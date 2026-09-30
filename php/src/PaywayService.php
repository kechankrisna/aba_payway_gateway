<?php

declare(strict_types=1);

namespace PhpPayway;

use PhpPayway\Crypto\OpenSslCrypto;
use PhpPayway\Crypto\PaywayCrypto;
use PhpPayway\Enum\PaymentOption;
use PhpPayway\Exception\ErrorType;
use PhpPayway\Exception\PaywayException;
use PhpPayway\Http\CurlHttpClient;
use PhpPayway\Http\HttpClient;
use PhpPayway\Model\Callback;
use PhpPayway\Model\CheckTransactionResponse;
use PhpPayway\Model\ExchangeRateResponse;
use PhpPayway\Model\Purchase;
use PhpPayway\Model\PurchaseResponse;
use PhpPayway\Model\RefundResponse;
use PhpPayway\Model\StatusResponse;
use PhpPayway\Model\TransactionDetailResponse;
use PhpPayway\Model\TransactionListQuery;
use PhpPayway\Model\TransactionListResponse;
use Psr\Clock\ClockInterface;
use Psr\Log\LoggerInterface;

/**
 * ABA PayWay Ecommerce Checkout client.
 *
 * PayWay business errors (wrong hash, transaction not found, ...) are
 * returned in `status`. A {@see PaywayException} is thrown only when PayWay
 * could not be reached or did not answer with a status. Run it on your
 * server: the API key is a secret.
 */
final class PaywayService
{
    public const string PURCHASE_PATH = '/api/payment-gateway/v1/payments/purchase';
    public const string CHECK_TRANSACTION_PATH = '/api/payment-gateway/v1/payments/check-transaction-2';
    public const string TRANSACTION_DETAIL_PATH = '/api/payment-gateway/v1/payments/transaction-detail';
    public const string CLOSE_TRANSACTION_PATH = '/api/payment-gateway/v1/payments/close-transaction';
    public const string TRANSACTION_LIST_PATH = '/api/payment-gateway/v1/payments/transaction-list-2';
    public const string EXCHANGE_RATE_PATH = '/api/payment-gateway/v1/exchange-rate';
    public const string REFUND_PATH = '/api/merchant-portal/merchant-access/online-transaction/refund';

    /** header carrying the callback signature */
    public const string CALLBACK_SIGNATURE_HEADER = 'X-PayWay-HMAC-SHA512';

    /** builds the signed request bodies; exposed to support new endpoints */
    public readonly RequestBuilder $requestBuilder;

    private readonly PaywayCrypto $crypto;

    private ?HttpClient $http;

    /**
     * Every dependency except `$merchant` is optional and injectable.
     *
     * @param ?HttpClient $httpClient HTTP stack (default: CurlHttpClient; or a Psr18HttpClient)
     * @param ?ClockInterface $clock PSR-20 source of `req_time` (default: now)
     * @param ?PaywayCrypto $crypto hashing and RSA (default: ext-openssl)
     * @param ?LoggerInterface $logger PSR-3 logger for request/response logs (debug level)
     */
    public function __construct(
        public readonly PaywayMerchant $merchant,
        ?HttpClient $httpClient = null,
        ?ClockInterface $clock = null,
        ?PaywayCrypto $crypto = null,
        private readonly ?LoggerInterface $logger = null,
    ) {
        $this->crypto = $crypto ?? new OpenSslCrypto();
        $this->requestBuilder = new RequestBuilder($merchant, $clock, $this->crypto);
        // created on first use, so verifying a callback needs no ext-curl
        $this->http = $httpClient;
    }

    /**
     * Creates a payment and returns its KHQR string and ABA Mobile deep link.
     * Only {@see PaymentOption::AbapayKhqrDeeplink} answers with JSON; use
     * {@see checkoutHtml()} for every other payment option.
     */
    public function purchase(Purchase $purchase): PurchaseResponse
    {
        if ($purchase->paymentOption !== PaymentOption::AbapayKhqrDeeplink) {
            throw new \InvalidArgumentException(
                'only AbapayKhqrDeeplink returns JSON; use checkoutHtml() for the hosted payment page',
            );
        }
        $boundary = 'payway' . bin2hex(random_bytes(12));

        return PurchaseResponse::fromArray($this->post(
            self::PURCHASE_PATH,
            self::multipart($this->requestBuilder->purchase($purchase), $boundary),
            "multipart/form-data; boundary={$boundary}",
        ));
    }

    /**
     * An HTML page that immediately POSTs `$purchase` to PayWay, opening its
     * hosted payment page. Serve it from your site or load it in a web view.
     */
    public function checkoutHtml(Purchase $purchase): string
    {
        $inputs = '';
        foreach ($this->requestBuilder->purchase($purchase) as $name => $value) {
            $inputs .= \sprintf("      <input type=\"hidden\" name=\"%s\" value=\"%s\">\n", self::escape($name), self::escape($value));
        }
        $action = self::escape($this->url(self::PURCHASE_PATH));

        return <<<HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>PayWay</title>
            </head>
            <body>
              <form method="POST" action="{$action}" id="payway_checkout">
            {$inputs}  </form>
              <script>document.getElementById("payway_checkout").submit();</script>
            </body>
            </html>

            HTML;
    }

    /** Status of a transaction created within the last 7 days. */
    public function checkTransaction(string $tranId): CheckTransactionResponse
    {
        return CheckTransactionResponse::fromArray($this->postJson(
            self::CHECK_TRANSACTION_PATH,
            $this->requestBuilder->checkTransaction($tranId),
        ));
    }

    /** Details of a transaction, including its payment and refund operations. */
    public function getTransactionDetail(string $tranId): TransactionDetailResponse
    {
        return TransactionDetailResponse::fromArray($this->postJson(
            self::TRANSACTION_DETAIL_PATH,
            $this->requestBuilder->transactionDetail($tranId),
        ));
    }

    /** Cancels an unpaid transaction: later payments are rejected or reversed. */
    public function closeTransaction(string $tranId): StatusResponse
    {
        return StatusResponse::fromArray($this->postJson(
            self::CLOSE_TRANSACTION_PATH,
            $this->requestBuilder->closeTransaction($tranId),
        ));
    }

    /** Transactions matching `$query`, one page at a time. */
    public function getTransactionList(TransactionListQuery $query = new TransactionListQuery()): TransactionListResponse
    {
        return TransactionListResponse::fromArray($this->postJson(
            self::TRANSACTION_LIST_PATH,
            $this->requestBuilder->transactionList($query),
        ));
    }

    /**
     * Refunds `$amount` (full or partial) within 30 days of the transaction.
     * Needs the merchant RSA public key.
     */
    public function refund(string $tranId, int|float $amount): RefundResponse
    {
        try {
            $body = $this->requestBuilder->refund($tranId, $amount);
        } catch (\InvalidArgumentException|\RuntimeException $e) {
            throw new PaywayException(ErrorType::Encryption, 'Refunds need a valid merchant RSA public key', null, $e);
        }

        return RefundResponse::fromArray($this->postJson(self::REFUND_PATH, $body));
    }

    /** ABA Bank's latest exchange rates, in riel per unit of each currency. */
    public function getExchangeRates(): ExchangeRateResponse
    {
        return ExchangeRateResponse::fromArray($this->postJson(
            self::EXCHANGE_RATE_PATH,
            $this->requestBuilder->exchangeRate(),
        ));
    }

    /**
     * Whether `$body`, the JSON PayWay POSTed to your `return_url`, is signed
     * with `$signature` (the `X-PayWay-HMAC-SHA512` header). `$key` defaults
     * to the merchant API key.
     *
     * ```php
     * $body = file_get_contents('php://input');
     * $ok = $payway->verifyCallback($body, $_SERVER['HTTP_X_PAYWAY_HMAC_SHA512'] ?? '');
     * ```
     */
    public function verifyCallback(string $body, string $signature, #[\SensitiveParameter] ?string $key = null): bool
    {
        $decoded = json_decode($body, true);
        if (!\is_array($decoded)) {
            return false;
        }
        $expected = $this->crypto->hmacSha512Base64(
            OpenSslCrypto::callbackSigningString($decoded),
            $key ?? $this->merchant->apiKey,
        );

        return hash_equals($expected, trim($signature));
    }

    /** Parses a callback body; call {@see verifyCallback()} first. */
    public function parseCallback(string $body): Callback
    {
        try {
            $decoded = json_decode($body, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException $e) {
            throw new PaywayException(ErrorType::InvalidCallback, 'Callback body is not JSON', null, $e);
        }
        if (!\is_array($decoded) || array_is_list($decoded)) {
            throw new PaywayException(ErrorType::InvalidCallback, 'Callback body is not a JSON object');
        }

        return Callback::fromArray($decoded);
    }

    /**
     * @param array<string, string> $body
     * @return array<array-key, mixed>
     */
    private function postJson(string $path, array $body): array
    {
        return $this->post($path, json_encode($body, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES), 'application/json');
    }

    /**
     * POSTs and returns PayWay's reply. PayWay answers errors with a JSON
     * body carrying the real status, possibly with a non-2xx HTTP status,
     * which is returned like a success; a status nested in `data` is lifted.
     *
     * @return array<array-key, mixed>
     */
    private function post(string $path, string $body, string $contentType): array
    {
        $url = $this->url($path);
        $this->logger?->debug("[PayWay] POST {$url} {$body}");

        $headers = [
            'Accept' => 'application/json',
            'Content-Type' => $contentType,
            'User-Agent' => 'php-payway/' . Version::SDK_VERSION,
        ];
        if ($this->merchant->referer !== '') {
            $headers['Referer'] = $this->merchant->referer;
        }

        try {
            $this->http ??= new CurlHttpClient();
            $response = $this->http->post($url, $headers, $body);
        } catch (PaywayException $e) {
            $this->logger?->debug("[PayWay] failed {$e->getMessage()}");
            throw $e;
        }

        $this->logger?->debug("[PayWay] {$response->statusCode} {$response->body}");
        $json = json_decode($response->body, true);
        if (\is_array($json)) {
            if (\is_array($json['status'] ?? null)) {
                return $json;
            }
            if (\is_array($json['data'] ?? null) && \is_array($json['data']['status'] ?? null)) {
                return [...$json, 'status' => $json['data']['status']];
            }
        }

        throw new PaywayException(ErrorType::UnexpectedResponse, 'Unexpected response from PayWay', $response->statusCode);
    }

    private function url(string $path): string
    {
        return rtrim($this->merchant->baseApiUrl, '/') . $path;
    }

    /** @param array<string, string> $fields */
    private static function multipart(array $fields, string $boundary): string
    {
        $body = '';
        foreach ($fields as $name => $value) {
            $body .= "--{$boundary}\r\nContent-Disposition: form-data; name=\"{$name}\"\r\n\r\n{$value}\r\n";
        }

        return $body . "--{$boundary}--\r\n";
    }

    private static function escape(string $value): string
    {
        return htmlspecialchars($value, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }
}

<?php

declare(strict_types=1);

namespace PhpPayway;

use PhpPayway\Crypto\OpenSslCrypto;
use PhpPayway\Crypto\PaywayCrypto;
use PhpPayway\Model\Purchase;
use PhpPayway\Model\TransactionListQuery;
use Psr\Clock\ClockInterface;

/**
 * Builds the signed request bodies of the PayWay checkout APIs. Every hash
 * is `base64(HMAC-SHA512(values..., api_key))` over the values in the order
 * the docs list them; absent optional values count as empty.
 */
final readonly class RequestBuilder
{
    private ClockInterface $clock;

    private PaywayCrypto $crypto;

    public function __construct(
        private PaywayMerchant $merchant,
        ?ClockInterface $clock = null,
        ?PaywayCrypto $crypto = null,
    ) {
        $this->clock = $clock ?? new SystemClock();
        $this->crypto = $crypto ?? new OpenSslCrypto();
    }

    /**
     * Form fields of `purchase`, in PayWay's order, with `hash`.
     *
     * @return array<string, string>
     */
    public function purchase(Purchase $p, ?string $requestTime = null): array
    {
        $time = $this->requestTime($requestTime);
        $b64Json = static fn(mixed $v): ?string => $v === null ? null : base64_encode(self::json($v));

        $hashed = [
            'req_time' => $time,
            'merchant_id' => $this->merchant->merchantId,
            'tran_id' => $p->tranId,
            'amount' => self::formatAmount($p->amount),
            'items' => $p->items === [] ? null : $b64Json(array_map(static fn($i) => $i->toArray(), $p->items)),
            'shipping' => $p->shipping === null ? null : self::formatAmount($p->shipping),
            'firstname' => $p->firstName,
            'lastname' => $p->lastName,
            'email' => $p->email,
            'phone' => $p->phone,
            'type' => $p->type?->value,
            'payment_option' => $p->paymentOption?->value,
            'return_url' => $p->returnUrl === null ? null : base64_encode($p->returnUrl),
            'cancel_url' => $p->cancelUrl,
            'continue_success_url' => $p->continueSuccessUrl,
            'return_deeplink' => $b64Json($p->returnDeeplink?->toArray()),
            'currency' => $p->currency?->value,
            'custom_fields' => $b64Json($p->customFields),
            'return_params' => $p->returnParams,
            'payout' => $p->payout === null ? null : $b64Json(array_map(static fn($x) => $x->toArray(), $p->payout)),
            'lifetime' => $p->lifetime === null ? null : (string) $p->lifetime,
            'additional_params' => $b64Json($p->additionalParams),
            'google_pay_token' => $p->googlePayToken,
            'skip_success_page' => $p->skipSuccessPage === null ? null : ($p->skipSuccessPage ? '1' : '0'),
        ];
        $unhashed = [
            'view_type' => $p->viewType?->value,
            'payment_gate' => $p->paymentGate === null ? null : (string) $p->paymentGate,
        ];

        return [
            ...array_filter($hashed, static fn($v) => $v !== null),
            ...array_filter($unhashed, static fn($v) => $v !== null),
            'hash' => $this->sign(array_values($hashed)),
        ];
    }

    /** @return array<string, string> body of `check-transaction-2` */
    public function checkTransaction(string $tranId, ?string $requestTime = null): array
    {
        return $this->tranIdBody($tranId, $requestTime);
    }

    /** @return array<string, string> body of `transaction-detail` */
    public function transactionDetail(string $tranId, ?string $requestTime = null): array
    {
        return $this->tranIdBody($tranId, $requestTime);
    }

    /** @return array<string, string> body of `close-transaction` */
    public function closeTransaction(string $tranId, ?string $requestTime = null): array
    {
        return $this->tranIdBody($tranId, $requestTime);
    }

    /** @return array<string, string> body of `transaction-list-2` */
    public function transactionList(TransactionListQuery $q, ?string $requestTime = null): array
    {
        $time = $this->requestTime($requestTime);
        $hashed = [
            'req_time' => $time,
            'merchant_id' => $this->merchant->merchantId,
            'from_date' => $q->fromDate?->format('Y-m-d H:i:s'),
            'to_date' => $q->toDate?->format('Y-m-d H:i:s'),
            'from_amount' => $q->fromAmount === null ? null : self::formatAmount($q->fromAmount),
            'to_amount' => $q->toAmount === null ? null : self::formatAmount($q->toAmount),
            'status' => $q->statuses === [] ? null : implode(',', array_map(static fn($s) => $s->value, $q->statuses)),
            'page' => $q->page === null ? null : (string) $q->page,
            'pagination' => $q->pagination === null ? null : (string) $q->pagination,
        ];

        return [
            ...array_filter($hashed, static fn($v) => $v !== null),
            'hash' => $this->sign(array_values($hashed)),
        ];
    }

    /** @return array<string, string> body of `exchange-rate` */
    public function exchangeRate(?string $requestTime = null): array
    {
        $time = $this->requestTime($requestTime);

        return [
            'req_time' => $time,
            'merchant_id' => $this->merchant->merchantId,
            'hash' => $this->sign([$time, $this->merchant->merchantId]),
        ];
    }

    /**
     * Body of `refund`: `merchant_auth` is the RSA-encrypted
     * `{"mc_id", "tran_id", "refund_amount"}`, which needs the RSA public key.
     *
     * @return array<string, string>
     */
    public function refund(string $tranId, int|float $refundAmount, ?string $requestTime = null): array
    {
        $rsaKey = $this->merchant->rsaPublicKey;
        if ($rsaKey === null || $rsaKey === '') {
            throw new \InvalidArgumentException('refunds need the RSA public key provided by ABA');
        }
        $time = $this->requestTime($requestTime);
        $merchantAuth = $this->crypto->rsaEncrypt(self::json([
            'mc_id' => $this->merchant->merchantId,
            'tran_id' => $tranId,
            'refund_amount' => $refundAmount,
        ]), $rsaKey);

        return [
            'request_time' => $time,
            'merchant_id' => $this->merchant->merchantId,
            'merchant_auth' => $merchantAuth,
            'hash' => $this->sign([$time, $this->merchant->merchantId, $merchantAuth]),
        ];
    }

    /**
     * `base64(HMAC-SHA512(concatenated values, api_key))`; null counts as empty.
     *
     * @param list<?string> $values
     */
    public function sign(array $values): string
    {
        return $this->crypto->hmacSha512Base64(implode('', array_map(static fn($v) => $v ?? '', $values)), $this->merchant->apiKey);
    }

    /** `YYYYMMDDHHmmss` in UTC, as PayWay requires. */
    public static function formatRequestTime(\DateTimeInterface $time): string
    {
        return \DateTimeImmutable::createFromInterface($time)->setTimezone(new \DateTimeZone('UTC'))->format('YmdHis');
    }

    /** amounts without a trailing `.0`: `6` stays `6`, `6.5` stays `6.5` */
    public static function formatAmount(int|float $amount): string
    {
        if (\is_int($amount)) {
            return (string) $amount;
        }

        return $amount == floor($amount) && abs($amount) < 1e15 ? (string) (int) $amount : (string) $amount;
    }

    /** @return array<string, string> */
    private function tranIdBody(string $tranId, ?string $requestTime): array
    {
        $time = $this->requestTime($requestTime);

        return [
            'req_time' => $time,
            'merchant_id' => $this->merchant->merchantId,
            'tran_id' => $tranId,
            'hash' => $this->sign([$time, $this->merchant->merchantId, $tranId]),
        ];
    }

    private function requestTime(?string $requestTime): string
    {
        $time = $requestTime ?? self::formatRequestTime($this->clock->now());
        if (preg_match('/^\d{14}$/', $time) !== 1) {
            throw new \InvalidArgumentException("requestTime must be 14 digits YYYYMMDDHHmmss, got \"{$time}\"");
        }

        return $time;
    }

    private static function json(mixed $value): string
    {
        return json_encode($value, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }
}

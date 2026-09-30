<?php

declare(strict_types=1);

namespace PhpPayway\Tests;

use PhpPayway\Enum\PaymentOption;
use PhpPayway\Enum\PaymentStatusCode;
use PhpPayway\Exception\ErrorType;
use PhpPayway\Exception\PaywayException;
use PhpPayway\Http\HttpResponse;
use PhpPayway\Model\Purchase;
use PhpPayway\PaywayMerchant;
use PhpPayway\PaywayService;
use PhpPayway\RequestBuilder;
use PhpPayway\Version;
use PHPUnit\Framework\TestCase;

/** Offline tests of the PHP specifics: injected HTTP, errors, parsing. */
final class UnitTest extends TestCase
{
    private static function service(FakeHttpClient $http): PaywayService
    {
        return new PaywayService(KnownAnswersTest::merchant(), $http);
    }

    public function testRequestTimeIsUtcAndZeroPadded(): void
    {
        $local = (new \DateTimeImmutable('2026-01-02T15:04:05Z'))->setTimezone(new \DateTimeZone('Asia/Phnom_Penh'));
        self::assertSame('20260102150405', RequestBuilder::formatRequestTime($local));
        self::assertSame('20260903070809', RequestBuilder::formatRequestTime(new \DateTimeImmutable('2026-09-03T07:08:09Z')));
    }

    public function testPurchasePostsMultipartAndReadsProductionFields(): void
    {
        $http = FakeHttpClient::json([
            'qrString' => '000201...',
            'qrImage' => 'data:image/png;base64,iVBORw0KGgo=',
            'abapay_deeplink' => 'abamobilebank://ababank.com?type=payway',
            'app_store' => 'https://itunes.apple.com/app/id968860649',
            'play_store' => 'https://play.google.com/store/apps/details?id=com.paygo24.ibank',
            'status' => ['code' => '00', 'message' => 'Success!', 'tran_id' => 'order-1001', 'trace_id' => '19b80de5'],
        ]);

        $response = self::service($http)->purchase(KnownAnswersTest::fullPurchase());

        self::assertTrue($response->isSuccess());
        self::assertSame('000201...', $response->qrString);
        self::assertStringStartsWith('data:image/png', (string) $response->qrImage);
        self::assertSame('19b80de5', $response->status->traceId);
        $request = $http->requests[0];
        self::assertSame('https://payway.test' . PaywayService::PURCHASE_PATH, $request['url']);
        self::assertStringStartsWith('multipart/form-data; boundary=', $request['headers']['Content-Type']);
        self::assertSame('https://shop.test', $request['headers']['Referer']);
        self::assertSame('php-payway/' . Version::SDK_VERSION, $request['headers']['User-Agent']);
        self::assertStringContainsString("name=\"tran_id\"\r\n\r\norder-1001\r\n", $request['body']);
    }

    public function testPurchaseReadsTheSandboxFieldNamesToo(): void
    {
        $response = self::service(FakeHttpClient::json([
            'qr_string' => 'abc',
            'checkout_qr_url' => 'https://checkout-sandbox.payway.com.kh/qr',
            'status' => ['code' => '00', 'message' => 'Success!'],
        ]))->purchase(new Purchase('x', 1, paymentOption: PaymentOption::AbapayKhqrDeeplink));
        self::assertSame('abc', $response->qrString);
        self::assertNotNull($response->checkoutQrUrl);
    }

    public function testPurchaseNeedsTheDeeplinkOption(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        self::service(FakeHttpClient::json([]))->purchase(new Purchase('x', 1, paymentOption: PaymentOption::Cards));
    }

    public function testCheckTransactionPostsJsonAndLiftsANestedStatus(): void
    {
        $http = FakeHttpClient::json(['data' => [
            'payment_status_code' => 0,
            'payment_status' => 'APPROVED',
            'total_amount' => '6.5',
            'status' => ['code' => '00', 'message' => 'Success!'],
        ]]);

        $response = self::service($http)->checkTransaction('order-1001');

        self::assertTrue($response->isPaid());
        self::assertSame(6.5, $response->data?->totalAmount);
        self::assertSame('application/json', $http->requests[0]['headers']['Content-Type']);
        self::assertSame('https://payway.test' . PaywayService::CHECK_TRANSACTION_PATH, $http->requests[0]['url']);
        $body = json_decode($http->requests[0]['body'], true, 512, JSON_THROW_ON_ERROR);
        self::assertIsArray($body);
        self::assertSame(['req_time', 'merchant_id', 'tran_id', 'hash'], array_keys($body));
        self::assertSame('order-1001', $body['tran_id']);
    }

    public function testErrorStatusIsReturnedNotThrown(): void
    {
        $response = self::service(FakeHttpClient::json(
            ['status' => ['code' => 6, 'message' => 'tran_id not found', 'tran_id' => 'x']],
            403,
        ))->getTransactionDetail('x');
        self::assertFalse($response->isSuccess());
        self::assertSame('6', $response->status->code);
        self::assertNull($response->data);
    }

    public function testTransactionDetailOperations(): void
    {
        $response = self::service(FakeHttpClient::json([
            'data' => [
                'transaction_id' => 'T1',
                'payment_status_code' => PaymentStatusCode::APPROVED,
                'transaction_operations' => [['status' => 'Completed', 'amount' => 0.1, 'bank_ref' => 'FT1']],
            ],
            'status' => ['code' => '00', 'message' => 'Success!'],
        ]))->getTransactionDetail('T1');
        self::assertNotNull($response->data);
        self::assertTrue($response->data->isApproved());
        self::assertSame('FT1', $response->data->transactionOperations[0]->bankRef);
    }

    public function testExchangeRatesFromBothLayouts(): void
    {
        $response = self::service(FakeHttpClient::json([
            'status' => ['code' => '00', 'message' => 'Success'],
            'exchange_rates' => ['usd' => ['sell' => '4065', 'buy' => '4042']],
            'eur' => ['sell' => 4687.1, 'buy' => 4445.2],
        ]))->getExchangeRates();
        self::assertSame(4065.0, $response->rates['usd']->sell);
        self::assertArrayHasKey('eur', $response->rates);
    }

    public function testRefundEncryptsMerchantAuth(): void
    {
        $body = KnownAnswersTest::builder()->refund('order-1001', 0.5);
        self::assertSame(['request_time', 'merchant_id', 'merchant_auth', 'hash'], array_keys($body));
        self::assertSame(
            ['mc_id' => 'ec000002', 'tran_id' => 'order-1001', 'refund_amount' => 0.5],
            json_decode(Spec::rsaDecrypt($body['merchant_auth'], Spec::fixture('rsa_1024_private.pem')), true),
        );
        self::assertSame(
            base64_encode(hash_hmac('sha512', '20260102030405ec000002' . $body['merchant_auth'], 'test-api-key', true)),
            $body['hash'],
        );
    }

    public function testRefundWithoutRsaKeyIsAnEncryptionError(): void
    {
        $service = new PaywayService(new PaywayMerchant('m', 'k', ''), FakeHttpClient::json([]));
        try {
            $service->refund('x', 1);
            self::fail('expected an exception');
        } catch (PaywayException $e) {
            self::assertSame(ErrorType::Encryption, $e->type);
        }
    }

    public function testHtmlErrorPageIsUnexpected(): void
    {
        $http = new FakeHttpClient(static fn(): HttpResponse => new HttpResponse(502, '<html>'));
        try {
            self::service($http)->getTransactionList();
            self::fail('expected an exception');
        } catch (PaywayException $e) {
            self::assertSame(ErrorType::UnexpectedResponse, $e->type);
            self::assertSame(502, $e->statusCode);
            self::assertTrue($e->isRetryable());
        }
    }

    public function testCheckoutHtmlEscapesAndSigns(): void
    {
        $service = new PaywayService(KnownAnswersTest::merchant());
        $html = $service->checkoutHtml(new Purchase('x', 1, firstName: '"><script>alert(1)</script>'));
        self::assertStringNotContainsString('<script>alert', $html);
        self::assertStringContainsString('action="https://payway.test' . PaywayService::PURCHASE_PATH . '"', $html);
        self::assertStringContainsString('name="hash"', $html);
    }

    public function testParseCallback(): void
    {
        $service = new PaywayService(KnownAnswersTest::merchant());
        $callback = $service->parseCallback(Spec::knownAnswers()['callback_body']);
        self::assertSame('9065703303', $callback->tranId);
        self::assertTrue($callback->isSuccess());
        self::assertSame(0.01, $callback->totalAmount);

        $this->expectException(PaywayException::class);
        $service->parseCallback('[]');
    }

    public function testSecretsAreHiddenFromDebugOutput(): void
    {
        self::assertStringNotContainsString('test-api-key', print_r(KnownAnswersTest::merchant(), true));
    }
}

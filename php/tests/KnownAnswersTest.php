<?php

declare(strict_types=1);

namespace PhpPayway\Tests;

use PhpPayway\Enum\Currency;
use PhpPayway\Enum\PaymentOption;
use PhpPayway\Enum\PaymentStatus;
use PhpPayway\Enum\TransactionType;
use PhpPayway\Enum\ViewType;
use PhpPayway\Model\Item;
use PhpPayway\Model\Payout;
use PhpPayway\Model\Purchase;
use PhpPayway\Model\ReturnDeeplink;
use PhpPayway\Model\TransactionListQuery;
use PhpPayway\PaywayMerchant;
use PhpPayway\PaywayService;
use PhpPayway\RequestBuilder;
use PHPUnit\Framework\TestCase;
use Psr\Clock\ClockInterface;

/**
 * Request hashes and callback signatures must equal the known answers in
 * spec/test-vectors, computed with the PHP samples from ABA's docs.
 */
final class KnownAnswersTest extends TestCase
{
    private const string REQUEST_TIME = '20260102030405';

    public static function merchant(): PaywayMerchant
    {
        return new PaywayMerchant(
            'ec000002',
            'test-api-key',
            'https://shop.test',
            Spec::fixture('rsa_1024_public.pem'),
            'https://payway.test',
        );
    }

    public static function builder(): RequestBuilder
    {
        return new RequestBuilder(self::merchant(), new class implements ClockInterface {
            public function now(): \DateTimeImmutable
            {
                return new \DateTimeImmutable('2026-01-02T03:04:05Z');
            }
        });
    }

    public static function fullPurchase(): Purchase
    {
        return new Purchase(
            tranId: 'order-1001',
            amount: 6.5,
            items: [new Item('product 1', 1, 1.5), new Item('product 2', 2, 2.5)],
            shipping: 1,
            firstName: 'Sok',
            lastName: 'Dara',
            email: 'sok@example.com',
            phone: '012345678',
            type: TransactionType::PreAuth,
            paymentOption: PaymentOption::AbapayKhqrDeeplink,
            returnUrl: 'https://shop.test/payway/callback',
            cancelUrl: 'https://shop.test/cancel',
            continueSuccessUrl: 'https://shop.test/done',
            returnDeeplink: new ReturnDeeplink('shop://done', 'shop://done'),
            currency: Currency::USD,
            customFields: ['order' => '1001'],
            returnParams: 'order=1001',
            payout: [new Payout('000133879', 1), new Payout('000133880', 1.5)],
            lifetime: 30,
            additionalParams: ['wechat_sub_appid' => 'wx1'],
            skipSuccessPage: true,
            viewType: ViewType::Popup,
            paymentGate: 0,
        );
    }

    public function testPurchaseWithRequiredFieldsOnly(): void
    {
        self::assertSame([
            'req_time' => self::REQUEST_TIME,
            'merchant_id' => 'ec000002',
            'tran_id' => 'order-1001',
            'amount' => '6.5',
            'hash' => Spec::knownAnswers()['purchase_minimal'],
        ], self::builder()->purchase(new Purchase('order-1001', 6.5)));
    }

    public function testPurchaseWithEveryField(): void
    {
        $kat = Spec::knownAnswers();
        $fields = self::builder()->purchase(self::fullPurchase());

        self::assertSame($kat['purchase_full'], $fields['hash']);
        self::assertSame($kat['purchase_full_items'], $fields['items']);
        self::assertSame($kat['purchase_full_return_url'], $fields['return_url']);
        self::assertSame($kat['purchase_full_return_deeplink'], $fields['return_deeplink']);
        self::assertSame($kat['purchase_full_payout'], $fields['payout']);
        self::assertSame('popup', $fields['view_type']);
        self::assertSame('0', $fields['payment_gate']);
        self::assertSame('hash', array_key_last($fields));
    }

    public function testTranIdBodies(): void
    {
        $expected = [
            'req_time' => self::REQUEST_TIME,
            'merchant_id' => 'ec000002',
            'tran_id' => 'order-1001',
            'hash' => Spec::knownAnswers()['tran_id_hash'],
        ];
        $builder = self::builder();
        self::assertSame($expected, $builder->checkTransaction('order-1001'));
        self::assertSame($expected, $builder->transactionDetail('order-1001'));
        self::assertSame($expected, $builder->closeTransaction('order-1001'));
    }

    public function testTransactionList(): void
    {
        $body = self::builder()->transactionList(new TransactionListQuery(
            fromDate: new \DateTimeImmutable('2026-01-01 00:00:00'),
            toDate: new \DateTimeImmutable('2026-01-31 23:59:59'),
            fromAmount: 1,
            toAmount: 100,
            statuses: [PaymentStatus::Approved, PaymentStatus::Refunded],
            page: 2,
            pagination: 50,
        ));
        self::assertSame('APPROVED,REFUNDED', $body['status']);
        self::assertSame(Spec::knownAnswers()['list_hash'], $body['hash']);
    }

    public function testExchangeRate(): void
    {
        self::assertSame(Spec::knownAnswers()['exchange_hash'], self::builder()->exchangeRate()['hash']);
    }

    public function testCallbackSignatures(): void
    {
        $kat = Spec::knownAnswers();
        $service = new PaywayService(self::merchant());
        self::assertTrue($service->verifyCallback($kat['callback_body'], $kat['callback_signature']));
        self::assertTrue($service->verifyCallback($kat['callback2_body'], $kat['callback2_signature']));
        self::assertFalse($service->verifyCallback(str_replace('0.01', '1000', $kat['callback_body']), $kat['callback_signature']));
        self::assertFalse($service->verifyCallback($kat['callback_body'], 'forged'));
    }
}

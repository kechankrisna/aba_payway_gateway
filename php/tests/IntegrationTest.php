<?php

declare(strict_types=1);

namespace PhpPayway\Tests;

use PhpPayway\Enum\Currency;
use PhpPayway\Enum\PaymentOption;
use PhpPayway\Enum\PaymentStatus;
use PhpPayway\Enum\PaymentStatusCode;
use PhpPayway\Model\CheckTransactionResponse;
use PhpPayway\Model\Item;
use PhpPayway\Model\Purchase;
use PhpPayway\Model\TransactionListQuery;
use PhpPayway\PaywayMerchant;
use PhpPayway\PaywayService;
use PHPUnit\Framework\Attributes\Depends;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\TestCase;

/**
 * Integration tests against PayWay checkout. They read merchant credentials
 * from php/.env (or the file named by PAYWAY_ENV_FILE) and are skipped
 * without one:
 *
 *   composer test -- --group integration
 *   PAYWAY_ENV_FILE=php/.env.production composer test -- --group integration
 *
 * They create real transactions (0.10 USD, then closed), so a file pointing
 * at production (checkout.payway.com.kh) is refused unless you also set
 * PAYWAY_ALLOW_PRODUCTION=true.
 */
#[Group('integration')]
final class IntegrationTest extends TestCase
{
    private static ?PaywayService $payway = null;

    private static string $tranId = '';

    public static function setUpBeforeClass(): void
    {
        $file = getenv('PAYWAY_ENV_FILE') ?: __DIR__ . '/../.env';
        if (!is_file($file)) {
            return;
        }
        $env = self::readEnv($file);
        $baseUrl = $env['ABA_PAYWAY_API_URL'] ?? PaywayMerchant::SANDBOX_URL;
        if (parse_url($baseUrl, PHP_URL_HOST) === parse_url(PaywayMerchant::PRODUCTION_URL, PHP_URL_HOST)
            && getenv('PAYWAY_ALLOW_PRODUCTION') !== 'true') {
            return;
        }
        $rsaKey = $env['ABA_PAYWAY_RSA_PUBLIC_KEY'] ?? '';
        self::$payway = new PaywayService(new PaywayMerchant(
            $env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
            $env['ABA_PAYWAY_API_KEY'] ?? '',
            $env['ABA_PAYWAY_REFERER_DOMAIN'] ?? '',
            $rsaKey === '' ? null : $rsaKey,
            $baseUrl,
        ));
        self::$tranId = 'sdk' . (int) (microtime(true) * 1000);
    }

    // close only the transaction this run created, never someone else's
    public static function tearDownAfterClass(): void
    {
        if (self::$payway !== null && self::$tranId !== '') {
            self::$payway->closeTransaction(self::$tranId);
        }
    }

    protected function setUp(): void
    {
        if (self::$payway === null) {
            self::markTestSkipped('no PayWay env file, or it points at production without PAYWAY_ALLOW_PRODUCTION=true');
        }
    }

    private static function payway(): PaywayService
    {
        \assert(self::$payway !== null);

        return self::$payway;
    }

    public function testPurchaseReturnsAKhqr(): void
    {
        $response = self::payway()->purchase(new Purchase(
            tranId: self::$tranId,
            amount: 0.1,
            items: [new Item('test item', 1, 0.1)],
            paymentOption: PaymentOption::AbapayKhqrDeeplink,
            currency: Currency::USD,
        ));
        self::assertTrue($response->isSuccess(), $response->status->message);
        self::assertNotEmpty($response->qrString);
    }

    #[Depends('testPurchaseReturnsAKhqr')]
    public function testNewTransactionIsPending(): void
    {
        // a new transaction takes a moment to appear
        $check = null;
        for ($attempt = 0; $attempt < 10; $attempt++) {
            $check = self::payway()->checkTransaction(self::$tranId);
            if ($check->isSuccess()) {
                break;
            }
            sleep(1);
        }
        self::assertInstanceOf(CheckTransactionResponse::class, $check);
        self::assertTrue($check->isSuccess(), $check->status->message);
        self::assertSame(PaymentStatusCode::PENDING, $check->data?->paymentStatusCode);

        $detail = self::payway()->getTransactionDetail(self::$tranId);
        self::assertTrue($detail->isSuccess(), $detail->status->message);
        self::assertSame(0.1, $detail->data?->totalAmount);
    }

    #[Depends('testNewTransactionIsPending')]
    public function testNewTransactionIsListed(): void
    {
        $list = self::payway()->getTransactionList(new TransactionListQuery(
            statuses: [PaymentStatus::Pending],
            pagination: 20,
        ));
        self::assertTrue($list->isSuccess(), $list->status->message);
        self::assertContains(self::$tranId, array_map(static fn($t) => $t->transactionId, $list->data));
    }

    #[Depends('testNewTransactionIsListed')]
    public function testCloseTransaction(): void
    {
        $closed = self::payway()->closeTransaction(self::$tranId);
        self::assertTrue($closed->isSuccess(), $closed->status->message);
    }

    public function testUnknownTransactionIsReportedNotThrown(): void
    {
        self::assertFalse(self::payway()->checkTransaction('sdk-unknown-0')->isSuccess());
    }

    public function testExchangeRates(): void
    {
        $response = self::payway()->getExchangeRates();
        self::assertTrue($response->isSuccess(), $response->status->message);
        self::assertGreaterThan(1000, $response->rates['usd']->sell ?? 0, 'rates are riel per unit');
    }

    /** @return array<string, string> KEY="value" lines of a .env file */
    private static function readEnv(string $file): array
    {
        $env = [];
        foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
            if (preg_match('/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/', $line, $m) === 1) {
                $env[$m[1]] = trim($m[2], "\"'");
            }
        }

        return $env;
    }
}

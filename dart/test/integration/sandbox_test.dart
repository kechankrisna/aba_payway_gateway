// Integration tests against PayWay checkout. They read merchant credentials
// from an env file and are skipped without one:
//
//   dart test -t integration                                  # uses .env
//   PAYWAY_ENV_FILE=.env.production dart test -t integration  # another file
//
// They create real transactions (0.10 USD, then closed), so a file pointing
// at production (checkout.payway.com.kh) is refused unless you also set
// PAYWAY_ALLOW_PRODUCTION=true.
//
// Run only the offline tests with: dart test -x integration
@Tags(['integration'])
library;

import 'dart:io' as io;

import 'package:dart_payway/dart_payway.dart';
import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

void main() {
  final envFile = io.Platform.environment['PAYWAY_ENV_FILE'] ?? '.env';
  final env = DotEnv();
  if (io.File(envFile).existsSync()) env.load([envFile]);
  final baseUrl = env['ABA_PAYWAY_API_URL'] ?? PaywayMerchant.sandboxBaseUrl;
  final isProduction =
      Uri.parse(baseUrl).host ==
      Uri.parse(PaywayMerchant.productionBaseUrl).host;
  final allowProduction =
      io.Platform.environment['PAYWAY_ALLOW_PRODUCTION'] == 'true';

  final Object skip = !io.File(envFile).existsSync()
      ? 'no $envFile with PayWay credentials'
      : isProduction && !allowProduction
      ? '$envFile points at production; set PAYWAY_ALLOW_PRODUCTION=true '
            'to run tests that create real transactions'
      : false;

  group(
    'PayWay checkout (${Uri.parse(baseUrl).host}, $envFile)',
    skip: skip,
    () {
      late PaywayService payway;
      final tranId = 'sdk${DateTime.now().millisecondsSinceEpoch}';

      setUpAll(() {
        io.HttpOverrides.global = null;
        final rsaKey = env['ABA_PAYWAY_RSA_PUBLIC_KEY'];
        payway = PaywayService(
          merchant: PaywayMerchant(
            merchantId: env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
            apiKey: env['ABA_PAYWAY_API_KEY'] ?? '',
            rsaPublicKey: rsaKey == null || rsaKey.isEmpty ? null : rsaKey,
            referer: env['ABA_PAYWAY_REFERER_DOMAIN'] ?? '',
            baseApiUrl: baseUrl,
          ),
          logger: print,
        );
      });

      // close only the transaction this run created, never someone else's
      tearDownAll(() async {
        await payway.closeTransaction(tranId: tranId);
      });

      test('purchase with abapay_khqr_deeplink returns a KHQR', () async {
        final response = await payway.purchase(
          PaywayPurchase(
            tranId: tranId,
            amount: 0.1,
            currency: PaywayCurrency.usd,
            paymentOption: PaywayPaymentOption.abapayKhqrDeeplink,
            items: const [
              PaywayItem(name: 'test item', quantity: 1, price: 0.1),
            ],
          ),
        );
        expect(response.isSuccess, true, reason: '${response.status}');
        expect(response.qrString, isNotEmpty);
      });

      test('the new transaction is pending in check and details', () async {
        // a new transaction takes a moment to appear
        PaywayCheckTransactionResponse? check;
        for (var attempt = 0; attempt < 10; attempt++) {
          check = await payway.checkTransaction(tranId: tranId);
          if (check.isSuccess) break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        expect(check!.isSuccess, true, reason: '${check.status}');
        expect(check.data!.paymentStatusCode, PaywayPaymentStatusCode.pending);

        final detail = await payway.getTransactionDetail(tranId: tranId);
        expect(detail.isSuccess, true, reason: '${detail.status}');
        expect(detail.data!.totalAmount, 0.1);
      });

      test('the new transaction is in the transaction list', () async {
        final list = await payway.getTransactionList(
          query: const PaywayTransactionListQuery(
            statuses: [PaywayPaymentStatus.pending],
            pagination: 20,
          ),
        );
        expect(list.isSuccess, true, reason: '${list.status}');
        expect(list.data.map((t) => t.transactionId), contains(tranId));
      });

      test('closing the new transaction succeeds', () async {
        final closed = await payway.closeTransaction(tranId: tranId);
        expect(closed.isSuccess, true, reason: '${closed.status}');
      });

      test(
        'check transaction of an unknown id is reported, not thrown',
        () async {
          final response = await payway.checkTransaction(
            tranId: 'sdk-unknown-0',
          );
          expect(response.isSuccess, false);
        },
      );

      test('exchange rates', () async {
        final response = await payway.getExchangeRates();
        expect(response.isSuccess, true, reason: '${response.status}');
        expect(
          response.rates['usd']!.sell,
          greaterThan(1000),
          reason: 'rates are riel per unit',
        );
      });
    },
  );
}

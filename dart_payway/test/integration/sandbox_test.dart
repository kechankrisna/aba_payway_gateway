// Integration tests against the ABA PayWay checkout sandbox. They need a
// `.env` with sandbox merchant credentials (see .env.example) and are
// skipped without one. Run only the offline tests with:
//   dart test -x integration
@Tags(['integration'])
library;

import 'dart:io' as io;

import 'package:dart_payway/dart_payway.dart';
import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

void main() {
  final hasSandboxEnv = io.File('.env').existsSync();

  group(
    'ABA PayWay checkout sandbox',
    skip: hasSandboxEnv ? false : 'no .env with sandbox credentials',
    () {
      late PaywayService payway;

      setUpAll(() {
        io.HttpOverrides.global = null;
        final env = DotEnv(includePlatformEnvironment: true)..load();
        final rsaKey = env['ABA_PAYWAY_RSA_PUBLIC_KEY'];
        payway = PaywayService(
          merchant: PaywayMerchant(
            merchantId: env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
            apiKey: env['ABA_PAYWAY_API_KEY'] ?? '',
            rsaPublicKey: rsaKey == null || rsaKey.isEmpty ? null : rsaKey,
            referer: env['ABA_PAYWAY_REFERER_DOMAIN'] ?? '',
            baseApiUrl:
                env['ABA_PAYWAY_API_URL'] ?? PaywayMerchant.sandboxBaseUrl,
          ),
          logger: print,
        );
      });

      test('purchase with abapay_khqr_deeplink returns a KHQR', () async {
        final response = await payway.purchase(
          PaywayPurchase(
            tranId: 'sdk${DateTime.now().millisecondsSinceEpoch}',
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

      test(
        'transaction list, then close the newest pending transaction',
        () async {
          final list = await payway.getTransactionList(
            query: const PaywayTransactionListQuery(
              statuses: [PaywayPaymentStatus.pending],
              pagination: 5,
            ),
          );
          expect(list.isSuccess, true, reason: '${list.status}');
          if (list.data.isEmpty) return;
          final tranId = list.data.first.transactionId;
          final detail = await payway.getTransactionDetail(tranId: tranId);
          expect(detail.isSuccess, true, reason: '${detail.status}');
          final closed = await payway.closeTransaction(tranId: tranId);
          expect(closed.isSuccess, true, reason: '${closed.status}');
        },
      );

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

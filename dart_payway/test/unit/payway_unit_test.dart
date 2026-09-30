// Offline tests: no network, no ABA credentials. Expected hashes and
// signatures in test/fixtures/php_known_answers.json were computed with the
// PHP samples from ABA's documentation (test/fixtures/php_known_answers.php).
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_payway/dart_payway.dart';
import 'package:dio/dio.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';

String fixture(String name) =>
    io.File('test/fixtures/$name').readAsStringSync();

final Map<String, dynamic> kat =
    json.decode(fixture('php_known_answers.json')) as Map<String, dynamic>;

/// answers every request with [handler] and records what was sent
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];
  final bodies = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    requests.add(options);
    bodies.add(utf8.decode(bytes, allowMalformed: true));
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object body, int statusCode) =>
    ResponseBody.fromString(json.encode(body), statusCode);

/// PKCS#1 v1.5 decryption with a PKCS#1 private key, to check merchant_auth
String rsaDecrypt(String data, String privateKeyPem) {
  final der = base64.decode(
    privateKeyPem
        .split('\n')
        .where((l) => !l.startsWith('-----'))
        .join()
        .trim(),
  );
  final seq = ASN1Parser(der).nextObject() as ASN1Sequence;
  final v = [for (final e in seq.elements!) (e as ASN1Integer).integer!];
  final cipher = PKCS1Encoding(RSAEngine())
    ..init(
      false,
      PrivateKeyParameter<RSAPrivateKey>(RSAPrivateKey(v[1], v[3], v[4], v[5])),
    );
  final source = base64.decode(data);
  final out = BytesBuilder();
  for (var i = 0; i < source.length; i += cipher.inputBlockSize) {
    out.add(
      cipher.process(
        Uint8List.sublistView(source, i, i + cipher.inputBlockSize),
      ),
    );
  }
  return utf8.decode(out.toBytes());
}

void main() {
  final merchant = PaywayMerchant(
    merchantId: 'ec000002',
    apiKey: 'test-api-key',
    referer: 'https://shop.test',
    rsaPublicKey: fixture('rsa_1024_public.pem'),
    baseApiUrl: 'https://payway.test',
  );
  DateTime fixedClock() => DateTime.utc(2026, 1, 2, 3, 4, 5);
  const requestTime = '20260102030405';
  final builder = PaywayRequestBuilder(merchant: merchant, clock: fixedClock);

  const fullPurchase = PaywayPurchase(
    tranId: 'order-1001',
    amount: 6.5,
    items: [
      PaywayItem(name: 'product 1', quantity: 1, price: 1.5),
      PaywayItem(name: 'product 2', quantity: 2, price: 2.5),
    ],
    shipping: 1,
    firstName: 'Sok',
    lastName: 'Dara',
    email: 'sok@example.com',
    phone: '012345678',
    type: PaywayTransactionType.preAuth,
    paymentOption: PaywayPaymentOption.abapayKhqrDeeplink,
    returnUrl: 'https://shop.test/payway/callback',
    cancelUrl: 'https://shop.test/cancel',
    continueSuccessUrl: 'https://shop.test/done',
    returnDeeplink: PaywayReturnDeeplink(
      iosScheme: 'shop://done',
      androidScheme: 'shop://done',
    ),
    currency: PaywayCurrency.usd,
    customFields: {'order': '1001'},
    returnParams: 'order=1001',
    payout: [
      PaywayPayout(account: '000133879', amount: 1),
      PaywayPayout(account: '000133880', amount: 1.5),
    ],
    lifetime: 30,
    additionalParams: {'wechat_sub_appid': 'wx1'},
    skipSuccessPage: true,
    viewType: PaywayViewType.popup,
    paymentGate: 0,
  );

  PaywayService serviceWith(FakeAdapter adapter, {PaywayLogger? logger}) =>
      PaywayService(
        merchant: merchant,
        dio: Dio()..httpClientAdapter = adapter,
        clock: fixedClock,
        logger: logger,
      );

  group('request time', () {
    test('is UTC YYYYMMDDHHmmss, zero padded', () {
      final local = DateTime.utc(2026, 1, 2, 15, 4, 5).toLocal();
      expect(PaywayRequestBuilder.formatRequestTime(local), '20260102150405');
      expect(
        PaywayRequestBuilder.formatRequestTime(
          DateTime.utc(2026, 9, 3, 7, 8, 9),
        ),
        '20260903070809',
      );
    });

    test('a malformed request time is rejected', () {
      expect(
        () => builder.checkTransaction('x', requestTime: '2026-01-02'),
        throwsArgumentError,
      );
    });
  });

  group('hashes match ABA\'s PHP samples', () {
    test('purchase with the required fields only', () {
      final fields = builder.purchase(
        const PaywayPurchase(tranId: 'order-1001', amount: 6.5),
      );
      expect(fields, {
        'req_time': requestTime,
        'merchant_id': 'ec000002',
        'tran_id': 'order-1001',
        'amount': '6.5',
        'hash': kat['purchase_minimal'],
      });
    });

    test('purchase with every field', () {
      final fields = builder.purchase(fullPurchase);
      expect(fields['hash'], kat['purchase_full']);
      expect(fields['items'], kat['purchase_full_items']);
      expect(fields['return_url'], kat['purchase_full_return_url']);
      expect(fields['return_deeplink'], kat['purchase_full_return_deeplink']);
      expect(fields['payout'], kat['purchase_full_payout']);
      expect(fields['type'], 'pre-auth');
      expect(fields['skip_success_page'], '1');
      // sent, but not part of the hash
      expect(fields['view_type'], 'popup');
      expect(fields['payment_gate'], '0');
      expect(fields.keys.last, 'hash');
    });

    test('check transaction, transaction detail and close transaction', () {
      for (final body in [
        builder.checkTransaction('order-1001'),
        builder.transactionDetail('order-1001'),
        builder.closeTransaction('order-1001'),
      ]) {
        expect(body, {
          'req_time': requestTime,
          'merchant_id': 'ec000002',
          'tran_id': 'order-1001',
          'hash': kat['tran_id_hash'],
        });
      }
    });

    test('transaction list', () {
      final body = builder.transactionList(
        PaywayTransactionListQuery(
          fromDate: DateTime(2026, 1, 1),
          toDate: DateTime(2026, 1, 31, 23, 59, 59),
          fromAmount: 1,
          toAmount: 100,
          statuses: const [
            PaywayPaymentStatus.approved,
            PaywayPaymentStatus.refunded,
          ],
          page: 2,
          pagination: 50,
        ),
      );
      expect(body['from_date'], '2026-01-01 00:00:00');
      expect(body['status'], 'APPROVED,REFUNDED');
      expect(body['hash'], kat['list_hash']);
    });

    test('exchange rate', () {
      expect(builder.exchangeRate()['hash'], kat['exchange_hash']);
    });
  });

  group('refund', () {
    test('merchant_auth is the RSA-encrypted refund, hashed with it', () {
      final body = builder.refund('order-1001', 0.5);
      expect(body.keys, [
        'request_time',
        'merchant_id',
        'merchant_auth',
        'hash',
      ]);
      expect(
        json.decode(
          rsaDecrypt(body['merchant_auth']!, fixture('rsa_1024_private.pem')),
        ),
        {'mc_id': 'ec000002', 'tran_id': 'order-1001', 'refund_amount': 0.5},
      );
      final expected = base64.encode(
        crypto.Hmac(crypto.sha512, utf8.encode('test-api-key'))
            .convert(
              utf8.encode('${requestTime}ec000002${body['merchant_auth']}'),
            )
            .bytes,
      );
      expect(body['hash'], expected);
    });

    test('a 2048 bit RSA key works too', () {
      final big = PaywayRequestBuilder(
        merchant: merchant.copyWith(
          rsaPublicKey: fixture('rsa_2048_public.pem'),
        ),
        clock: fixedClock,
      );
      final body = big.refund('order-1001', 1);
      expect(
        json.decode(
          rsaDecrypt(body['merchant_auth']!, fixture('rsa_2048_private.pem')),
        )['tran_id'],
        'order-1001',
      );
    });

    test('without the RSA key it throws an encryption error', () async {
      final service = PaywayService(
        merchant: PaywayMerchant(
          merchantId: 'm',
          apiKey: 'k',
          referer: '',
          baseApiUrl: 'https://payway.test',
        ),
      );
      expect(
        () => service.refund(tranId: 'x', amount: 1),
        throwsA(
          isA<PaywayException>().having(
            (e) => e.type,
            'type',
            PaywayErrorType.encryption,
          ),
        ),
      );
    });
  });

  group('callbacks', () {
    final service = PaywayService(merchant: merchant);

    test('the documented sample callback verifies', () {
      expect(
        service.verifyCallback(
          body: kat['callback_body'] as String,
          signature: kat['callback_signature'] as String,
        ),
        true,
      );
    });

    test('nested objects, unicode, booleans and null sign like PHP', () {
      expect(
        service.verifyCallback(
          body: kat['callback2_body'] as String,
          signature: kat['callback2_signature'] as String,
        ),
        true,
      );
    });

    test('a tampered body or wrong signature is rejected', () {
      final tampered = (kat['callback_body'] as String).replaceFirst(
        '0.01',
        '1000',
      );
      expect(
        service.verifyCallback(
          body: tampered,
          signature: kat['callback_signature'] as String,
        ),
        false,
      );
      expect(
        service.verifyCallback(
          body: kat['callback_body'] as String,
          signature: 'forged',
        ),
        false,
      );
      expect(service.verifyCallback(body: 'not json', signature: 'x'), false);
    });

    test('parseCallback reads the documented fields', () {
      final callback = service.parseCallback(kat['callback_body'] as String);
      expect(callback.tranId, '9065703303');
      expect(callback.isSuccess, true);
      expect(callback.totalAmount, 0.01);
      expect(callback.paymentType, 'ABA Pay');
      expect(
        () => service.parseCallback('[]'),
        throwsA(
          isA<PaywayException>().having(
            (e) => e.type,
            'type',
            PaywayErrorType.invalidCallback,
          ),
        ),
      );
    });
  });

  group('PaywayService with an injected Dio', () {
    test(
      'purchase posts multipart form data and parses the deeplink reply',
      () async {
        final adapter = FakeAdapter(
          (_) async => jsonResponse({
            'status': {
              'code': '00',
              'message': 'Success!',
              'tran_id': 'order-1001',
            },
            'qr_string': '000201...',
            'abapay_deeplink': 'abamobilebank://ababank.com?type=payway',
            'checkout_qr_url': 'https://checkout-sandbox.payway.com.kh/qr',
          }, 200),
        );

        final response = await serviceWith(adapter).purchase(fullPurchase);

        expect(response.isSuccess, true);
        expect(response.abapayDeeplink, startsWith('abamobilebank://'));
        final request = adapter.requests.single;
        expect(
          request.uri.toString(),
          'https://payway.test${PaywayService.purchasePath}',
        );
        expect(request.contentType, startsWith('multipart/form-data'));
        expect(adapter.bodies.single, contains(kat['purchase_full']));
        expect(request.headers['Referer'], 'https://shop.test');
        expect(
          request.headers['User-Agent'],
          'dart-payway/${PaywayService.sdkVersion}',
        );
      },
    );

    test('purchase needs abapayKhqrDeeplink; others use checkoutHtml', () {
      final service = serviceWith(
        FakeAdapter((_) async => throw UnimplementedError()),
      );
      expect(
        () => service.purchase(
          const PaywayPurchase(
            tranId: 'x',
            amount: 1,
            paymentOption: PaywayPaymentOption.cards,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('check transaction posts JSON and lifts a nested status', () async {
      final adapter = FakeAdapter(
        (_) async => jsonResponse({
          'data': {
            'payment_status_code': 0,
            'payment_status': 'APPROVED',
            'total_amount': '6.5',
            'apv': '753786',
            'status': {
              'code': '00',
              'message': 'Success!',
              'tran_id': 'order-1001',
            },
          },
        }, 200),
      );

      final response = await serviceWith(
        adapter,
      ).checkTransaction(tranId: 'order-1001');

      expect(response.isSuccess, true);
      expect(response.isPaid, true);
      expect(response.data!.totalAmount, 6.5);
      final request = adapter.requests.single;
      expect(request.uri.path, PaywayService.checkTransactionPath);
      expect(request.headers[Headers.contentTypeHeader], 'application/json');
      expect(
        json.decode(adapter.bodies.single),
        builder.checkTransaction('order-1001'),
      );
    });

    test('a PayWay error status is returned, not thrown', () async {
      final adapter = FakeAdapter(
        (_) async => jsonResponse({
          'status': {
            'code': '6',
            'message': 'Transaction not found',
            'tran_id': 'x',
          },
        }, 403),
      );
      final response = await serviceWith(
        adapter,
      ).getTransactionDetail(tranId: 'x');
      expect(response.isSuccess, false);
      expect(response.status.code, '6');
      expect(response.data, isNull);
    });

    test('transaction details parse operations', () async {
      final adapter = FakeAdapter(
        (_) async => jsonResponse({
          'data': {
            'transaction_id': '17394277693',
            'payment_status_code': 0,
            'payment_status': 'APPROVED',
            'total_amount': 0.1,
            'transaction_operations': [
              {
                'status': 'Completed',
                'amount': 0.1,
                'transaction_date': '2025-02-13 13:55:25',
                'bank_ref': 'FT1',
              },
            ],
          },
          'status': {'code': '00', 'message': 'Success!'},
        }, 200),
      );
      final response = await serviceWith(
        adapter,
      ).getTransactionDetail(tranId: '17394277693');
      expect(response.data!.isApproved, true);
      expect(response.data!.transactionOperations.single.bankRef, 'FT1');
    });

    test('exchange rates are read from both documented layouts', () async {
      final adapter = FakeAdapter(
        (_) async => jsonResponse({
          'status': {'code': '00', 'message': 'Success'},
          'exchange_rates': {
            'aud': {'sell': '0.68', 'buy': 0.66},
          },
          'eur': {'sell': 1.1, 'buy': 1.08},
        }, 200),
      );
      final response = await serviceWith(adapter).getExchangeRates();
      expect(response.rates.keys, containsAll(['aud', 'eur']));
      expect(response.rates['aud']!.sell, 0.68);
    });

    test('refund posts to the merchant-portal endpoint', () async {
      final adapter = FakeAdapter(
        (_) async => jsonResponse({
          'grand_total': 1.5,
          'total_refunded': 0.09,
          'currency': 'USD',
          'transaction_status': 'REFUNDED',
          'status': {'code': '00', 'message': 'Success!'},
        }, 200),
      );
      final response = await serviceWith(
        adapter,
      ).refund(tranId: 'order-1001', amount: 0.09);
      expect(response.isSuccess, true);
      expect(response.totalRefunded, 0.09);
      expect(adapter.requests.single.uri.path, PaywayService.refundPath);
    });

    test('network failures throw retryable connection errors', () async {
      final adapter = FakeAdapter(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      expect(
        serviceWith(adapter).closeTransaction(tranId: 'x'),
        throwsA(
          isA<PaywayException>()
              .having((e) => e.type, 'type', PaywayErrorType.connection)
              .having((e) => e.isRetryable, 'isRetryable', true),
        ),
      );
    });

    test('an HTML page instead of JSON is an unexpected response', () async {
      final adapter = FakeAdapter(
        (_) async => ResponseBody.fromString('<html>', 502),
      );
      expect(
        serviceWith(adapter).getTransactionList(),
        throwsA(
          isA<PaywayException>()
              .having((e) => e.type, 'type', PaywayErrorType.unexpectedResponse)
              .having((e) => e.statusCode, 'statusCode', 502),
        ),
      );
    });

    test('a cancelled call is typed', () async {
      final adapter = FakeAdapter(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        ),
      );
      expect(
        serviceWith(
          adapter,
        ).checkTransaction(tranId: 'x', cancelToken: CancelToken()),
        throwsA(
          isA<PaywayException>().having(
            (e) => e.type,
            'type',
            PaywayErrorType.cancelled,
          ),
        ),
      );
    });

    test('logs go to the injected logger only', () async {
      final lines = <String>[];
      final adapter = FakeAdapter(
        (_) async => jsonResponse({
          'status': {'code': '00', 'message': 'ok'},
        }, 200),
      );
      await serviceWith(
        adapter,
        logger: lines.add,
      ).closeTransaction(tranId: 'x');
      expect(lines, hasLength(2));
      expect(lines.first, contains('POST https://payway.test'));
    });
  });

  group('checkoutHtml', () {
    final service = PaywayService(merchant: merchant, clock: fixedClock);

    test('auto-submits the signed purchase to PayWay', () {
      final html = service.checkoutHtml(fullPurchase);
      expect(
        html,
        contains('action="https://payway.test${PaywayService.purchasePath}"'),
      );
      expect(html, contains('name="hash" value="${kat['purchase_full']}"'));
      expect(html, contains('.submit()'));
    });

    test('escapes values', () {
      final html = service.checkoutHtml(
        const PaywayPurchase(
          tranId: 'x',
          amount: 1,
          firstName: '"><script>alert(1)</script>',
        ),
      );
      expect(html, isNot(contains('<script>alert')));
      expect(html, contains('&quot;&gt;&lt;script&gt;'));
    });

    test('checkoutUri wraps it in a data URI', () {
      expect(service.checkoutUri(fullPurchase).scheme, 'data');
    });
  });

  group('models', () {
    test('status codes of payments', () {
      expect(PaywayPaymentStatusCode.refunded, 4);
      expect(const PaywayStatus(code: '0', message: '').isSuccess, true);
    });

    test('merchant JSON round-trips and toString hides the key', () {
      expect(PaywayMerchant.fromJson(merchant.toJson()), merchant);
      expect(merchant.toString(), isNot(contains('test-api-key')));
    });

    test('numbers sent as strings still parse', () {
      final status = PaywayTransactionStatus.fromJson({
        'payment_status_code': '2',
        'total_amount': '10.5',
      });
      expect(status.paymentStatusCode, PaywayPaymentStatusCode.pending);
      expect(status.totalAmount, 10.5);
    });
  });

  test('sdkVersion matches pubspec.yaml', () {
    final pubspec = io.File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: (\S+)',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(PaywayService.sdkVersion, version.group(1));
  });
}

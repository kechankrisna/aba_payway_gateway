import 'dart:math';

import 'package:dart_payway/dart_payway.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io' as io;

void main() {
  group("load env and test", () {
    late PaywayTransactionService service;
    setUpAll(() {
      io.HttpOverrides.global = null;

      var env = DotEnv(includePlatformEnvironment: true)..load();

      service = PaywayTransactionService(
          merchant: PaywayMerchant(
        merchantID: env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
        merchantApiName: env['ABA_PAYWAY_MERCHANT_NAME'] ?? '',
        merchantApiKey: env['ABA_PAYWAY_API_KEY'] ?? '',
        baseApiUrl: env['ABA_PAYWAY_API_URL'] ?? '',
        refererDomain: "http://mylekha.app",
      ));
    });

    test("create a transaction then check status pending", () async {
      final tranID = service.uniqueTranID();

      var _transaction = PaywayCreateTransaction(
        amount: 10.00,
        items: [
          PaywayTransactionItem(name: "ទំនិញ 1", price: 2, quantity: 1),
          PaywayTransactionItem(name: "ទំនិញ 2", price: 3, quantity: 1),
          PaywayTransactionItem(name: "ទំនិញ 3", price: 5, quantity: 1),
        ],
        reqTime: service.uniqueReqTime(),
        tranId: tranID,
        email: 'support@mylekha.app',
        firstname: 'Miss',
        lastname: 'My Lekha',
        phone: '010464144',
        option: PaywayPaymentOption.abapay_deeplink,
        shipping: 0.0,
        returnUrl: "https://mylekha.org/api/v1.0/integrate/payway/success",
        returnParams: EncoderService.base64_encode({ 'key_1': 'value_1', 'key_2': 'value_2' }),
        customFields :EncoderService.base64_encode({"Purcahse order ref":"Po-MX9901", "Customfield2":"value for custom field"}),
      );

      var createResponse =
          await service.createTransaction(transaction: _transaction, enabledLogger: true);

      expect(createResponse.abapayDeeplink != null, true,
          reason: "the deeplink should be a string according to docs");

      var checkResponse = await service.checkTransaction(
          transaction: PaywayCheckTransaction(
        tranId: _transaction.tranId,
        reqTime: service.uniqueReqTime(),
      ));

      expect(checkResponse.status == 2, true,
          reason: "the new transaction created should be pending or status 2");
    });

    test("generate checkout uri for a transaction then check status pending",
        () async {
      final tranID = service.uniqueTranID();

      var _transaction = PaywayCreateTransaction(
        amount: 10,
        items: [
          PaywayTransactionItem(name: "ទំនិញ 1", price: 5, quantity: 1),
          PaywayTransactionItem(name: "ទំនិញ 2", price: 3, quantity: 1),
          PaywayTransactionItem(name: "ទំនិញ 3", price: 2, quantity: 1),
        ],
        reqTime: service.uniqueReqTime(),
        tranId: tranID,
        email: 'support@mylekha.app',
        firstname: 'Miss',
        lastname: 'My Lekha',
        phone: '010464144',
        option: PaywayPaymentOption.abapay,
        shipping: 0.0,
        returnUrl: "https://mylekha.org/api/v1.0/integrate/payway/success",
        returnParams: EncoderService.base64_encode({ 'key_1': 'value_1', 'key_2': 'value_2' }),
        customFields :EncoderService.base64_encode({"Purcahse order ref":"Po-MX9901", "Customfield2":"value for custom field"}),
      );

      var webURI = await service.generateTransactionCheckoutURI(
          transaction: _transaction);
      io.File('checkout.html').writeAsString(webURI.data!.contentAsString());

      /// print(webURI);

      /// expect(
      ///     webURI.queryParameters['items'],
      ///     EncoderService.base64_encode(
      ///         _transaction.items.map((e) => e.toMap()).toList()),
      ///     reason: "encoded items should be equal");

      expect(webURI.toString().isNotEmpty, true,
          reason: "the uri should be generated");
    });
  });
}

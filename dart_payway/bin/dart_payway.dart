import 'dart:io';

import 'package:dart_payway/dart_payway.dart';
import 'package:dotenv/dotenv.dart';

void main(List<String> arguments) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final service = PaywayTransactionService(
      merchant: PaywayMerchant(
    merchantID: env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
    merchantApiName: env['ABA_PAYWAY_MERCHANT_NAME'] ?? '',
    merchantApiKey: env['ABA_PAYWAY_API_KEY'] ?? '',
    baseApiUrl: env['ABA_PAYWAY_API_URL'] ?? '',
    refererDomain: "http://mylekha.app",
  ));

  /// create transaction
  final tranID = service.uniqueTranID();

  var _transaction = PaywayCreateTransaction(
      amount: 6.00,
      items: [
        PaywayTransactionItem(name: "ទំនិញ 1", price: 1, quantity: 1),
        PaywayTransactionItem(name: "ទំនិញ 2", price: 2, quantity: 1),
        PaywayTransactionItem(name: "ទំនិញ 3", price: 3, quantity: 1),
      ],
      reqTime: service.uniqueReqTime(),
      tranId: tranID,
      email: 'support@mylekha.app',
      firstname: 'Miss',
      lastname: 'My Lekha',
      phone: '010464144',
      option: PaywayPaymentOption.abapay_deeplink,
      shipping: 0.0,
      returnUrl: "https://stage.mylekha.app");

  var createResponse =
      await service.createTransaction(transaction: _transaction);

  print(_transaction.amount);
  print(createResponse.status);
  exit(0);
}

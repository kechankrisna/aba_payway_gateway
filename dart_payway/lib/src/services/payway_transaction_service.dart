import 'dart:convert';
import 'package:dart_payway/dart_payway.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class PaywayTransactionService {
  late PaywayMerchant merchant;

  PaywayTransactionService({required this.merchant});

  PaywayClientService? get helper => PaywayClientService(merchant);

  String uniqueTranID() => "${DateTime.now().microsecondsSinceEpoch}";
  String uniqueReqTime() =>
      "${DateFormat("yMddhhmmss").format(DateTime.now())}";

  /// ## [createTransaction]
  ///
  /// create a new trasaction
  ///
  /// `transaction`: this information is required
  ///
  /// Usage:
  ///
  /// ```dart
  ///
  /// var _transaction = PaywayCreateTransaction(
  ///     amount: 6.00,
  ///     items: [
  ///       PaywayTransactionItem(name: "ទំនិញ 1", price: 1, quantity: 1),
  ///       PaywayTransactionItem(name: "ទំនិញ 2", price: 2, quantity: 1),
  ///       PaywayTransactionItem(name: "ទំនិញ 3", price: 3, quantity: 1),
  ///     ],
  ///     reqTime: service.uniqueReqTime(),
  ///     tranId: service.uniqueTranID(),
  ///     email: 'support@mylekha.app',
  ///     firstname: 'Miss',
  ///     lastname: 'My Lekha',
  ///     phone: '010464144',
  ///     option: PaywayPaymentOption.abapay_deeplink,
  ///     shipping: 0.0,
  ///     returnUrl: "https://stage.mylekha.app");
  ///
  /// var createResponse = await service.createTransaction(transaction: _transaction);
  ///
  /// ```
  Future<PaywayCreateTransactionResponse> createTransaction(
      {required PaywayCreateTransaction transaction,
      bool enabledLogger = false}) async {
    var res = PaywayCreateTransactionResponse(status: 11);
    var _transaction = transaction;
    if (![PaywayPaymentOption.abapay_deeplink].contains(transaction.option)) {
      _transaction =
          _transaction.copyWith(option: PaywayPaymentOption.abapay_deeplink);
    }
    assert([PaywayPaymentOption.abapay_deeplink].contains(_transaction.option));

    final clientService = PaywayClientFormRequestService(merchant: merchant);
    Map<String, dynamic> map =
        clientService.generateCreateTransactionFormData(_transaction);

    var formData = FormData.fromMap(map);
    try {
      if (helper == null) return PaywayCreateTransactionResponse();
      final client = helper!.client;

      if (enabledLogger) {
        debugPrint(json.encode(map));
        client.interceptors.add(dioLoggerInterceptor);
      }

      Response<String> response = await client
          .post("/api/payment-gateway/v1/payments/purchase", data: formData);

      var _map = json.decode(response.data!) as Map<String, dynamic>;
      res = PaywayCreateTransactionResponse.fromMap(_map);
      return res;
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res = res.copyWith(
          description: PaywayClientService.handleResponseError(error));
    }
    return res;
  }

  /// ## [generateTransactionCheckoutURI]
  ///
  /// generate the html weburi
  ///
  /// `transaction`: is requied to generate the html weburi
  ///
  /// Usage
  ///
  /// ```dart
  ///
  /// var _transaction = PaywayCreateTransaction(
  ///     amount: 100.00,
  ///     items: [
  ///       PaywayTransactionItem(name: "ទំនិញ 1", price: 50, quantity: 1),
  ///       PaywayTransactionItem(name: "ទំនិញ 2", price: 30, quantity: 1),
  ///       PaywayTransactionItem(name: "ទំនិញ 3", price: 20, quantity: 1),
  ///     ],
  ///     reqTime: service.uniqueReqTime(),
  ///     tranId: service.uniqueTranID(),
  ///     email: 'support@mylekha.app',
  ///     firstname: 'Miss',
  ///     lastname: 'My Lekha',
  ///     phone: '010464144',
  ///     option: PaywayPaymentOption.abapay,
  ///     shipping: 0.0,
  ///     returnUrl: "");
  ///
  /// var webURI = await service.generateTransactionCheckoutURI(transaction: _transaction);
  ///
  /// ```
  Future<Uri> generateTransactionCheckoutURI({
    required PaywayCreateTransaction transaction,
  }) async {
    var _transaction = transaction;
    if (![PaywayPaymentOption.cards, PaywayPaymentOption.abapay]
        .contains(transaction.option)) {
      _transaction = _transaction.copyWith(option: PaywayPaymentOption.cards);
    }

    assert([
      PaywayPaymentOption.cards,
      PaywayPaymentOption.abapay,
    ].contains(_transaction.option));

    final service = PaywayClientService(merchant);
    var items = EncoderService.base64_encode(_transaction.items);
    var str = service.getStr(
      reqTime: _transaction.reqTime,
      tranId: _transaction.tranId,
      amount: _transaction.amount.toString(),
      items: items,
      shipping: _transaction.shipping.toString(),

      firstName: _transaction.firstname.toString(),
      lastName: _transaction.lastname.toString(),
      email: _transaction.email.toString(),
      phone: _transaction.phone.toString(),
      currency: _transaction.currency.name,

      /// ctid : "",
      /// pwt : "",
      /// type : "",
      /// paymentOption: "",
      returnUrl: EncoderService.base64_encode( _transaction.returnUrl ?? "") ,
      /// cancelUrl : "",
      /// continueSuccessUrl : "",
      /// returnDeeplink : "",
      /// customFields : "",
      /// returnParams : "",
    );

    /// _transaction.reqTime.toString() +
    ///     merchant.merchantID.toString() +
    ///     _transaction.tranId.toString() +
    ///     _transaction.amount.toString() +
    ///     items +
    ///     _transaction.shipping.toString() +
    ///     _transaction.firstname.toString() +
    ///     _transaction.lastname +
    ///     _transaction.email +
    ///     _transaction.phone +
    ///     _transaction.currency.name;

    final hash = PaywayClientService(merchant).getHash(str);

    final template = """
<!DOCTYPE html>
<html lang="en">

<head>
    <title>Payway</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
    <meta name="author" content="PayWay">
</head>

<body>
<div id="aba_main_modal" class="aba-modal">
    <div class="aba-modal-content">
        <form method="POST" action="${merchant.baseApiUrl}/api/payment-gateway/v1/payments/purchase" id="aba_merchant_request">
            <input type="hidden" name="hash" value="${hash}" id="hash"/>
            <input type="hidden" name="tran_id" value="${_transaction.tranId}" id="tran_id"/>
            <input type="hidden" name="amount" value="${_transaction.amount}" id="amount"/>
            <input type="hidden" name="items" value="${items}" id="items"/>
            <input type="hidden" name="firstname" value="${_transaction.firstname}" id="firstname" />
            <input type="hidden" name="lastname" value="${_transaction.lastname}" id="lastname" />
            <input type="hidden" name="phone" value="${_transaction.phone}" id="phone" /> 
            <input type="hidden" name="email" value="${_transaction.email}" id="email" /> 
            <input type="hidden" name="req_time" value="${_transaction.reqTime}" id="req_time" />
            <input type="hidden" name="merchant_id" value="${merchant.merchantID}" id="merchant_id" />
            <input type="hidden" name="shipping" value="${_transaction.shipping}" id="shipping" />
            <input type="hidden" name="currency" value="${_transaction.currency.name}" id="currency" />
            <input type="hidden" name="return_url" value="${EncoderService.base64_encode( _transaction.returnUrl ?? "")}" id="return_url" />
            <input style="display: none;" type="radio" name="payment_option" value="${_transaction.option.name}" id="payment_option" />
            <input type="hidden" name="payment_gate"  value="0" id="payment_gate" />
        </form>
    </div>
</div>

<script>
    window.onload = () => document.querySelector("#aba_merchant_request").submit()
</script>

</body>
</html>
""";

    return Uri.dataFromString(template, mimeType: "text/html");
  }

  /// ## [checkTransaction]
  /// check the current status of this transaction vai its id
  Future<PaywayCheckTransactionResponse> checkTransaction(
      {required PaywayCheckTransaction transaction,
      bool enabledLogger = false}) async {
    var res = PaywayCheckTransactionResponse(status: 11);

    final clientService = PaywayClientFormRequestService(merchant: merchant);
    Map<String, dynamic> map =
        clientService.generateCheckTransactionFormData(transaction);

    var formData = FormData.fromMap(map);

    try {
      if (helper == null) return PaywayCheckTransactionResponse();
      final client = helper!.client;

      if (enabledLogger) {
        debugPrint(json.encode(map));
        client.interceptors.add(dioLoggerInterceptor);
      }

      Response<String> response = await client.post(
          "/api/payment-gateway/v1/payments/check-transaction",
          data: formData);

      var _map = json.decode(response.data!) as Map<String, dynamic>;
      res = PaywayCheckTransactionResponse.fromMap(_map);
      return res;
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res = res.copyWith(
          description: PaywayClientService.handleResponseError(error));
    }
    return res;
  }

  /// ## [isValidate]
  /// will return true if transaction completed
  /// otherwise false
  Future<bool> isTransactionCompleted(
      {required PaywayCheckTransaction transaction}) async {
    var result = await checkTransaction(transaction: transaction);
    return (result.status == 0);
  }
}

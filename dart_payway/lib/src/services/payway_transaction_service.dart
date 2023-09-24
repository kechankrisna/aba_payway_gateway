import 'dart:convert';
import 'package:dart_payway/dart_payway.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class PaywayTransactionService {

  late ABAMerchant merchant;  

  PaywayTransactionService({required this.merchant});

  ABAClientService? get helper => ABAClientService(merchant);

  String uniqueTranID() => "${DateTime.now().microsecondsSinceEpoch}";
  String uniqueReqTime() => "${DateFormat("yMddHms").format(DateTime.now())}";

  /// ## [createTransaction]
  /// create a new trasaction
  Future<PaywayCreateTransactionResponse> createTransaction(
      {required PaywayCreateTransaction transaction,
      bool enabledLogger = false}) async {
    var res = PaywayCreateTransactionResponse(status: 11);
    var _transaction = transaction;
    if (![ABAPaymentOption.abapay_deeplink].contains(transaction.option)) {
      _transaction =
          _transaction.copyWith(option: ABAPaymentOption.abapay_deeplink);
    }
    assert([ABAPaymentOption.abapay_deeplink].contains(_transaction.option));

    final clientService = ABAClientFormRequestService(merchant: merchant);
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

      Response<String> response =
          await client.post("/purchase", data: formData);

      var _map = json.decode(response.data!) as Map<String, dynamic>;
      res = PaywayCreateTransactionResponse.fromMap(_map);
      return res;
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res = res.copyWith(
          description: ABAClientService.handleResponseError(error));
    }
    return res;
  }

  Future<Uri> generateTransactionCheckoutURI({
    required PaywayCreateTransaction transaction,
    required String checkoutApiUrl,
  }) async {
    assert(checkoutApiUrl.isNotEmpty);
    var _transaction = transaction;
    if (![ABAPaymentOption.cards, ABAPaymentOption.abapay]
        .contains(transaction.option)) {
      _transaction = _transaction.copyWith(option: ABAPaymentOption.cards);
    }

    assert([
      ABAPaymentOption.cards,
      ABAPaymentOption.abapay,
    ].contains(_transaction.option));

    final clientService = ABAClientFormRequestService(merchant: merchant);
    Map<String, dynamic> map =
        clientService.generateCreateTransactionFormData(_transaction);

    var parsed = Uri.tryParse(checkoutApiUrl)!;

    return parsed.authority.contains("https")
        ? Uri.https(parsed.authority, parsed.path, map)
        : Uri.http(parsed.authority, parsed.path, map);
  }

  /// ## [checkTransaction]
  /// check the current status of this transaction vai its id
  Future<PaywayCheckTransactionResponse> checkTransaction(
      {required PaywayCheckTransaction transaction,
      bool enabledLogger = false}) async {
    var res = PaywayCheckTransactionResponse(status: 11);

    final clientService = ABAClientFormRequestService(merchant: merchant);
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

      Response<String> response =
          await client.post("/check-transaction", data: formData);

      var _map = json.decode(response.data!) as Map<String, dynamic>;
      res = PaywayCheckTransactionResponse.fromMap(_map);
      return res;
    } catch (error, stacktrace) {
      print("Exception occured: $error stackTrace: $stacktrace");
      res = res.copyWith(
          description: ABAClientService.handleResponseError(error));
    }
    return res;
  }

  /// ## [isValidate]
  /// will return true if transaction completed
  /// otherwise false
  Future<bool> isTransactionCompleted(
      {required PaywayCheckTransaction transaction}) async {
    var result = await this.checkTransaction(transaction: transaction);
    return (result.status == 0);
  }
}

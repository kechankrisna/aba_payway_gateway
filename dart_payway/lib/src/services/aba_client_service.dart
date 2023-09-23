import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_payway/dart_payway.dart';
import 'package:dio/dio.dart';

class ABAClientService {
  final ABAMerchant? merchant;
  ABAClientService(this.merchant);

  /// [client]
  /// Return dio object for http helper
  /// ### Example:
  /// ```
  /// var merchant = ABAMerchant();
  /// var helper = ABAClientService(merchant);
  /// var dio = helper.getDio();
  /// ```
  Dio get client {
    Dio dio = Dio();
    dio.options.baseUrl = merchant!.baseApiUrl!;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    dio.httpClientAdapter = PlatformHttpClientAdapter().clientAdapter();

    /// [add interceptors]
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      if (!kIsWeb) {
        options.headers["Referer"] = merchant!.refererDomain;
      }
      options.headers["Accept"] = "application/json";
      return handler.next(options);
    }, onResponse: (response, handler) {
      // Do something with response data
      return handler.next(response); // continue
      // If you want to reject the request with a error message,
      // you can reject a `DioError` object eg: return `dio.reject(dioError)`
    }, onError: (DioException e, handler) {
      // Do something with response error
      return handler.next(e); //continue
      // If you want to resolve the request with some custom data，
      // you can resolve a `Response` object eg: return `dio.resolve(response)`.
    }));
    return dio;
  }

  /// [getHash]
  ///
  /// `tranID`: unique tran_id < 20 characters (number, character and (-) only)
  ///
  /// `amount`: total amount
  ///
  /// `item`: base64_encode (json_encode(array item))
  ///
  /// `shipping`: shipping value
  ///
  /// ### Example:
  /// ```
  /// var merchant = ABAMerchant();
  /// var helper = ABAClientHelper(merchant);
  /// var tranID = DateTime.now().microsecondsSinceEpoch.toString();
  /// var reqTime = DateTime.now().toUtc();
  /// var amount = 0.00;
  /// var hash = helper.getHash(tranID: tranID, amount: amount);
  /// print(hash);
  /// ```

  String getHash({
    required String reqTime,
    required String tranId,
    String amount = "",
    String items = "",
    String shipping = "",
    String ctid = "",
    String pwt = "",
    String? firstName = "",
    String? lastName = "",
    String? email = "",
    String? phone = "",
    String type = "",
    String paymentOption = "",
    String returnUrl = "",
    String cancelUrl = "",
    String continueSuccessUrl = "",
    String returnDeeplink = "",
    String currency = "",
    String customFields = "",
    String returnParams = "",
  }) {
    // String =
    // req_time + merchant_id +
    // tran_id + amount + items +
    // shipping + ctid + pwt +
    // firstname + lastname +
    // email + phone + type +
    // payment_option + return_url +
    // cancel_url + continue_success_url +
    // return_deeplink + currency + custom_fields + return_params with public_key.
    // assert(tranID != null);
    // assert(amount != null);
    var key = utf8.encode(merchant!.merchantApiKey!);
    var raw =
        "$reqTime ${merchant!.merchantID} $tranId $amount $items $shipping $ctid $pwt $firstName $lastName $email $phone $type $paymentOption $returnUrl $cancelUrl $continueSuccessUrl $returnDeeplink $currency $customFields $returnParams";
    var str =
        "$reqTime${merchant!.merchantID}$tranId$amount$items$shipping$ctid$pwt$firstName$lastName$email$phone$type$paymentOption$returnUrl$cancelUrl$continueSuccessUrl$returnDeeplink$currency$customFields$returnParams";

    var bytes = utf8.encode(str);
    var digest = crypto.Hmac(crypto.sha512, key).convert(bytes);
    var hash = base64Encode(digest.bytes);
    return hash;
  }

  /// [handleTransactionResponse]
  ///
  /// `This will be describe response from each transaction based on status code`
  static String handleTransactionResponse(int status) {
    switch (status) {
      case 1:
        return "Invalid Hash, Hash generated is incorrect and not following the guideline to generate the Hash.";
      case 2:
        return "Invalid Transaction ID, unsupported characters included in Transaction ID";
      case 3:
        return "Invalid Amount format need not include decimal point for KHR transaction. example for USD 100.00 for KHR 100";
      case 4:
        return "Duplicate Transaction ID, the transaction ID already exists in PayWay, generate new transaction.";
      case 5:
        return "Invalid Continue Success URL, (Main domain must be registered in PayWay backend to use success URL)";
      case 6:
        return "Invalid Domain Name (Request originated from non-whitelisted domain need to register domain in PayWay backend)";
      case 7:
        return "Invalid Return Param (String must be lesser than 500 chars)";
      case 9:
        return "Invalid Limit Amount (The amount must be smaller than value that allowed in PayWay backend)";
      case 10:
        return "Invalid Shipping Amount";
      case 11:
        return "PayWay Server Side Error";
      case 12:
        return "Invalid Currency Type (Merchant is allowed only one currency - USD or KHR)";
      case 13:
        return "Invalid Item, value for items parameters not following the guideline to generate the base 64 encoded array of item list.";
      case 15:
        return "Invalid Channel Values for parameter topup_channel";
      case 16:
        return "Invalid First Name - unsupported special characters included in value";
      case 17:
        return "Invalid Last Name";
      case 18:
        return "Invalid Phone Number";
      case 19:
        return "Invalid Email Address";
      case 20:
        return "Required purchase details when checkout";
      case 21:
        return "Expired production key";
      default:
        return "other - server-side error";
    }
  }

  static String handleResponseError(dynamic error) {
    String errorDescription = "";
    if (error is DioException) {
      DioException dioError = error;
      switch (dioError.type) {
        case DioExceptionType.connectionTimeout:
          errorDescription = "Connection timeout with API server";
          break;
        case DioExceptionType.sendTimeout:
          errorDescription = "Send timeout in connection with API server";
          break;
        case DioExceptionType.receiveTimeout:
          errorDescription = "Receive timeout in connection with API server";
          break;
        case DioExceptionType.badResponse:
          errorDescription =
              "Received invalid status code: ${dioError.response!.statusCode}";
          break;
        case DioExceptionType.cancel:
          errorDescription = "Request to API server was cancelled";
          break;
        case DioExceptionType.unknown:
          errorDescription =
              "Connection to API server failed due to internet connection";
          break;
        case DioExceptionType.badCertificate:
          errorDescription = "Bad Certificate Error";
          break;
        case DioExceptionType.connectionError:
          errorDescription = "Connection Error";
          break;
      }
    } else {
      errorDescription = "Unexpected error occured";
    }
    return errorDescription;
  }
}

/// middleware
///
final dioLoggerInterceptor =
    InterceptorsWrapper(onRequest: (RequestOptions options, handler) {
  debugPrint(
      "┌------------------------------------------------------------------------------");
  debugPrint('| [DIO] Request: ${options.method} ${options.uri}');
  debugPrint('| ${options.data.toString()}');
  debugPrint('| Headers:');
  options.headers.forEach((key, value) {
    debugPrint('|\t$key: $value');
  });
  debugPrint(
      "├------------------------------------------------------------------------------");
  handler.next(options); //continue
}, onResponse: (Response response, handler) async {
  debugPrint(
      "| [DIO] Response [code ${response.statusCode}]: ${response.data.toString()}");
  debugPrint(
      "└------------------------------------------------------------------------------");
  handler.next(response);
  // return response; // continue
}, onError: (DioException error, handler) async {
  debugPrint("| [DIO] Error: ${error.error}: ${error.response.toString()}");
  debugPrint(
      "└------------------------------------------------------------------------------");
  handler.next(error); //continue
});

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dart_payway_partner/dart_payway_partner.dart';
import 'package:dio/dio.dart';

class PaywayPartnerClientService {
  final PaywayPartner? partner;
  PaywayPartnerClientService(this.partner);

  /// [client]
  /// Return dio object for http helper
  /// ### Example:
  /// ```
  /// var partner = PaywayPartner();
  /// var helper = PaywayPartnerClientService(partner);
  /// var dio = helper.getDio();
  /// ```
  Dio get client {
    Dio dio = Dio();
    dio.options.baseUrl = partner!.baseApiUrl;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    dio.httpClientAdapter = PlatformHttpClientAdapter().clientAdapter();

    /// [add interceptors]
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
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
  /// `request_time`: unique request time
  ///
  /// `request_data`: base64_encode string
  ///
  /// ### Example:
  /// ```
  /// var partner = PaywayPartner();
  /// var helper = PaywayPartnerClientHelper(partner);
  /// var tranID = DateTime.now().microsecondsSinceEpoch.toString();
  /// var request_time = DateTime.now().toUtc();
  /// var request_data = "base_64 string";
  /// var hash = helper.getHash(request_time: request_time, request_data: request_data);
  /// print(hash);
  /// ```
  String getStr({
    required String request_time,
    required String request_data,
  }) {
    // String =
    // partner_id + request_data + req_time + public_key
    assert(partner != null);
    var str = "${partner!.partnerID}$request_data$request_time";

    return str;
  }

  String getHash(String str) {
    var key = utf8.encode(partner!.partnerKey);
    var bytes = utf8.encode(str);
    var digest = crypto.Hmac(crypto.sha256, key).convert(bytes);
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

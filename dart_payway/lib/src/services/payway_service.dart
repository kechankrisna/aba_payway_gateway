import 'dart:convert';

import 'package:dio/dio.dart';

import '../exceptions.dart';
import '../models/payway_enums.dart';
import '../models/payway_merchant.dart';
import '../models/requests/payway_purchase.dart';
import '../models/requests/payway_transaction_list_query.dart';
import '../models/responses/payway_callback.dart';
import '../models/responses/payway_purchase_response.dart';
import '../models/responses/payway_responses.dart';
import '../version.dart';
import 'payway_crypto.dart';
import 'payway_request_builder.dart';

/// receives request/response log lines
typedef PaywayLogger = void Function(String message);

/// browsers do not allow setting `Referer` or `User-Agent`
const bool _kIsWeb =
    bool.fromEnvironment('dart.library.js_util') ||
    bool.fromEnvironment('dart.library.js_interop');

/// ABA PayWay Ecommerce Checkout client.
///
/// ```dart
/// final payway = PaywayService(merchant: merchant);
/// final status = await payway.checkTransaction(tranId: 'order-1001');
/// if (status.isPaid) deliverOrder();
/// ```
///
/// PayWay business errors (wrong hash, transaction not found, ...) are
/// returned in `status`. A [PaywayException] is thrown only when PayWay
/// could not be reached or did not answer with a status.
///
/// Run API calls on your server: the API key is a secret.
class PaywayService {
  /// version of this SDK, sent as `User-Agent: dart-payway/<version>`
  static const String sdkVersion = packageVersion;

  /// endpoint of [purchase] and [checkoutHtml]
  static const String purchasePath =
      '/api/payment-gateway/v1/payments/purchase';

  /// endpoint of [checkTransaction]
  static const String checkTransactionPath =
      '/api/payment-gateway/v1/payments/check-transaction-2';

  /// endpoint of [getTransactionDetail]
  static const String transactionDetailPath =
      '/api/payment-gateway/v1/payments/transaction-detail';

  /// endpoint of [closeTransaction]
  static const String closeTransactionPath =
      '/api/payment-gateway/v1/payments/close-transaction';

  /// endpoint of [getTransactionList]
  static const String transactionListPath =
      '/api/payment-gateway/v1/payments/transaction-list-2';

  /// endpoint of [getExchangeRates]
  static const String exchangeRatePath =
      '/api/payment-gateway/v1/exchange-rate';

  /// endpoint of [refund]
  static const String refundPath =
      '/api/merchant-portal/merchant-access/online-transaction/refund';

  /// header carrying the callback signature
  static const String callbackSignatureHeader = 'x-payway-hmac-sha512';

  /// merchant credentials used to sign
  final PaywayMerchant merchant;

  /// hashing and encryption
  final PaywayCrypto crypto;

  /// builds the signed request bodies; exposed to support new endpoints
  final PaywayRequestBuilder requestBuilder;

  final Dio _dio;
  final PaywayLogger? _logger;

  /// Creates a client for [merchant].
  ///
  /// Every dependency except [merchant] is optional and injectable:
  /// - `dio`: HTTP client, used as is (URLs and headers are set per request)
  ///   and reused for all calls
  /// - `clock`: source of `req_time` (default `DateTime.now`)
  /// - `crypto`: hashing and encryption
  /// - `logger`: receives request/response logs; nothing is logged without it
  PaywayService({
    required this.merchant,
    Dio? dio,
    PaywayClock? clock,
    this.crypto = const PaywayCrypto(),
    PaywayLogger? logger,
  }) : requestBuilder = PaywayRequestBuilder(
         merchant: merchant,
         clock: clock,
         crypto: crypto,
       ),
       _dio = dio ?? createDio(),
       _logger = logger;

  /// default HTTP client: platform adapter with certificate validation
  static Dio createDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// ## [purchase]
  ///
  /// Creates a payment and returns its KHQR string, ABA Mobile deep link and
  /// hosted QR page. Only [PaywayPaymentOption.abapayKhqrDeeplink] answers
  /// with JSON; every other payment option renders PayWay's payment page,
  /// so use [checkoutHtml] for those.
  Future<PaywayPurchaseResponse> purchase(
    PaywayPurchase purchase, {
    CancelToken? cancelToken,
  }) {
    if (purchase.paymentOption != PaywayPaymentOption.abapayKhqrDeeplink) {
      throw ArgumentError.value(
        purchase.paymentOption,
        'paymentOption',
        'only abapayKhqrDeeplink returns JSON; '
            'use checkoutHtml() for the hosted payment page',
      );
    }
    return _post(
      purchasePath,
      FormData.fromMap(requestBuilder.purchase(purchase)),
      PaywayPurchaseResponse.fromJson,
      cancelToken,
    );
  }

  /// ## [checkoutHtml]
  ///
  /// An HTML page that immediately POSTs [purchase] to PayWay, opening its
  /// hosted payment page. Load it in a web view (see [checkoutUri]) or serve
  /// it from your site.
  String checkoutHtml(PaywayPurchase purchase) {
    final fields = requestBuilder.purchase(purchase);
    final inputs = fields.entries
        .map(
          (e) =>
              '<input type="hidden" name="${_escape(e.key)}" value="${_escape(e.value)}">',
        )
        .join('\n      ');
    final action = _escape(_uri(purchasePath).toString());
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PayWay</title>
</head>
<body>
  <form method="POST" action="$action" id="payway_checkout">
      $inputs
  </form>
  <script>document.getElementById("payway_checkout").submit();</script>
</body>
</html>
''';
  }

  /// [checkoutHtml] as a `data:` URI, e.g. for `WebView` or `launchUrl`.
  Uri checkoutUri(PaywayPurchase purchase) => Uri.dataFromString(
    checkoutHtml(purchase),
    mimeType: 'text/html',
    encoding: utf8,
  );

  /// ## [checkTransaction]
  ///
  /// Status of a transaction created within the last 7 days; older ones
  /// need [getTransactionDetail].
  Future<PaywayCheckTransactionResponse> checkTransaction({
    required String tranId,
    CancelToken? cancelToken,
  }) {
    return _post(
      checkTransactionPath,
      requestBuilder.checkTransaction(tranId),
      PaywayCheckTransactionResponse.fromJson,
      cancelToken,
    );
  }

  /// ## [getTransactionDetail]
  ///
  /// Details of a transaction, including its payment and refund operations.
  Future<PaywayTransactionDetailResponse> getTransactionDetail({
    required String tranId,
    CancelToken? cancelToken,
  }) {
    return _post(
      transactionDetailPath,
      requestBuilder.transactionDetail(tranId),
      PaywayTransactionDetailResponse.fromJson,
      cancelToken,
    );
  }

  /// ## [closeTransaction]
  ///
  /// Cancels an unpaid transaction: later payments are rejected or reversed
  /// and no callback is sent.
  Future<PaywayStatusResponse> closeTransaction({
    required String tranId,
    CancelToken? cancelToken,
  }) {
    return _post(
      closeTransactionPath,
      requestBuilder.closeTransaction(tranId),
      PaywayStatusResponse.fromJson,
      cancelToken,
    );
  }

  /// ## [getTransactionList]
  ///
  /// Transactions matching [query], one page at a time.
  Future<PaywayTransactionListResponse> getTransactionList({
    PaywayTransactionListQuery query = const PaywayTransactionListQuery(),
    CancelToken? cancelToken,
  }) {
    return _post(
      transactionListPath,
      requestBuilder.transactionList(query),
      PaywayTransactionListResponse.fromJson,
      cancelToken,
    );
  }

  /// ## [refund]
  ///
  /// Refunds [amount] (full or partial) of a transaction, within 30 days of
  /// its creation. Needs [PaywayMerchant.rsaPublicKey].
  Future<PaywayRefundResponse> refund({
    required String tranId,
    required num amount,
    CancelToken? cancelToken,
  }) {
    final Map<String, String> body;
    try {
      body = requestBuilder.refund(tranId, amount);
    } on ArgumentError catch (error) {
      throw PaywayException(
        PaywayErrorType.encryption,
        'Refunds need the merchant RSA public key',
        cause: error,
      );
    } on FormatException catch (error) {
      throw PaywayException(
        PaywayErrorType.encryption,
        'Invalid merchant RSA public key',
        cause: error,
      );
    }
    return _post(refundPath, body, PaywayRefundResponse.fromJson, cancelToken);
  }

  /// ## [getExchangeRates]
  ///
  /// ABA Bank's latest exchange rates, in riel per unit of each currency.
  Future<PaywayExchangeRateResponse> getExchangeRates({
    CancelToken? cancelToken,
  }) {
    return _post(
      exchangeRatePath,
      requestBuilder.exchangeRate(),
      PaywayExchangeRateResponse.fromJson,
      cancelToken,
    );
  }

  /// ## [verifyCallback]
  ///
  /// Whether [body], the JSON PayWay POSTed to your `return_url`, is signed
  /// with [signature] (the `X-PayWay-HMAC-SHA512` header). [key] defaults to
  /// the merchant API key.
  bool verifyCallback({
    required String body,
    required String signature,
    String? key,
  }) {
    final Object? decoded;
    try {
      decoded = json.decode(body);
    } on FormatException {
      return false;
    }
    if (decoded is! Map<String, dynamic>) return false;
    final expected = crypto.hmacSha512Base64(
      PaywayCrypto.callbackSigningString(decoded),
      key ?? merchant.apiKey,
    );
    return _constantTimeEquals(expected, signature.trim());
  }

  /// ## [parseCallback]
  ///
  /// Parses a callback body; call [verifyCallback] first.
  PaywayCallback parseCallback(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return PaywayCallback.fromJson(decoded);
      }
    } on FormatException catch (error) {
      throw PaywayException(
        PaywayErrorType.invalidCallback,
        'Callback body is not JSON',
        cause: error,
      );
    }
    throw const PaywayException(
      PaywayErrorType.invalidCallback,
      'Callback body is not a JSON object',
    );
  }

  /// POST [body] (form data or JSON) and parse PayWay's reply. PayWay
  /// answers errors with a JSON body carrying the real status, possibly
  /// with a non-2xx HTTP status, which is parsed like a success.
  Future<T> _post<T>(
    String path,
    Object body,
    T Function(Map<String, dynamic> json) parse,
    CancelToken? cancelToken,
  ) async {
    final uri = _uri(path);
    final isForm = body is FormData;
    _logger?.call(
      '[PayWay] POST $uri '
      '${isForm ? Map.fromEntries(body.fields) : json.encode(body)}',
    );

    Response<String> response;
    try {
      response = await _dio.postUri<String>(
        uri,
        data: isForm ? body : json.encode(body),
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (!isForm) 'Content-Type': 'application/json',
            if (!_kIsWeb) 'User-Agent': 'dart-payway/$sdkVersion',
            if (!_kIsWeb && merchant.referer.isNotEmpty)
              'Referer': merchant.referer,
          },
          responseType: ResponseType.plain,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      final errorBody = error.response?.data;
      _logger?.call(
        '[PayWay] ${error.response?.statusCode ?? error.type.name} '
        '${errorBody ?? error.message}',
      );
      final map = _statusBody(errorBody);
      if (map != null) return parse(map);
      final (type, message) = _describe(error);
      throw PaywayException(
        type,
        message,
        statusCode: error.response?.statusCode,
        cause: error,
      );
    }

    _logger?.call('[PayWay] ${response.statusCode} ${response.data}');
    final map = _statusBody(response.data);
    if (map != null) return parse(map);
    throw PaywayException(
      PaywayErrorType.unexpectedResponse,
      'Unexpected response from PayWay',
      statusCode: response.statusCode,
    );
  }

  Uri _uri(String path) => Uri.parse(merchant.baseApiUrl).resolve(path);

  /// decode [body] when it holds a PayWay `status`, at the top level or
  /// inside `data`, which is lifted to the top
  static Map<String, dynamic>? _statusBody(Object? body) {
    if (body is! String || body.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = json.decode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['status'] is Map) return decoded;
    final data = decoded['data'];
    if (data is Map<String, dynamic> && data['status'] is Map) {
      return {...decoded, 'status': data['status']};
    }
    return null;
  }

  static (PaywayErrorType, String) _describe(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => (
        PaywayErrorType.timeout,
        'Timeout with PayWay',
      ),
      DioExceptionType.badCertificate => (
        PaywayErrorType.badCertificate,
        'Bad certificate from PayWay',
      ),
      DioExceptionType.badResponse => (
        PaywayErrorType.unexpectedResponse,
        'Unexpected response from PayWay',
      ),
      DioExceptionType.cancel => (
        PaywayErrorType.cancelled,
        'Request to PayWay was cancelled',
      ),
      DioExceptionType.connectionError => (
        PaywayErrorType.connection,
        'Could not connect to PayWay',
      ),
      // unknown, and any type a newer dio adds
      _ => (
        PaywayErrorType.unknown,
        'Request to PayWay failed: ${error.message ?? error.error}',
      ),
    };
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

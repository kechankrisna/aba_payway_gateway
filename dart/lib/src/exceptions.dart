/// What went wrong in a [PaywayException].
enum PaywayErrorType {
  /// PayWay could not be reached (DNS, refused connection, offline, ...)
  connection,

  /// connecting, sending or receiving took longer than the configured timeout
  timeout,

  /// the call was cancelled with its `CancelToken`
  cancelled,

  /// PayWay's TLS certificate was rejected
  badCertificate,

  /// PayWay answered without a PayWay `status` (e.g. an HTML page)
  unexpectedResponse,

  /// the refund payload could not be encrypted, e.g. a missing or invalid
  /// merchant RSA public key
  encryption,

  /// a callback body is not the JSON object PayWay sends
  invalidCallback,

  /// any other failure; see [PaywayException.cause]
  unknown,
}

/// Thrown when PayWay could not be reached or did not answer with a PayWay
/// status, and for invalid local input such as a missing RSA key.
///
/// PayWay business errors (wrong hash, transaction not found, ...) are not
/// thrown: they are returned in the response `status`.
class PaywayException implements Exception {
  /// what went wrong
  final PaywayErrorType type;

  /// human readable description, for logs
  final String message;

  /// HTTP status code, when a response was received
  final int? statusCode;

  /// the underlying error, e.g. a `DioException`
  final Object? cause;

  /// Creates an exception of [type] described by [message].
  const PaywayException(this.type, this.message, {this.statusCode, this.cause});

  /// whether retrying the same call later may succeed
  bool get isRetryable =>
      type == PaywayErrorType.connection ||
      type == PaywayErrorType.timeout ||
      (type == PaywayErrorType.unexpectedResponse && (statusCode ?? 0) >= 500);

  @override
  String toString() => statusCode == null
      ? 'PaywayException(${type.name}): $message'
      : 'PaywayException(${type.name}): $message (HTTP $statusCode)';
}

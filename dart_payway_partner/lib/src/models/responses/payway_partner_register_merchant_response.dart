// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PaywayPartnerRegisterMerchantResponse {
  final String url;
  final String token;
  final PaywayPartnerRegisterMerchantResponseStatus status;
  PaywayPartnerRegisterMerchantResponse({
    required this.url,
    required this.token,
    required this.status,
  });

  PaywayPartnerRegisterMerchantResponse copyWith({
    String? url,
    String? token,
    PaywayPartnerRegisterMerchantResponseStatus? status,
  }) {
    return PaywayPartnerRegisterMerchantResponse(
      url: url ?? this.url,
      token: token ?? this.token,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'url': url,
      'token': token,
      'status': status.toMap(),
    };
  }

  factory PaywayPartnerRegisterMerchantResponse.fromMap(
      Map<String, dynamic> map) {
    return PaywayPartnerRegisterMerchantResponse(
      url: map['url'] as String,
      token: map['token'] as String,
      status: PaywayPartnerRegisterMerchantResponseStatus.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartnerRegisterMerchantResponse.fromJson(String source) =>
      PaywayPartnerRegisterMerchantResponse.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'PaywayPartnerRegisterMerchantResponse(url: $url, token: $token, status: $status)';

  @override
  bool operator ==(covariant PaywayPartnerRegisterMerchantResponse other) {
    if (identical(this, other)) return true;

    return other.url == url && other.token == token && other.status == status;
  }

  @override
  int get hashCode => url.hashCode ^ token.hashCode ^ status.hashCode;
}

class PaywayPartnerRegisterMerchantResponseStatus {
  final String code;
  final String message;
  final String? trace_id;
  final String? correlation_id;
  PaywayPartnerRegisterMerchantResponseStatus({
    required this.code,
    required this.message,
    this.trace_id,
    this.correlation_id,
  });

  PaywayPartnerRegisterMerchantResponseStatus copyWith({
    String? code,
    String? message,
    String? trace_id,
    String? correlation_id,
  }) {
    return PaywayPartnerRegisterMerchantResponseStatus(
      code: code ?? this.code,
      message: message ?? this.message,
      trace_id: trace_id ?? this.trace_id,
      correlation_id: correlation_id ?? this.correlation_id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'message': message,
      'trace_id': trace_id,
      'correlation_id': correlation_id,
    };
  }

  factory PaywayPartnerRegisterMerchantResponseStatus.fromMap(
      Map<String, dynamic> map) {
    return PaywayPartnerRegisterMerchantResponseStatus(
      code: map['code'] as String,
      message: map['message'] as String,
      trace_id: map['trace_id'] != null ? map['trace_id'] as String : null,
      correlation_id: map['correlation_id'] != null
          ? map['correlation_id'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartnerRegisterMerchantResponseStatus.fromJson(String source) =>
      PaywayPartnerRegisterMerchantResponseStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'PaywayPartnerRegisterMerchantResponseStatus(code: $code, message: $message, trace_id: $trace_id, correlation_id: $correlation_id)';

  @override
  bool operator ==(
      covariant PaywayPartnerRegisterMerchantResponseStatus other) {
    if (identical(this, other)) return true;

    return other.code == code &&
        other.message == message &&
        other.trace_id == trace_id &&
        other.correlation_id == correlation_id;
  }

  @override
  int get hashCode =>
      code.hashCode ^
      message.hashCode ^
      trace_id.hashCode ^
      correlation_id.hashCode;
}

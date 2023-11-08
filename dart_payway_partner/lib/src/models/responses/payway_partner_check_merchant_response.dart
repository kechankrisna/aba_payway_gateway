// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PaywayPartnerCheckMerchantResponse {
  final String data;
  final PaywayPartnerCheckMerchantResponseStatus status;

  ///
  /// `data`: will be need to decode from base64 string to get
  /// We will response below fields as
  /// encryption text:
  /// - partner_name
  /// - merchant_name
  /// - mid
  /// - merchant_key
  /// - public_key
  /// - register_ref
  /// - currency
  /// - rsa_public_key
  ///
  /// `status`: will be json format like
  /// 
  /// Code:00, msg: success
  /// 
  /// Code:PTL02, msg: wrong hash
  /// 
  /// Code:PTL06, msg: The Request is Expired
  PaywayPartnerCheckMerchantResponse({
    required this.data,
    required this.status,
  });

  PaywayPartnerCheckMerchantResponse copyWith({
    String? data,
    PaywayPartnerCheckMerchantResponseStatus? status,
  }) {
    return PaywayPartnerCheckMerchantResponse(
      data: data ?? this.data,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'data': data,
      'status': status.toMap(),
    };
  }

  factory PaywayPartnerCheckMerchantResponse.fromMap(Map<String, dynamic> map) {
    return PaywayPartnerCheckMerchantResponse(
      data: map['data'] as String,
      status: PaywayPartnerCheckMerchantResponseStatus.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartnerCheckMerchantResponse.fromJson(String source) =>
      PaywayPartnerCheckMerchantResponse.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'PaywayPartnerCheckMerchantResponse(data: $data, status: $status)';

  @override
  bool operator ==(covariant PaywayPartnerCheckMerchantResponse other) {
    if (identical(this, other)) return true;

    return other.data == data && other.status == status;
  }

  @override
  int get hashCode => data.hashCode ^ status.hashCode;
}

class PaywayPartnerCheckMerchantResponseStatus {
  final String code;
  final String message;
  final String? tran_id;
  PaywayPartnerCheckMerchantResponseStatus({
    required this.code,
    required this.message,
    this.tran_id,
  });

  PaywayPartnerCheckMerchantResponseStatus copyWith({
    String? code,
    String? message,
    String? tran_id,
  }) {
    return PaywayPartnerCheckMerchantResponseStatus(
      code: code ?? this.code,
      message: message ?? this.message,
      tran_id: tran_id ?? this.tran_id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'message': message,
      'tran_id': tran_id,
    };
  }

  factory PaywayPartnerCheckMerchantResponseStatus.fromMap(
      Map<String, dynamic> map) {
    return PaywayPartnerCheckMerchantResponseStatus(
      code: map['code'] as String,
      message: map['message'] as String,
      tran_id: map['tran_id'] != null ? map['tran_id'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartnerCheckMerchantResponseStatus.fromJson(String source) =>
      PaywayPartnerCheckMerchantResponseStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'PaywayPartnerCheckMerchantResponseStatus(code: $code, message: $message, tran_id: $tran_id)';

  @override
  bool operator ==(covariant PaywayPartnerCheckMerchantResponseStatus other) {
    if (identical(this, other)) return true;

    return other.code == code &&
        other.message == message &&
        other.tran_id == tran_id;
  }

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ tran_id.hashCode;
}

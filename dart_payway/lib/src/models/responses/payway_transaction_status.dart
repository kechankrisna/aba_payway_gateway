// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PaywayTransactionStatus {
  final String code;
  final String message;
  final String tran_id;
  PaywayTransactionStatus({
    required this.code,
    required this.message,
    required this.tran_id,
  });

  factory PaywayTransactionStatus.empty() =>
      PaywayTransactionStatus(code: "", message: "Unknown Error!", tran_id: "");

  PaywayTransactionStatus copyWith({
    String? code,
    String? message,
    String? tran_id,
  }) {
    return PaywayTransactionStatus(
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

  factory PaywayTransactionStatus.fromMap(Map<String, dynamic> map) {
    return PaywayTransactionStatus(
      code: map['code'] as String,
      message: map['message'] as String,
      tran_id: map['tran_id'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayTransactionStatus.fromJson(String source) =>
      PaywayTransactionStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'PaywayTransactionStatus(code: $code, message: $message, tran_id: $tran_id)';

  @override
  bool operator ==(covariant PaywayTransactionStatus other) {
    if (identical(this, other)) return true;

    return other.code == code &&
        other.message == message &&
        other.tran_id == tran_id;
  }

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ tran_id.hashCode;
}

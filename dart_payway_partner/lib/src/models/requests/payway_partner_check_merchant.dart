// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

class PaywayPartnerCheckMerchant {
  final String register_ref;
  PaywayPartnerCheckMerchant({
    required this.register_ref,
  });
  

  PaywayPartnerCheckMerchant copyWith({
    String? register_ref,
  }) {
    return PaywayPartnerCheckMerchant(
      register_ref: register_ref ?? this.register_ref,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'register_ref': register_ref,
    };
  }

  factory PaywayPartnerCheckMerchant.fromMap(Map<String, dynamic> map) {
    return PaywayPartnerCheckMerchant(
      register_ref: map['register_ref'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartnerCheckMerchant.fromJson(String source) => PaywayPartnerCheckMerchant.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PaywayPartnerCheckMerchant(register_ref: $register_ref)';

  @override
  bool operator ==(covariant PaywayPartnerCheckMerchant other) {
    if (identical(this, other)) return true;
  
    return 
      other.register_ref == register_ref;
  }

  @override
  int get hashCode => register_ref.hashCode;
}

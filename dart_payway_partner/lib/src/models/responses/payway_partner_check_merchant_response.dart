// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PaywayPartnerCheckMerchantResponse {
  final String partner_name;
  final String merchant_name;
  final String mid;
  final String merchant_key;
  final String public_key;
  final String register_ref;
  final String currency;
  final String rsa_public_key;
  PaywayPartnerCheckMerchantResponse({
    required this.partner_name,
    required this.merchant_name,
    required this.mid,
    required this.merchant_key,
    required this.public_key,
    required this.register_ref,
    required this.currency,
    required this.rsa_public_key,
  });

  PaywayPartnerCheckMerchantResponse copyWith({
    String? partner_name,
    String? merchant_name,
    String? mid,
    String? merchant_key,
    String? public_key,
    String? register_ref,
    String? currency,
    String? rsa_public_key,
  }) {
    return PaywayPartnerCheckMerchantResponse(
      partner_name: partner_name ?? this.partner_name,
      merchant_name: merchant_name ?? this.merchant_name,
      mid: mid ?? this.mid,
      merchant_key: merchant_key ?? this.merchant_key,
      public_key: public_key ?? this.public_key,
      register_ref: register_ref ?? this.register_ref,
      currency: currency ?? this.currency,
      rsa_public_key: rsa_public_key ?? this.rsa_public_key,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'partner_name': partner_name,
      'merchant_name': merchant_name,
      'mid': mid,
      'merchant_key': merchant_key,
      'public_key': public_key,
      'register_ref': register_ref,
      'currency': currency,
      'rsa_public_key': rsa_public_key,
    };
  }

  factory PaywayPartnerCheckMerchantResponse.fromMap(Map<String, dynamic> map) {
    return PaywayPartnerCheckMerchantResponse(
      partner_name: map['partner_name'] as String,
      merchant_name: map['merchant_name'] as String,
      mid: map['mid'] as String,
      merchant_key: map['merchant_key'] as String,
      public_key: map['public_key'] as String,
      register_ref: map['register_ref'] as String,
      currency: map['currency'] as String,
      rsa_public_key: map['rsa_public_key'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartnerCheckMerchantResponse.fromJson(String source) => PaywayPartnerCheckMerchantResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaywayPartnerCheckMerchantResponse(partner_name: $partner_name, merchant_name: $merchant_name, mid: $mid, merchant_key: $merchant_key, public_key: $public_key, register_ref: $register_ref, currency: $currency, rsa_public_key: $rsa_public_key)';
  }

  @override
  bool operator ==(covariant PaywayPartnerCheckMerchantResponse other) {
    if (identical(this, other)) return true;
  
    return 
      other.partner_name == partner_name &&
      other.merchant_name == merchant_name &&
      other.mid == mid &&
      other.merchant_key == merchant_key &&
      other.public_key == public_key &&
      other.register_ref == register_ref &&
      other.currency == currency &&
      other.rsa_public_key == rsa_public_key;
  }

  @override
  int get hashCode {
    return partner_name.hashCode ^
      merchant_name.hashCode ^
      mid.hashCode ^
      merchant_key.hashCode ^
      public_key.hashCode ^
      register_ref.hashCode ^
      currency.hashCode ^
      rsa_public_key.hashCode;
  }
}

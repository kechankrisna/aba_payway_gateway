// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PaywayMerchant {
  /// [internal]
  /// provided by api
  final String merchantID;
  final String merchantApiKey;
  final String merchantApiName;
  final String baseApiUrl;
  final String refererDomain;

  /// ## [PaywayMerchant]
  /// `Represent and Hold Merchant Credential provided by aba bank supporter`
  /// ### [Example]
  /// ```
  ///var merchant = PaywayMerchant(
  ///   merchantID: "your_merchant_api",
  ///   merchantApiKey: "your_api_key",
  ///   merchantApiName: "your_merchant_name",
  ///   baseApiUrl: "based_api_url", // without merchantApiName
  ///   referedDomain: "", // whitelist domain
  /// );
  /// ```
  ///
  PaywayMerchant({
    required this.merchantID,
    required this.merchantApiKey,
    required this.merchantApiName,
    required this.baseApiUrl,
    required this.refererDomain,
  });

  PaywayMerchant copyWith({
    String? merchantID,
    String? merchantApiKey,
    String? merchantApiName,
    String? baseApiUrl,
    String? refererDomain,
  }) {
    return PaywayMerchant(
      merchantID: merchantID ?? this.merchantID,
      merchantApiKey: merchantApiKey ?? this.merchantApiKey,
      merchantApiName: merchantApiName ?? this.merchantApiName,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
      refererDomain: refererDomain ?? this.refererDomain,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'merchantID': merchantID,
      'merchantApiKey': merchantApiKey,
      'merchantApiName': merchantApiName,
      'baseApiUrl': baseApiUrl,
      'refererDomain': refererDomain,
    };
  }

  factory PaywayMerchant.fromMap(Map<String, dynamic> map) {
    return PaywayMerchant(
      merchantID: map['merchantID'] as String,
      merchantApiKey: map['merchantApiKey'] as String,
      merchantApiName: map['merchantApiName'] as String,
      baseApiUrl: map['baseApiUrl'] as String,
      refererDomain: map['refererDomain'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayMerchant.fromJson(String source) =>
      PaywayMerchant.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaywayMerchant(merchantID: $merchantID, merchantApiKey: $merchantApiKey, merchantApiName: $merchantApiName, baseApiUrl: $baseApiUrl, refererDomain: $refererDomain)';
  }

  @override
  bool operator ==(covariant PaywayMerchant other) {
    if (identical(this, other)) return true;

    return other.merchantID == merchantID &&
        other.merchantApiKey == merchantApiKey &&
        other.merchantApiName == merchantApiName &&
        other.baseApiUrl == baseApiUrl &&
        other.refererDomain == refererDomain;
  }

  @override
  int get hashCode {
    return merchantID.hashCode ^
        merchantApiKey.hashCode ^
        merchantApiName.hashCode ^
        baseApiUrl.hashCode ^
        refererDomain.hashCode;
  }
}

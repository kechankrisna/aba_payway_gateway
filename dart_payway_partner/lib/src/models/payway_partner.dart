// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PaywayPartner {
  final String partnerName;
  final String partnerID;
  final String partnerKey;
  final String partnerReferer;
  final String partnerPrivateKey;
  final String partnerPublicKey;
  final String baseApiUrl;

  /// ## [PaywayPartner]
  /// `Represent and Hold Merchant Credential provided by aba bank supporter`
  /// ### [Example]
  /// ```
  ///var merchant = PaywayPartner(
  ///   partnerName: "your partner name",
  ///   partnerId: "your partner id",
  ///   partnerKey: "your partner key",
  ///   partnerPrivateKey: "your partner private key",
  ///   partnerPublicKey: "your partner public key",
  ///   baseApiUrl: "based_api_url", // without merchantApiName
  /// );
  /// ```
  PaywayPartner({
    required this.partnerName,
    required this.partnerID,
    required this.partnerKey,
    required this.partnerReferer,
    required this.partnerPrivateKey,
    required this.partnerPublicKey,
    required this.baseApiUrl,
  });

  PaywayPartner copyWith({
    String? partnerName,
    String? partnerID,
    String? partnerKey,
    String? partnerReferer,
    String? partnerPrivateKey,
    String? partnerPublicKey,
    String? baseApiUrl,
  }) {
    return PaywayPartner(
      partnerName: partnerName ?? this.partnerName,
      partnerID: partnerID ?? this.partnerID,
      partnerKey: partnerKey ?? this.partnerKey,
      partnerReferer: partnerReferer ?? this.partnerReferer,
      partnerPrivateKey: partnerPrivateKey ?? this.partnerPrivateKey,
      partnerPublicKey: partnerPublicKey ?? this.partnerPublicKey,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'partnerName': partnerName,
      'partnerID': partnerID,
      'partnerKey': partnerKey,
      'partnerReferer': partnerReferer,
      'partnerPrivateKey': partnerPrivateKey,
      'partnerPublicKey': partnerPublicKey,
      'baseApiUrl': baseApiUrl,
    };
  }

  factory PaywayPartner.fromMap(Map<String, dynamic> map) {
    return PaywayPartner(
      partnerName: map['partnerName'] as String,
      partnerID: map['partnerID'] as String,
      partnerKey: map['partnerKey'] as String,
      partnerReferer: map['partnerReferer'] as String,
      partnerPrivateKey: map['partnerPrivateKey'] as String,
      partnerPublicKey: map['partnerPublicKey'] as String,
      baseApiUrl: map['baseApiUrl'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartner.fromJson(String source) =>
      PaywayPartner.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaywayPartner(partnerName: $partnerName, partnerID: $partnerID, partnerKey: $partnerKey, partnerReferer: $partnerReferer, partnerPrivateKey: $partnerPrivateKey, partnerPublicKey: $partnerPublicKey, baseApiUrl: $baseApiUrl)';
  }

  @override
  bool operator ==(covariant PaywayPartner other) {
    if (identical(this, other)) return true;

    return other.partnerName == partnerName &&
        other.partnerID == partnerID &&
        other.partnerKey == partnerKey &&
        other.partnerReferer == partnerReferer &&
        other.partnerPrivateKey == partnerPrivateKey &&
        other.partnerPublicKey == partnerPublicKey &&
        other.baseApiUrl == baseApiUrl;
  }

  @override
  int get hashCode {
    return partnerName.hashCode ^
        partnerID.hashCode ^
        partnerKey.hashCode ^
        partnerReferer.hashCode ^
        partnerPrivateKey.hashCode ^
        partnerPublicKey.hashCode ^
        baseApiUrl.hashCode;
  }
}

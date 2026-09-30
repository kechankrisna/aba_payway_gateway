import 'package:json_annotation/json_annotation.dart';

part 'payway_merchant.g.dart';

/// Merchant credentials provided by ABA Bank.
///
/// ```dart
/// final merchant = PaywayMerchant(
///   merchantId: 'your merchant id',
///   apiKey: 'your API key (public_key)',
///   rsaPublicKey: '-----BEGIN PUBLIC KEY-----...', // only for refunds
///   referer: 'https://your-whitelisted-domain.com',
///   baseApiUrl: PaywayMerchant.sandboxBaseUrl,
/// );
/// ```
///
/// [fromJson] / [toJson] use the field names as keys, for loading this
/// configuration from your own secret store. [toJson] contains the secrets.
@JsonSerializable()
class PaywayMerchant {
  /// PayWay checkout sandbox (testing) environment
  static const String sandboxBaseUrl = 'https://checkout-sandbox.payway.com.kh';

  /// PayWay checkout production (live) environment
  static const String productionBaseUrl = 'https://checkout.payway.com.kh';

  /// merchant id provided by ABA (`merchant_id`)
  final String merchantId;

  /// API key provided by ABA, keys every request hash (secret)
  final String apiKey;

  /// RSA public key provided by ABA, PEM or bare base64; needed for refunds
  final String? rsaPublicKey;

  /// domain whitelisted by ABA, sent as the `Referer` header
  final String referer;

  /// [sandboxBaseUrl] or [productionBaseUrl]
  final String baseApiUrl;

  /// Creates a [PaywayMerchant].
  const PaywayMerchant({
    required this.merchantId,
    required this.apiKey,
    required this.referer,
    this.rsaPublicKey,
    this.baseApiUrl = PaywayMerchant.sandboxBaseUrl,
  });

  /// Reads a configuration written by [toJson].
  factory PaywayMerchant.fromJson(Map<String, dynamic> json) =>
      _$PaywayMerchantFromJson(json);

  /// JSON keyed by field name; contains the secrets.
  Map<String, dynamic> toJson() => _$PaywayMerchantToJson(this);

  /// Returns a copy with the given fields replaced.
  PaywayMerchant copyWith({
    String? merchantId,
    String? apiKey,
    String? rsaPublicKey,
    String? referer,
    String? baseApiUrl,
  }) {
    return PaywayMerchant(
      merchantId: merchantId ?? this.merchantId,
      apiKey: apiKey ?? this.apiKey,
      rsaPublicKey: rsaPublicKey ?? this.rsaPublicKey,
      referer: referer ?? this.referer,
      baseApiUrl: baseApiUrl ?? this.baseApiUrl,
    );
  }

  /// the API key is a secret, keep it out of logs
  @override
  String toString() =>
      'PaywayMerchant(merchantId: $merchantId, apiKey: ***, referer: $referer, baseApiUrl: $baseApiUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaywayMerchant &&
          other.merchantId == merchantId &&
          other.apiKey == apiKey &&
          other.rsaPublicKey == rsaPublicKey &&
          other.referer == referer &&
          other.baseApiUrl == baseApiUrl;

  @override
  int get hashCode =>
      Object.hash(merchantId, apiKey, rsaPublicKey, referer, baseApiUrl);
}

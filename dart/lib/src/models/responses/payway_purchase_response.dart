import 'package:json_annotation/json_annotation.dart';

import '../json_converters.dart';
import 'payway_status.dart';

part 'payway_purchase_response.g.dart';

/// Reads [keys] in order and returns the first value present. PayWay's
/// production and sandbox spell some purchase fields differently.
Object? Function(Map<dynamic, dynamic>, String) _firstOf(List<String> keys) =>
    (json, _) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    };

/// JSON response of `purchase` with `abapay_khqr_deeplink`.
///
/// Production and the sandbox differ: production sends `qrString`,
/// `qrImage`, `app_store` and `play_store`; the sandbox (and the docs) send
/// `qr_string` and `checkout_qr_url`. Both are read.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PaywayPurchaseResponse {
  /// PayWay's `status` object
  final PaywayStatus status;

  /// KHQR payload to render as a QR code
  @JsonKey(readValue: _readQrString, fromJson: nullableStringFromJson)
  final String? qrString;

  /// the KHQR as a PNG `data:` URI (production)
  @JsonKey(readValue: _readQrImage, fromJson: nullableStringFromJson)
  final String? qrImage;

  /// deep link opening ABA Mobile
  @JsonKey(readValue: _readDeeplink, fromJson: nullableStringFromJson)
  final String? abapayDeeplink;

  /// hosted page showing the QR code (sandbox)
  @JsonKey(readValue: _readCheckoutQrUrl, fromJson: nullableStringFromJson)
  final String? checkoutQrUrl;

  /// App Store link of ABA Mobile (production)
  @JsonKey(fromJson: nullableStringFromJson)
  final String? appStore;

  /// Google Play link of ABA Mobile (production)
  @JsonKey(fromJson: nullableStringFromJson)
  final String? playStore;

  /// Creates a [PaywayPurchaseResponse].
  const PaywayPurchaseResponse({
    required this.status,
    this.qrString,
    this.qrImage,
    this.abapayDeeplink,
    this.checkoutQrUrl,
    this.appStore,
    this.playStore,
  });

  /// Whether PayWay accepted the purchase.
  bool get isSuccess => status.isSuccess;

  /// Parses PayWay JSON.
  factory PaywayPurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$PaywayPurchaseResponseFromJson(json);

  /// JSON with PayWay's documented (snake_case) field names.
  Map<String, dynamic> toJson() => _$PaywayPurchaseResponseToJson(this);

  @override
  String toString() =>
      'PaywayPurchaseResponse(status: $status, abapayDeeplink: $abapayDeeplink, checkoutQrUrl: $checkoutQrUrl)';
}

Object? _readQrString(Map<dynamic, dynamic> json, String key) =>
    _firstOf(const ['qr_string', 'qrString'])(json, key);

Object? _readQrImage(Map<dynamic, dynamic> json, String key) =>
    _firstOf(const ['qr_image', 'qrImage'])(json, key);

Object? _readDeeplink(Map<dynamic, dynamic> json, String key) =>
    _firstOf(const ['abapay_deeplink', 'abapayDeeplink'])(json, key);

Object? _readCheckoutQrUrl(Map<dynamic, dynamic> json, String key) =>
    _firstOf(const ['checkout_qr_url', 'checkoutQrUrl'])(json, key);

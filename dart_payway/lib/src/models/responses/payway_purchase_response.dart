import 'package:json_annotation/json_annotation.dart';

import '../json_converters.dart';
import 'payway_status.dart';

part 'payway_purchase_response.g.dart';

/// JSON response of `purchase` with `abapay_khqr_deeplink`.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PaywayPurchaseResponse {
  /// PayWay's `status` object
  final PaywayStatus status;

  /// KHQR payload to render as a QR code
  @JsonKey(fromJson: nullableStringFromJson)
  final String? qrString;

  /// deep link opening ABA Mobile
  @JsonKey(fromJson: nullableStringFromJson)
  final String? abapayDeeplink;

  /// hosted page showing the QR code
  @JsonKey(fromJson: nullableStringFromJson)
  final String? checkoutQrUrl;

  /// Creates a [PaywayPurchaseResponse].
  const PaywayPurchaseResponse({
    required this.status,
    this.qrString,
    this.abapayDeeplink,
    this.checkoutQrUrl,
  });

  /// Whether PayWay accepted the purchase.
  bool get isSuccess => status.isSuccess;

  /// Parses PayWay JSON.
  factory PaywayPurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$PaywayPurchaseResponseFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayPurchaseResponseToJson(this);

  @override
  String toString() =>
      'PaywayPurchaseResponse(status: $status, abapayDeeplink: $abapayDeeplink, checkoutQrUrl: $checkoutQrUrl)';
}

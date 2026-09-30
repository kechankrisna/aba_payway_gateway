// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_purchase_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayPurchaseResponse _$PaywayPurchaseResponseFromJson(
  Map<String, dynamic> json,
) => PaywayPurchaseResponse(
  status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
  qrString: nullableStringFromJson(json['qr_string']),
  abapayDeeplink: nullableStringFromJson(json['abapay_deeplink']),
  checkoutQrUrl: nullableStringFromJson(json['checkout_qr_url']),
);

Map<String, dynamic> _$PaywayPurchaseResponseToJson(
  PaywayPurchaseResponse instance,
) => <String, dynamic>{
  'status': instance.status.toJson(),
  'qr_string': instance.qrString,
  'abapay_deeplink': instance.abapayDeeplink,
  'checkout_qr_url': instance.checkoutQrUrl,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_purchase_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayPurchaseResponse _$PaywayPurchaseResponseFromJson(
  Map<String, dynamic> json,
) => PaywayPurchaseResponse(
  status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
  qrString: nullableStringFromJson(_readQrString(json, 'qr_string')),
  qrImage: nullableStringFromJson(_readQrImage(json, 'qr_image')),
  abapayDeeplink: nullableStringFromJson(
    _readDeeplink(json, 'abapay_deeplink'),
  ),
  checkoutQrUrl: nullableStringFromJson(
    _readCheckoutQrUrl(json, 'checkout_qr_url'),
  ),
  appStore: nullableStringFromJson(json['app_store']),
  playStore: nullableStringFromJson(json['play_store']),
);

Map<String, dynamic> _$PaywayPurchaseResponseToJson(
  PaywayPurchaseResponse instance,
) => <String, dynamic>{
  'status': instance.status.toJson(),
  'qr_string': instance.qrString,
  'qr_image': instance.qrImage,
  'abapay_deeplink': instance.abapayDeeplink,
  'checkout_qr_url': instance.checkoutQrUrl,
  'app_store': instance.appStore,
  'play_store': instance.playStore,
};

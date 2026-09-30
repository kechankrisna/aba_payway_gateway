// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_merchant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayMerchant _$PaywayMerchantFromJson(Map<String, dynamic> json) =>
    PaywayMerchant(
      merchantId: json['merchantId'] as String,
      apiKey: json['apiKey'] as String,
      referer: json['referer'] as String,
      rsaPublicKey: json['rsaPublicKey'] as String?,
      baseApiUrl:
          json['baseApiUrl'] as String? ?? PaywayMerchant.sandboxBaseUrl,
    );

Map<String, dynamic> _$PaywayMerchantToJson(PaywayMerchant instance) =>
    <String, dynamic>{
      'merchantId': instance.merchantId,
      'apiKey': instance.apiKey,
      'rsaPublicKey': instance.rsaPublicKey,
      'referer': instance.referer,
      'baseApiUrl': instance.baseApiUrl,
    };

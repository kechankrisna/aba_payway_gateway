// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayStatus _$PaywayStatusFromJson(Map<String, dynamic> json) => PaywayStatus(
  code: stringFromJson(json['code']),
  message: stringFromJson(json['message']),
  tranId: nullableStringFromJson(json['tran_id']),
  traceId: nullableStringFromJson(json['trace_id']),
);

Map<String, dynamic> _$PaywayStatusToJson(PaywayStatus instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'tran_id': ?instance.tranId,
      'trace_id': ?instance.traceId,
    };

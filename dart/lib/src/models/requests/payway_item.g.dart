// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayItem _$PaywayItemFromJson(Map<String, dynamic> json) => PaywayItem(
  name: json['name'] as String,
  quantity: json['quantity'] as num,
  price: json['price'] as num,
);

Map<String, dynamic> _$PaywayItemToJson(PaywayItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'price': instance.price,
    };

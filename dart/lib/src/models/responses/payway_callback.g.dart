// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_callback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayCallback _$PaywayCallbackFromJson(Map<String, dynamic> json) =>
    PaywayCallback(
      tranId: stringFromJson(json['tran_id']),
      apv: stringFromJson(json['apv']),
      status: stringFromJson(json['status']),
      returnParams: stringFromJson(json['return_params']),
      originalAmount: doubleFromJson(json['original_amount']),
      originalCurrency: stringFromJson(json['original_currency']),
      paymentAmount: doubleFromJson(json['payment_amount']),
      paymentCurrency: stringFromJson(json['payment_currency']),
      totalAmount: doubleFromJson(json['total_amount']),
      discountAmount: doubleFromJson(json['discount_amount']),
      transactionDate: stringFromJson(json['transaction_date']),
      firstName: stringFromJson(json['first_name']),
      lastName: stringFromJson(json['last_name']),
      email: stringFromJson(json['email']),
      phone: stringFromJson(json['phone']),
      bankRef: stringFromJson(json['bank_ref']),
      paymentType: stringFromJson(json['payment_type']),
      payerAccount: stringFromJson(json['payer_account']),
      bankName: stringFromJson(json['bank_name']),
      cardSource: stringFromJson(json['card_source']),
    );

Map<String, dynamic> _$PaywayCallbackToJson(PaywayCallback instance) =>
    <String, dynamic>{
      'tran_id': instance.tranId,
      'apv': instance.apv,
      'status': instance.status,
      'return_params': instance.returnParams,
      'original_amount': instance.originalAmount,
      'original_currency': instance.originalCurrency,
      'payment_amount': instance.paymentAmount,
      'payment_currency': instance.paymentCurrency,
      'total_amount': instance.totalAmount,
      'discount_amount': instance.discountAmount,
      'transaction_date': instance.transactionDate,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'bank_ref': instance.bankRef,
      'payment_type': instance.paymentType,
      'payer_account': instance.payerAccount,
      'bank_name': instance.bankName,
      'card_source': instance.cardSource,
    };

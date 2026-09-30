// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayTransactionOperation _$PaywayTransactionOperationFromJson(
  Map<String, dynamic> json,
) => PaywayTransactionOperation(
  status: stringFromJson(json['status']),
  amount: doubleFromJson(json['amount']),
  transactionDate: stringFromJson(json['transaction_date']),
  bankRef: stringFromJson(json['bank_ref']),
);

Map<String, dynamic> _$PaywayTransactionOperationToJson(
  PaywayTransactionOperation instance,
) => <String, dynamic>{
  'status': instance.status,
  'amount': instance.amount,
  'transaction_date': instance.transactionDate,
  'bank_ref': instance.bankRef,
};

PaywayTransaction _$PaywayTransactionFromJson(Map<String, dynamic> json) =>
    PaywayTransaction(
      transactionId: stringFromJson(json['transaction_id']),
      paymentStatusCode: nullableIntFromJson(json['payment_status_code']),
      paymentStatus: stringFromJson(json['payment_status']),
      originalAmount: doubleFromJson(json['original_amount']),
      originalCurrency: stringFromJson(json['original_currency']),
      paymentAmount: doubleFromJson(json['payment_amount']),
      paymentCurrency: stringFromJson(json['payment_currency']),
      totalAmount: doubleFromJson(json['total_amount']),
      refundAmount: doubleFromJson(json['refund_amount']),
      discountAmount: doubleFromJson(json['discount_amount']),
      apv: stringFromJson(json['apv']),
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
      transactionOperations:
          (json['transaction_operations'] as List<dynamic>?)
              ?.map(
                (e) => PaywayTransactionOperation.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$PaywayTransactionToJson(PaywayTransaction instance) =>
    <String, dynamic>{
      'transaction_id': instance.transactionId,
      'payment_status_code': instance.paymentStatusCode,
      'payment_status': instance.paymentStatus,
      'original_amount': instance.originalAmount,
      'original_currency': instance.originalCurrency,
      'payment_amount': instance.paymentAmount,
      'payment_currency': instance.paymentCurrency,
      'total_amount': instance.totalAmount,
      'refund_amount': instance.refundAmount,
      'discount_amount': instance.discountAmount,
      'apv': instance.apv,
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
      'transaction_operations': instance.transactionOperations
          .map((e) => e.toJson())
          .toList(),
    };

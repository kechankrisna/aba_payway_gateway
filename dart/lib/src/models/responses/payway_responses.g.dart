// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payway_responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaywayTransactionStatus _$PaywayTransactionStatusFromJson(
  Map<String, dynamic> json,
) => PaywayTransactionStatus(
  paymentStatusCode: nullableIntFromJson(json['payment_status_code']),
  paymentStatus: stringFromJson(json['payment_status']),
  totalAmount: doubleFromJson(json['total_amount']),
  originalAmount: doubleFromJson(json['original_amount']),
  refundAmount: doubleFromJson(json['refund_amount']),
  discountAmount: doubleFromJson(json['discount_amount']),
  paymentAmount: doubleFromJson(json['payment_amount']),
  paymentCurrency: stringFromJson(json['payment_currency']),
  apv: stringFromJson(json['apv']),
  transactionDate: stringFromJson(json['transaction_date']),
);

Map<String, dynamic> _$PaywayTransactionStatusToJson(
  PaywayTransactionStatus instance,
) => <String, dynamic>{
  'payment_status_code': instance.paymentStatusCode,
  'payment_status': instance.paymentStatus,
  'total_amount': instance.totalAmount,
  'original_amount': instance.originalAmount,
  'refund_amount': instance.refundAmount,
  'discount_amount': instance.discountAmount,
  'payment_amount': instance.paymentAmount,
  'payment_currency': instance.paymentCurrency,
  'apv': instance.apv,
  'transaction_date': instance.transactionDate,
};

PaywayCheckTransactionResponse _$PaywayCheckTransactionResponseFromJson(
  Map<String, dynamic> json,
) => PaywayCheckTransactionResponse(
  status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
  data: json['data'] == null
      ? null
      : PaywayTransactionStatus.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaywayCheckTransactionResponseToJson(
  PaywayCheckTransactionResponse instance,
) => <String, dynamic>{
  'status': instance.status.toJson(),
  'data': ?instance.data?.toJson(),
};

PaywayTransactionDetailResponse _$PaywayTransactionDetailResponseFromJson(
  Map<String, dynamic> json,
) => PaywayTransactionDetailResponse(
  status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
  data: json['data'] == null
      ? null
      : PaywayTransaction.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaywayTransactionDetailResponseToJson(
  PaywayTransactionDetailResponse instance,
) => <String, dynamic>{
  'status': instance.status.toJson(),
  'data': ?instance.data?.toJson(),
};

PaywayTransactionListResponse _$PaywayTransactionListResponseFromJson(
  Map<String, dynamic> json,
) => PaywayTransactionListResponse(
  status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => PaywayTransaction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  page: nullableIntFromJson(json['page']),
  pagination: nullableIntFromJson(json['pagination']),
);

Map<String, dynamic> _$PaywayTransactionListResponseToJson(
  PaywayTransactionListResponse instance,
) => <String, dynamic>{
  'status': instance.status.toJson(),
  'data': instance.data.map((e) => e.toJson()).toList(),
  'page': instance.page,
  'pagination': instance.pagination,
};

PaywayStatusResponse _$PaywayStatusResponseFromJson(
  Map<String, dynamic> json,
) => PaywayStatusResponse(
  status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaywayStatusResponseToJson(
  PaywayStatusResponse instance,
) => <String, dynamic>{'status': instance.status.toJson()};

PaywayRefundResponse _$PaywayRefundResponseFromJson(
  Map<String, dynamic> json,
) => PaywayRefundResponse(
  status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
  grandTotal: nullableDoubleFromJson(json['grand_total']),
  totalRefunded: nullableDoubleFromJson(json['total_refunded']),
  currency: nullableStringFromJson(json['currency']),
  transactionStatus: nullableStringFromJson(json['transaction_status']),
);

Map<String, dynamic> _$PaywayRefundResponseToJson(
  PaywayRefundResponse instance,
) => <String, dynamic>{
  'status': instance.status.toJson(),
  'grand_total': instance.grandTotal,
  'total_refunded': instance.totalRefunded,
  'currency': instance.currency,
  'transaction_status': instance.transactionStatus,
};

PaywayExchangeRate _$PaywayExchangeRateFromJson(Map<String, dynamic> json) =>
    PaywayExchangeRate(
      sell: doubleFromJson(json['sell']),
      buy: doubleFromJson(json['buy']),
    );

Map<String, dynamic> _$PaywayExchangeRateToJson(PaywayExchangeRate instance) =>
    <String, dynamic>{'sell': instance.sell, 'buy': instance.buy};

import 'package:json_annotation/json_annotation.dart';

import '../json_converters.dart';
import 'payway_status.dart';
import 'payway_transaction.dart';

part 'payway_responses.g.dart';

/// Status of a transaction, from `check-transaction-2`.
@JsonSerializable(fieldRename: FieldRename.snake)
class PaywayTransactionStatus {
  /// see [PaywayPaymentStatusCode]
  @JsonKey(fromJson: nullableIntFromJson)
  final int? paymentStatusCode;

  /// `APPROVED`, `PRE-AUTH`, `PENDING`, `DECLINED`, `REFUNDED` or `CANCELLED`
  @JsonKey(fromJson: stringFromJson)
  final String paymentStatus;

  /// amount due after discount
  @JsonKey(fromJson: doubleFromJson)
  final double totalAmount;

  /// amount before discount
  @JsonKey(fromJson: doubleFromJson)
  final double originalAmount;

  /// refunded amount
  @JsonKey(fromJson: doubleFromJson)
  final double refundAmount;

  /// discount amount
  @JsonKey(fromJson: doubleFromJson)
  final double discountAmount;

  /// amount the payer paid
  @JsonKey(fromJson: doubleFromJson)
  final double paymentAmount;

  /// currency the payer paid in
  @JsonKey(fromJson: stringFromJson)
  final String paymentCurrency;

  /// approval code
  @JsonKey(fromJson: stringFromJson)
  final String apv;

  /// creation date, `YYYY-MM-DD HH:mm:ss`
  @JsonKey(fromJson: stringFromJson)
  final String transactionDate;

  /// Creates a [PaywayTransactionStatus].
  const PaywayTransactionStatus({
    required this.paymentStatusCode,
    required this.paymentStatus,
    required this.totalAmount,
    required this.originalAmount,
    required this.refundAmount,
    required this.discountAmount,
    required this.paymentAmount,
    required this.paymentCurrency,
    required this.apv,
    required this.transactionDate,
  });

  /// Whether the payment is approved (or pre-authorized).
  bool get isApproved => paymentStatusCode == 0;

  /// Parses PayWay JSON.
  factory PaywayTransactionStatus.fromJson(Map<String, dynamic> json) =>
      _$PaywayTransactionStatusFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayTransactionStatusToJson(this);
}

/// Response of `check-transaction-2`.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PaywayCheckTransactionResponse {
  /// PayWay's `status` object
  final PaywayStatus status;

  /// the transaction status, absent when the request failed
  final PaywayTransactionStatus? data;

  /// Creates a [PaywayCheckTransactionResponse].
  const PaywayCheckTransactionResponse({required this.status, this.data});

  /// Whether PayWay answered `00`.
  bool get isSuccess => status.isSuccess;

  /// Whether the payment is approved (or pre-authorized).
  bool get isPaid => isSuccess && (data?.isApproved ?? false);

  /// Parses PayWay JSON.
  factory PaywayCheckTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$PaywayCheckTransactionResponseFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayCheckTransactionResponseToJson(this);
}

/// Response of `transaction-detail`.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PaywayTransactionDetailResponse {
  /// PayWay's `status` object
  final PaywayStatus status;

  /// the transaction, absent when the request failed
  final PaywayTransaction? data;

  /// Creates a [PaywayTransactionDetailResponse].
  const PaywayTransactionDetailResponse({required this.status, this.data});

  /// Whether PayWay answered `00`.
  bool get isSuccess => status.isSuccess;

  /// Parses PayWay JSON.
  factory PaywayTransactionDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$PaywayTransactionDetailResponseFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() =>
      _$PaywayTransactionDetailResponseToJson(this);
}

/// Response of `transaction-list-2`.
@JsonSerializable(explicitToJson: true)
class PaywayTransactionListResponse {
  /// PayWay's `status` object
  final PaywayStatus status;

  /// transactions of this page
  @JsonKey(defaultValue: <PaywayTransaction>[])
  final List<PaywayTransaction> data;

  /// page number
  @JsonKey(fromJson: nullableIntFromJson)
  final int? page;

  /// records per page
  @JsonKey(fromJson: nullableIntFromJson)
  final int? pagination;

  /// Creates a [PaywayTransactionListResponse].
  const PaywayTransactionListResponse({
    required this.status,
    this.data = const [],
    this.page,
    this.pagination,
  });

  /// Whether PayWay answered `00`.
  bool get isSuccess => status.isSuccess;

  /// Parses PayWay JSON.
  factory PaywayTransactionListResponse.fromJson(Map<String, dynamic> json) =>
      _$PaywayTransactionListResponseFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayTransactionListResponseToJson(this);
}

/// Response of `close-transaction`: a status only.
@JsonSerializable(explicitToJson: true)
class PaywayStatusResponse {
  /// PayWay's `status` object
  final PaywayStatus status;

  /// Creates a [PaywayStatusResponse].
  const PaywayStatusResponse({required this.status});

  /// Whether PayWay answered `00`.
  bool get isSuccess => status.isSuccess;

  /// Parses PayWay JSON.
  factory PaywayStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$PaywayStatusResponseFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayStatusResponseToJson(this);
}

/// Response of `refund`.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PaywayRefundResponse {
  /// PayWay's `status` object; codes are `PTL…` for this API
  final PaywayStatus status;

  /// original purchase amount
  @JsonKey(fromJson: nullableDoubleFromJson)
  final double? grandTotal;

  /// total refunded so far
  @JsonKey(fromJson: nullableDoubleFromJson)
  final double? totalRefunded;

  /// currency of the amounts
  @JsonKey(fromJson: nullableStringFromJson)
  final String? currency;

  /// transaction status after the refund, e.g. `REFUNDED`
  @JsonKey(fromJson: nullableStringFromJson)
  final String? transactionStatus;

  /// Creates a [PaywayRefundResponse].
  const PaywayRefundResponse({
    required this.status,
    this.grandTotal,
    this.totalRefunded,
    this.currency,
    this.transactionStatus,
  });

  /// Whether PayWay answered `00`.
  bool get isSuccess => status.isSuccess;

  /// Parses PayWay JSON.
  factory PaywayRefundResponse.fromJson(Map<String, dynamic> json) =>
      _$PaywayRefundResponseFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayRefundResponseToJson(this);
}

/// ABA Bank's buy and sell rate of one currency, in riel per unit
/// (e.g. USD sell `4012`).
@JsonSerializable()
class PaywayExchangeRate {
  /// ABA sells the currency at this rate
  @JsonKey(fromJson: doubleFromJson)
  final double sell;

  /// ABA buys the currency at this rate
  @JsonKey(fromJson: doubleFromJson)
  final double buy;

  /// Creates a [PaywayExchangeRate].
  const PaywayExchangeRate({required this.sell, required this.buy});

  /// Parses PayWay JSON.
  factory PaywayExchangeRate.fromJson(Map<String, dynamic> json) =>
      _$PaywayExchangeRateFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayExchangeRateToJson(this);

  @override
  String toString() => 'PaywayExchangeRate(sell: $sell, buy: $buy)';
}

/// Response of `exchange-rate`: ABA Bank's latest rates in riel.
class PaywayExchangeRateResponse {
  /// PayWay's `status` object
  final PaywayStatus status;

  /// rates by lowercase currency code, e.g. `rates['usd']`, `rates['eur']`
  final Map<String, PaywayExchangeRate> rates;

  /// Creates a [PaywayExchangeRateResponse].
  const PaywayExchangeRateResponse({
    required this.status,
    this.rates = const {},
  });

  /// Whether PayWay answered `00`.
  bool get isSuccess => status.isSuccess;

  /// Parses PayWay JSON. Rates are read from `exchange_rates` and from
  /// top-level currency keys, as the documented schema shows both.
  factory PaywayExchangeRateResponse.fromJson(Map<String, dynamic> json) {
    final rates = <String, PaywayExchangeRate>{};
    void collect(Map<String, dynamic> source) {
      source.forEach((key, value) {
        if (value is Map<String, dynamic> &&
            value.containsKey('sell') &&
            value.containsKey('buy')) {
          rates[key.toLowerCase()] = PaywayExchangeRate.fromJson(value);
        }
      });
    }

    collect(json);
    final nested = json['exchange_rates'];
    if (nested is Map<String, dynamic>) collect(nested);
    return PaywayExchangeRateResponse(
      status: PaywayStatus.fromJson(json['status'] as Map<String, dynamic>),
      rates: rates,
    );
  }

  /// JSON with the rates under `exchange_rates`.
  Map<String, dynamic> toJson() => {
    'status': status.toJson(),
    'exchange_rates': rates.map((k, v) => MapEntry(k, v.toJson())),
  };
}

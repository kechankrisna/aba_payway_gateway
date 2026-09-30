import 'package:json_annotation/json_annotation.dart';

import '../json_converters.dart';

part 'payway_transaction.g.dart';

/// One operation (payment, refund, ...) of a transaction.
@JsonSerializable(fieldRename: FieldRename.snake)
class PaywayTransactionOperation {
  /// operation status, e.g. `Completed`
  @JsonKey(fromJson: stringFromJson)
  final String status;

  /// operation amount
  @JsonKey(fromJson: doubleFromJson)
  final double amount;

  /// operation date, `YYYY-MM-DD HH:mm:ss`
  @JsonKey(fromJson: stringFromJson)
  final String transactionDate;

  /// ABA core banking reference
  @JsonKey(fromJson: stringFromJson)
  final String bankRef;

  /// Creates a [PaywayTransactionOperation].
  const PaywayTransactionOperation({
    required this.status,
    required this.amount,
    required this.transactionDate,
    required this.bankRef,
  });

  /// Parses PayWay JSON.
  factory PaywayTransactionOperation.fromJson(Map<String, dynamic> json) =>
      _$PaywayTransactionOperationFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayTransactionOperationToJson(this);
}

/// A transaction, as returned by transaction details and the transaction
/// list. [transactionOperations] is only filled by transaction details.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PaywayTransaction {
  /// transaction id
  @JsonKey(fromJson: stringFromJson)
  final String transactionId;

  /// see [PaywayPaymentStatusCode]
  @JsonKey(fromJson: nullableIntFromJson)
  final int? paymentStatusCode;

  /// `APPROVED`, `PRE-AUTH`, `PENDING`, `DECLINED`, `REFUNDED` or `CANCELLED`
  @JsonKey(fromJson: stringFromJson)
  final String paymentStatus;

  /// amount before discount
  @JsonKey(fromJson: doubleFromJson)
  final double originalAmount;

  /// currency of [originalAmount]
  @JsonKey(fromJson: stringFromJson)
  final String originalCurrency;

  /// amount the payer paid
  @JsonKey(fromJson: doubleFromJson)
  final double paymentAmount;

  /// currency the payer paid in
  @JsonKey(fromJson: stringFromJson)
  final String paymentCurrency;

  /// amount due after discount
  @JsonKey(fromJson: doubleFromJson)
  final double totalAmount;

  /// refunded amount
  @JsonKey(fromJson: doubleFromJson)
  final double refundAmount;

  /// discount amount
  @JsonKey(fromJson: doubleFromJson)
  final double discountAmount;

  /// approval code
  @JsonKey(fromJson: stringFromJson)
  final String apv;

  /// creation date, `YYYY-MM-DD HH:mm:ss`
  @JsonKey(fromJson: stringFromJson)
  final String transactionDate;

  /// payer first name
  @JsonKey(fromJson: stringFromJson)
  final String firstName;

  /// payer last name
  @JsonKey(fromJson: stringFromJson)
  final String lastName;

  /// payer email
  @JsonKey(fromJson: stringFromJson)
  final String email;

  /// payer phone
  @JsonKey(fromJson: stringFromJson)
  final String phone;

  /// ABA core banking reference
  @JsonKey(fromJson: stringFromJson)
  final String bankRef;

  /// e.g. `ABA Pay`, `KHQR`, `VISA`
  @JsonKey(fromJson: stringFromJson)
  final String paymentType;

  /// masked account or card number
  @JsonKey(fromJson: stringFromJson)
  final String payerAccount;

  /// payer's bank
  @JsonKey(fromJson: stringFromJson)
  final String bankName;

  /// `ONUS`, `OFFUS_DOMESTIC` or `OFFUS_INTERNATIONAL` for cards
  @JsonKey(fromJson: stringFromJson)
  final String cardSource;

  /// payment and refund operations (transaction details only)
  @JsonKey(defaultValue: <PaywayTransactionOperation>[])
  final List<PaywayTransactionOperation> transactionOperations;

  /// Creates a [PaywayTransaction].
  const PaywayTransaction({
    required this.transactionId,
    required this.paymentStatusCode,
    required this.paymentStatus,
    required this.originalAmount,
    required this.originalCurrency,
    required this.paymentAmount,
    required this.paymentCurrency,
    required this.totalAmount,
    required this.refundAmount,
    required this.discountAmount,
    required this.apv,
    required this.transactionDate,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.bankRef,
    required this.paymentType,
    required this.payerAccount,
    required this.bankName,
    required this.cardSource,
    this.transactionOperations = const [],
  });

  /// Whether the payment is approved (or pre-authorized).
  bool get isApproved => paymentStatusCode == 0;

  /// Parses PayWay JSON.
  factory PaywayTransaction.fromJson(Map<String, dynamic> json) =>
      _$PaywayTransactionFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayTransactionToJson(this);

  @override
  String toString() =>
      'PaywayTransaction(transactionId: $transactionId, paymentStatus: $paymentStatus, totalAmount: $totalAmount $originalCurrency)';
}

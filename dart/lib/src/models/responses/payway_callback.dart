import 'package:json_annotation/json_annotation.dart';

import '../json_converters.dart';

part 'payway_callback.g.dart';

/// The payment result PayWay POSTs (JSON) to your `return_url`.
/// Verify it with `PaywayService.verifyCallback` before trusting it.
@JsonSerializable(fieldRename: FieldRename.snake)
class PaywayCallback {
  /// transaction id
  @JsonKey(fromJson: stringFromJson)
  final String tranId;

  /// approval code
  @JsonKey(fromJson: stringFromJson)
  final String apv;

  /// `0` when the payment succeeded
  @JsonKey(fromJson: stringFromJson)
  final String status;

  /// the `returnParams` given at purchase
  @JsonKey(fromJson: stringFromJson)
  final String returnParams;

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

  /// discount amount
  @JsonKey(fromJson: doubleFromJson)
  final double discountAmount;

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

  /// e.g. `ABA Pay`, `KHQR`, `VISA`, `MC`
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

  /// Creates a [PaywayCallback].
  const PaywayCallback({
    required this.tranId,
    required this.apv,
    required this.status,
    required this.returnParams,
    required this.originalAmount,
    required this.originalCurrency,
    required this.paymentAmount,
    required this.paymentCurrency,
    required this.totalAmount,
    required this.discountAmount,
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
  });

  /// Whether the payment succeeded (`status` `0`).
  bool get isSuccess => status == '0' || status == '00';

  /// Parses PayWay JSON.
  factory PaywayCallback.fromJson(Map<String, dynamic> json) =>
      _$PaywayCallbackFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayCallbackToJson(this);

  @override
  String toString() =>
      'PaywayCallback(tranId: $tranId, status: $status, totalAmount: $totalAmount $originalCurrency)';
}

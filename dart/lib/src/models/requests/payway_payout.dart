import 'package:json_annotation/json_annotation.dart';

part 'payway_payout.g.dart';

/// A split of the purchase amount to an ABA account (`payout`).
@JsonSerializable()
class PaywayPayout {
  /// ABA account number
  @JsonKey(name: 'acc')
  final String account;

  /// amount paid out to [account]
  @JsonKey(name: 'amt')
  final num amount;

  /// Creates a [PaywayPayout].
  const PaywayPayout({required this.account, required this.amount});

  /// Parses PayWay JSON.
  factory PaywayPayout.fromJson(Map<String, dynamic> json) =>
      _$PaywayPayoutFromJson(json);

  /// PayWay's JSON form: `{"acc": ..., "amt": ...}`.
  Map<String, dynamic> toJson() => _$PaywayPayoutToJson(this);

  @override
  String toString() => 'PaywayPayout(account: $account, amount: $amount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaywayPayout &&
          other.account == account &&
          other.amount == amount;

  @override
  int get hashCode => Object.hash(account, amount);
}

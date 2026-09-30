import 'package:json_annotation/json_annotation.dart';

part 'payway_item.g.dart';

/// A purchased item. Items are a description only: PayWay does not use
/// their price or quantity for calculation or validation. Up to 50 items.
@JsonSerializable()
class PaywayItem {
  /// item name
  final String name;

  /// quantity
  final num quantity;

  /// unit price
  final num price;

  /// Creates a [PaywayItem].
  const PaywayItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  /// Parses PayWay JSON.
  factory PaywayItem.fromJson(Map<String, dynamic> json) =>
      _$PaywayItemFromJson(json);

  /// PayWay's JSON form.
  Map<String, dynamic> toJson() => _$PaywayItemToJson(this);

  @override
  String toString() =>
      'PaywayItem(name: $name, quantity: $quantity, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaywayItem &&
          other.name == name &&
          other.quantity == quantity &&
          other.price == price;

  @override
  int get hashCode => Object.hash(name, quantity, price);
}

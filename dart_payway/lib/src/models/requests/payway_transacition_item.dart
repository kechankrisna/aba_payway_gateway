import 'dart:convert';

class PaywayTransactionItem {
  final String name;
  final double quantity;
  final double price;

  PaywayTransactionItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  PaywayTransactionItem copyWith({
    String? name,
    double? quantity,
    double? price,
  }) {
    return PaywayTransactionItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory PaywayTransactionItem.fromMap(Map<String, dynamic> map) {
    return PaywayTransactionItem(
      name: map['name'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      price: map['price']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayTransactionItem.fromJson(String source) => PaywayTransactionItem.fromMap(json.decode(source));

  @override
  String toString() => 'PaywayTransactionItem(name: $name, quantity: $quantity, price: $price)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PaywayTransactionItem &&
      other.name == name &&
      other.quantity == quantity &&
      other.price == price;
  }

  @override
  int get hashCode => name.hashCode ^ quantity.hashCode ^ price.hashCode;
}

class ABATransactionItem {
  String? name;
  double? quantity;
  double? price;

  ABATransactionItem({this.name, this.quantity, this.price});

  factory ABATransactionItem.fromMap(Map<String, dynamic> map) {
    return ABATransactionItem(
      name: map["name"],
      quantity: double.tryParse("${map["quantity"]}"),
      price: double.tryParse("${map["price"]}"),
    );
  }

  copyWith({
    String? name,
    double? quantity,
    double? price,
  }) {
    return ABATransactionItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "quantity": quantity,
      "price": price,
    };
  }
}

class ShoppingItem {
  final String name;
  final String quantity;
  final double unitPrice;
  final double totalPrice;
  final String category;

  const ShoppingItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.category = 'material',
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'material',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'category': category,
      };
}

class CartItemModel {
  final String id;
  final String? designId;
  final String name;
  final String quantity;
  final double unitPrice;
  final double totalPrice;
  final String category;

  const CartItemModel({
    required this.id,
    required this.designId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.category,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      designId: json['design_id'] as String?,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'material',
    );
  }
}

class CartSummaryModel {
  final List<CartItemModel> items;
  final double totalCost;

  const CartSummaryModel({required this.items, required this.totalCost});

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      items: (json['items'] as List? ?? [])
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}

import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final DateTime addedAt;
  final String? notes;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
    this.notes,
  });

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    DateTime? addedAt,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      product: Product.fromMap(map['product']),
      quantity: map['quantity'],
      addedAt: DateTime.parse(map['addedAt']),
      notes: map['notes'],
    );
  }

  double get totalPrice => (product.price ?? 0.0) * quantity;
}

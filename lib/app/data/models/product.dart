class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double? price;
  final String category;
  final List<String> images;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> customAttributes;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    this.price,
    required this.category,
    this.images = const [],
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.customAttributes = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num?)?.toDouble(),
      category: json['category'] as String,
      images: List<String>.from(json['images'] ?? []),
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      customAttributes: Map<String, dynamic>.from(json['customAttributes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'customAttributes': customAttributes,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product.fromJson(map);
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? images,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customAttributes,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, price: $price)';
  }
}

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final double? price;
  final bool priceOnInquiry;
  final List<String> categories;
  final List<String> images;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> customAttributes;
  
  // Extended fields from backend
  final List<ProductCategory>? productCategories;
  final List<ProductMedia>? media;
  final List<String>? categoryNames;
  final SellerInfo? seller;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    this.price,
    this.priceOnInquiry = false,
    required this.categories,
    this.images = const [],
    this.isAvailable = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.customAttributes = const {},
    this.productCategories,
    this.media,
    this.categoryNames,
    this.seller,
  });

  // Convenience getter for backward compatibility
  String get category => categories.isNotEmpty ? categories.first : 'Uncategorized';

  // Get primary image URL
  String get primaryImageUrl {
if (media?.isNotEmpty == true) {
for (int i = 0; i < media!.length; i++) {
        final m = media![i];
}
    }
if (media?.isNotEmpty == true) {
      final primaryMedia = media!.firstWhere(
        (m) => m.isPrimary && m.mediaType == 'image',
        orElse: () => media!.firstWhere(
          (m) => m.mediaType == 'image',
          orElse: () => media!.first,
        ),
      );
return primaryMedia.mediaUrl;
    }
    if (images.isNotEmpty) {
return images.first;
    }
return 'https://via.placeholder.com/300x300/E0E0E0/FFFFFF?text=No+Image';
  }

  // Get all image URLs
  List<String> get allImageUrls {
    if (media?.isNotEmpty == true) {
      return media!
          .where((m) => m.mediaType == 'image')
          .map((m) => m.mediaUrl)
          .toList();
    }
    return images;
  }

  // Get all video URLs
  List<String> get videoUrls {
    if (media?.isNotEmpty == true) {
      return media!
          .where((m) => m.mediaType == 'video')
          .map((m) => m.mediaUrl)
          .toList();
    }
    return [];
  }

  // Format price display
  String get formattedPrice {
    if (priceOnInquiry) {
      return 'Price on Inquiry';
    }
    if (price != null) {
      return '₹${price!.toStringAsFixed(0)}';
    }
    return 'Price not set';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle both old and new JSON structures
    final categoriesData = json['categories'] ?? json['Categories'];
    List<ProductCategory>? productCategories;
    List<String> categories = [];
    
    if (categoriesData is List) {
      productCategories = categoriesData.map((item) => ProductCategory.fromJson(item)).toList();
    }
    
    final mediaData = json['media'] ?? json['Media'];
    List<ProductMedia>? media;
    List<String> images = [];
if (mediaData is List) {
media = mediaData.map((item) {
return ProductMedia.fromJson(item);
      }).toList();
images = media
          .where((m) => m.mediaType == 'image' && (m.mediaUrl).toString().isNotEmpty)
          .map((m) => m.mediaUrl.trim())
          .toList();
}
// Parse category names with better handling of different formats
    if (json['categoryNames'] != null && json['categoryNames'] is List && (json['categoryNames'] as List).isNotEmpty) {
      categories = List<String>.from(json['categoryNames']);
    }
    else if (json['CategoryNames'] != null) {
      if (json['CategoryNames'] is String && (json['CategoryNames'] as String).isNotEmpty) {
        final categoryNamesStr = json['CategoryNames'] as String;
        categories = categoryNamesStr.split(', ').where((name) => name.isNotEmpty).toList();
      }
      else if (json['CategoryNames'] is List && (json['CategoryNames'] as List).isNotEmpty) {
        categories = List<String>.from(json['CategoryNames']);
      }
    }
    // Fallback: Use productCategories with placeholder names
    else if (productCategories != null && productCategories.isNotEmpty) {
      categories = productCategories.map((pc) => 'Category ${pc.catId}').toList();
    }

    // Use Pascal case field names from API with better null/empty handling
    final productId = json['productId'] ?? json['ProductId'] ?? json['id'];
    final sellerId = json['sellerId'] ?? json['SellerId'];
    final productName = json['productName'] ?? json['ProductName'] ?? json['name'];
    final description = json['description'] ?? json['Description'];
    final price = (json['price'] ?? json['Price'] as num?)?.toDouble();
    final priceOnInquiry = json['priceOnInquiry'] ?? json['PriceOnInquiry'] ?? json['price_on_inquiry'] ?? false;
    final isAvailable = json['isAvailable'] ?? json['IsAvailable'] ?? json['is_available'] ?? true;
    final isActive = json['isActive'] ?? json['IsActive'] ?? json['is_active'] ?? true;
    final createdAt = json['createdAt'] ?? json['CreatedAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['UpdatedAt'] ?? json['updated_at'];
    final customAttributes = json['customAttributes'] ?? json['CustomAttributes'] ?? {};

    // Provide fallbacks for empty values and generate test data if needed
    final finalProductName = (productName != null && productName.toString().isNotEmpty) 
        ? productName.toString() 
        : 'Product ${productId ?? DateTime.now().millisecondsSinceEpoch}';
    
    // If we have no categories but have productCategories, generate some test categories
    if (categories.isEmpty && productCategories != null && productCategories.isNotEmpty) {
      categories = productCategories.map((pc) => 'Category ${pc.catId}').toList();
    }
    // If still no categories, add a default one for testing
    else if (categories.isEmpty) {
      categories = ['General'];
    }

    return Product(
      id: productId.toString(),
      sellerId: sellerId.toString(),
      name: finalProductName,
      description: description?.toString(),
      price: price,
      priceOnInquiry: priceOnInquiry,
      categories: categories,
      images: images,
      isAvailable: isAvailable,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(updatedAt ?? DateTime.now().toIso8601String()),
      customAttributes: Map<String, dynamic>.from(customAttributes),
      productCategories: productCategories,
      media: media,
      categoryNames: categories.isNotEmpty ? categories : null,
      seller: json['seller'] != null ? SellerInfo.fromJson(json['seller']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': int.tryParse(id),
      'id': id,
      'sellerId': int.tryParse(sellerId),
      'productName': name,
      'name': name,
      'description': description,
      'price': price,
      'priceOnInquiry': priceOnInquiry,
      'categories': categories,
      'images': images,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'customAttributes': customAttributes,
      if (productCategories != null)
        'productCategories': productCategories!.map((c) => c.toJson()).toList(),
      if (media != null)
        'media': media!.map((m) => m.toJson()).toList(),
      if (categoryNames != null)
        'categoryNames': categoryNames,
      if (seller != null)
        'seller': seller!.toJson(),
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
    bool? priceOnInquiry,
    List<String>? categories,
    List<String>? images,
    bool? isAvailable,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customAttributes,
    List<ProductCategory>? productCategories,
    List<ProductMedia>? media,
    List<String>? categoryNames,
    SellerInfo? seller,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      priceOnInquiry: priceOnInquiry ?? this.priceOnInquiry,
      categories: categories ?? this.categories,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customAttributes: customAttributes ?? this.customAttributes,
      productCategories: productCategories ?? this.productCategories,
      media: media ?? this.media,
      categoryNames: categoryNames ?? this.categoryNames,
      seller: seller ?? this.seller,
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
    return 'Product(id: $id, name: $name, categories: $categories, price: $price)';
  }
}

class ProductCategory {
  final int? pcBindId;
  final int productId;
  final int catId;
  final bool isPrimary;
  final bool active;

  ProductCategory({
    this.pcBindId,
    required this.productId,
    required this.catId,
    this.isPrimary = false,
    this.active = true,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      pcBindId: json['pcBindId'] ?? json['PcBindId'],
      productId: json['productId'] ?? json['ProductId'],
      catId: json['catId'] ?? json['CatId'],
      isPrimary: json['isPrimary'] ?? json['IsPrimary'] ?? false,
      active: json['active'] ?? json['Active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pcBindId': pcBindId,
      'productId': productId,
      'catId': catId,
      'isPrimary': isPrimary,
      'active': active,
    };
  }
}

class ProductMedia {
  final int? mediaId;
  final int productId;
  final String mediaType;
  final String mediaUrl;
  final int mediaOrder;
  final bool isPrimary;
  final String? altText;
  final String? s3Key;
  final int? fileSize;
  final String? mimeType;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final DateTime createdAt;

  ProductMedia({
    this.mediaId,
    required this.productId,
    required this.mediaType,
    required this.mediaUrl,
    this.mediaOrder = 0,
    this.isPrimary = false,
    this.altText,
    this.s3Key,
    this.fileSize,
    this.mimeType,
    this.durationSeconds,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory ProductMedia.fromJson(Map<String, dynamic> json) {
    // Robust createdAt parsing: handle nulls and invalid formats gracefully
    DateTime parsedCreatedAt;
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    if (createdAtRaw == null || (createdAtRaw is String && createdAtRaw.isEmpty)) {
      parsedCreatedAt = DateTime.now();
    } else if (createdAtRaw is String) {
      try {
        parsedCreatedAt = DateTime.parse(createdAtRaw);
      } catch (_) {
        parsedCreatedAt = DateTime.now();
      }
    } else if (createdAtRaw is int) {
      // Support unix epoch seconds/millis heuristically
      try {
        parsedCreatedAt = createdAtRaw > 2000000000
            ? DateTime.fromMillisecondsSinceEpoch(createdAtRaw)
            : DateTime.fromMillisecondsSinceEpoch(createdAtRaw * 1000);
      } catch (_) {
        parsedCreatedAt = DateTime.now();
      }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return ProductMedia(
      mediaId: json['mediaId'] ?? json['MediaId'],
      productId: json['productId'] ?? json['ProductId'],
      mediaType: json['mediaType'] ?? json['MediaType'] ?? 'image',
      mediaUrl: json['mediaUrl'] ?? json['MediaUrl'] ?? '',
      mediaOrder: json['mediaOrder'] ?? json['MediaOrder'] ?? 0,
      isPrimary: json['isPrimary'] ?? json['IsPrimary'] ?? false,
      altText: json['altText'] ?? json['AltText'],
      s3Key: json['s3Key'] ?? json['S3Key'],
      fileSize: json['fileSize'] ?? json['FileSize'],
      mimeType: json['mimeType'] ?? json['MimeType'],
      durationSeconds: json['durationSeconds'] ?? json['DurationSeconds'],
      thumbnailUrl: json['thumbnailUrl'] ?? json['ThumbnailUrl'],
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'productId': productId,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'mediaOrder': mediaOrder,
      'isPrimary': isPrimary,
      'altText': altText,
      's3Key': s3Key,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'durationSeconds': durationSeconds,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SellerInfo {
  final int? sellerId;
  final String? businessName;
  final String? profileName;
  final String? city;
  final String? area;
  final String? logo;

  SellerInfo({
    this.sellerId,
    this.businessName,
    this.profileName,
    this.city,
    this.area,
    this.logo,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      sellerId: json['sellerId'],
      businessName: json['businessName'],
      profileName: json['profileName'],
      city: json['city'],
      area: json['area'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'businessName': businessName,
      'profileName': profileName,
      'city': city,
      'area': area,
      'logo': logo,
    };
  }
}

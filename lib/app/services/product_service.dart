import '../data/models/product.dart';
import '../data/models/api/seller_details.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';

class ProductService extends BaseApiService {
  static ProductService? _instance;
  static ProductService get instance {
    if (_instance == null) {
      _instance = ProductService._internal();
      _instance!.onInit(); // Manually call onInit for singleton
    }
    return _instance!;
  }
  ProductService._internal();

  // UNIFIED PRODUCT FETCHING METHODS

  /// Get all products with filtering and pagination - MAIN SEARCH ENDPOINT
  Future<ApiResponse<ProductSearchResponse>> getProducts({
    int? sellerId,
    String? productName,
    List<int>? categoryIds,
  String? categoryName,
    double? minPrice,
    double? maxPrice,
    bool? isAvailable,
    String? city,
    String? area,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'createdat',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      // Capitalized variants for some backends
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      'SortBy': sortBy,
      'SortOrder': sortOrder,
    };

  if (sellerId != null) { queryParams['sellerId'] = sellerId.toString(); queryParams['SellerId'] = sellerId.toString(); }
  if (productName != null && productName.isNotEmpty) { queryParams['productName'] = productName; queryParams['ProductName'] = productName; }
    if (categoryIds != null && categoryIds.isNotEmpty) {
      // Common patterns used by backends for array binding
      // 1) Indexed params: categoryIds[0]=1&categoryIds[1]=2
      for (int i = 0; i < categoryIds.length; i++) {
        queryParams['categoryIds[$i]'] = categoryIds[i].toString();
      }
      // 2) Repeated key without brackets: categoryIds=1&categoryIds=2 (ASP.NET works)
      // We'll also provide a comma-separated variant as a single key.
  queryParams['categoryIds'] = categoryIds.join(',');
  queryParams['CategoryIds'] = categoryIds.join(',');
      // 3) Single category fallback some APIs expect
      queryParams['categoryId'] = categoryIds.first.toString();
      queryParams['CategoryId'] = categoryIds.first.toString();
    }
  if (categoryName != null && categoryName.isNotEmpty) { queryParams['categoryName'] = categoryName; queryParams['CategoryName'] = categoryName; }
  if (minPrice != null) { queryParams['minPrice'] = minPrice.toString(); queryParams['MinPrice'] = minPrice.toString(); }
    if (maxPrice != null) { queryParams['maxPrice'] = maxPrice.toString(); queryParams['MaxPrice'] = maxPrice.toString(); }
    if (isAvailable != null) { queryParams['isAvailable'] = isAvailable.toString(); queryParams['IsAvailable'] = isAvailable.toString(); }
    if (city != null && city.isNotEmpty) { queryParams['city'] = city; queryParams['City'] = city; }
    if (area != null && area.isNotEmpty) { queryParams['area'] = area; queryParams['Area'] = area; }

    return await get<ProductSearchResponse>(
      '/Products',
      queryParams: queryParams,
      fromJson: (json) {
        // Normalize known field casing before parsing
        if (json is Map<String, dynamic>) {
          // If only uppercase keys exist, copy to lowercase for parser fallback
          json.putIfAbsent('products', () => json['Products']);
          json.putIfAbsent('totalCount', () => json['TotalCount']);
          json.putIfAbsent('page', () => json['Page']);
          json.putIfAbsent('pageSize', () => json['PageSize']);
          json.putIfAbsent('totalPages', () => json['TotalPages']);
          json.putIfAbsent('hasNextPage', () => json['HasNextPage']);
          json.putIfAbsent('hasPreviousPage', () => json['HasPreviousPage']);
        }
        return ProductSearchResponse.fromJson(json);
      },
    );
  }

  /// Get single product with full details - UNIFIED METHOD
  Future<ApiResponse<Product>> getProductDetails(int productId) async {
    return await get<Product>(
      '/Product/$productId',
      fromJson: (json) => Product.fromJson(json),
    );
  }

  /// Search products with advanced filtering - UNIFIED METHOD
  Future<ApiResponse<ProductSearchResponse>> searchProducts({
    int? sellerId,
    String? productName,
    List<int>? categoryIds,
  String? categoryName,
    double? minPrice,
    double? maxPrice,
    bool? isAvailable,
    String? city,
    String? area,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'createdat',
    String sortOrder = 'desc',
  }) async {
    // This is the same as getProducts - unified interface
    return await getProducts(
      sellerId: sellerId,
      productName: productName,
      categoryIds: categoryIds,
  categoryName: categoryName,
      minPrice: minPrice,
      maxPrice: maxPrice,
      isAvailable: isAvailable,
      city: city,
      area: area,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  /// Get products by seller ID - OPTIMIZED METHOD
  Future<ApiResponse<ProductSearchResponse>> getProductsBySeller(
    int sellerId, {
    int page = 1,
    int pageSize = 20,
    String sortBy = 'createdat',
    String sortOrder = 'desc',
  }) async {
    return await getProducts(
      sellerId: sellerId,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  /// Get seller details by seller ID - UNIFIED WITH PRODUCT FETCHING
  Future<ApiResponse<SellerDetailsExtended>> getSellerDetailsBySellerId(int sellerId) async {
    return await get<SellerDetailsExtended>(
      '/SellerBySellerId/$sellerId',
      fromJson: (json) => SellerDetailsExtended.fromJson(json),
    );
  }

  // PRODUCT MANAGEMENT METHODS

  /// Create new product
  Future<ApiResponse<Product>> createProduct(CreateProductRequest request) async {
    return await post<Product>(
      '/Product',
      body: request.toJson(),
      fromJson: (json) => Product.fromJson(json),
    );
  }

  /// Update existing product
  Future<ApiResponse<Product>> updateProduct(int productId, UpdateProductRequest request) async {
    return await put<Product>(
      '/Product/$productId',
      body: request.toJson(),
      fromJson: (json) => Product.fromJson(json),
    );
  }

  /// Delete product (soft delete)
  Future<ApiResponse<void>> deleteProduct(int productId) async {
    return await delete('/Product/$productId');
  }

  // MEDIA UPLOAD METHODS

  /// Upload multiple images for a product - UNIFIED METHOD
  Future<ApiResponse<BulkMediaUploadResponse>> uploadMultipleImages(
    int productId,
    List<ImageUploadData> images,
  ) async {
    final mediaRequests = images.map((img) => ProductMediaRequest(
      mediaType: 'image',
      base64Content: img.base64Content,
      fileName: img.fileName,
      mediaOrder: img.mediaOrder,
      isPrimary: img.isPrimary,
      altText: img.altText,
      contentType: img.contentType,
    )).toList();

    final response = await bulkUploadMedia(productId, mediaRequests);
    
    if (response.isSuccess) {
      return ApiResponse.success(
        response.data!,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.error(
        response.errorMessage ?? 'Failed to upload images',
        statusCode: response.statusCode,
      );
    }
  }

  /// Bulk upload media for product
  Future<ApiResponse<BulkMediaUploadResponse>> bulkUploadMedia(
    int productId,
    List<ProductMediaRequest> mediaFiles,
  ) async {
    final request = BulkMediaUploadRequest(
      productId: productId,
      mediaFiles: mediaFiles,
    );

    return await post<BulkMediaUploadResponse>(
      '/Product/$productId/Media',
      body: request.toJson(),
      fromJson: (json) => BulkMediaUploadResponse.fromJson(json),
    );
  }

  /// Upload single image (convenience method)
  Future<ApiResponse<ProductMedia>> uploadSingleImage(
    int productId,
    String base64Content,
    String fileName, {
    int mediaOrder = 0,
    bool isPrimary = false,
    String? altText,
    String contentType = 'image/jpeg',
  }) async {
    final mediaRequest = ProductMediaRequest(
      mediaType: 'image',
      base64Content: base64Content,
      fileName: fileName,
      mediaOrder: mediaOrder,
      isPrimary: isPrimary,
      altText: altText,
      contentType: contentType,
    );

    final response = await bulkUploadMedia(productId, [mediaRequest]);
    
    if (response.isSuccess && response.data!.uploadedMedia.isNotEmpty) {
      return ApiResponse.success(
        response.data!.uploadedMedia.first,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.error(
        response.data?.errors.isNotEmpty == true
            ? response.data!.errors.first
            : 'Failed to upload image',
        statusCode: response.statusCode,
      );
    }
  }

  /// Delete single media
  Future<ApiResponse<void>> deleteProductMedia(int productId, int mediaId) async {
    return await delete('/Product/$productId/Media/$mediaId');
  }

  // FAVORITES AND VIEWS METHODS (moved from BuyerService)

  /// Check if product is favorited by user
  Future<ApiResponse<Map<String, dynamic>>> checkIfProductFavorite({
    required int userId,
    required int productId,
  }) async {
    return await get<Map<String, dynamic>>(
      '/UserFavorite/Check',
      queryParams: {
        'userId': userId.toString(),
        'refId': productId.toString(),
        'type': 'P',
      },
      fromJson: (json) => json,
    );
  }

  /// Add product to favorites
  Future<ApiResponse<Map<String, dynamic>>> addProductToFavorites({
    required int userId,
    required int productId,
  }) async {
    return await post<Map<String, dynamic>>(
      '/UserFavorite',
      body: {
        'userId': userId,
        'refId': productId,
        'type': 'P',
      },
      fromJson: (json) => json,
    );
  }

  /// Remove product from favorites
  Future<ApiResponse<Map<String, dynamic>>> removeProductFromFavorites({
    required int userId,
    required int productId,
  }) async {
    final response = await delete('/UserFavorite');
    return ApiResponse.success(
      {'message': 'Removed from favorites', 'userId': userId, 'productId': productId},
      statusCode: response.statusCode,
    );
  }

  /// Track product view
  Future<ApiResponse<Map<String, dynamic>>> trackProductView({
    required int userId,
    required int productId,
  }) async {
    return await post<Map<String, dynamic>>(
      '/UserView',
      body: {
        'userId': userId,
        'refId': productId,
        'type': 'P',
        'viewedAt': DateTime.now().toIso8601String(),
      },
      fromJson: (json) => json,
    );
  }

  /// Get user's all favorites (products and sellers)
  Future<ApiResponse<Map<String, dynamic>>> getUserFavorites(int userId) async {
    return await get<Map<String, dynamic>>(
      '/UserFavorites/$userId',
      fromJson: (json) => json,
    );
  }

  /// Get user's favorite products
  Future<ApiResponse<List<Product>>> getUserFavoriteProducts(int userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return await get<List<Product>>(
      '/UserFavorite/Products/$userId',
      queryParams: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
      fromJson: (json) => (json as List).map((item) => Product.fromJson(item)).toList(),
    );
  }

  /// Add seller to favorites
  Future<ApiResponse<Map<String, dynamic>>> addSellerToFavorites({
    required int userId,
    required int sellerId,
  }) async {
    return await post<Map<String, dynamic>>(
      '/AddToFavorites',
      body: {'refId': sellerId, 'type': 'S'},
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }

  /// Remove seller from favorites
  Future<ApiResponse<Map<String, dynamic>>> removeSellerFromFavorites({
    required int userId,
    required int sellerId,
  }) async {
    return await post<Map<String, dynamic>>(
      '/RemoveFromFavorites',
      body: {'refId': sellerId, 'type': 'S'},
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }

  /// Check if seller is in favorites
  Future<ApiResponse<Map<String, dynamic>>> checkIfSellerFavorite({
    required int userId,
    required int sellerId,
  }) async {
    return await get<Map<String, dynamic>>(
      '/CheckFavorite',
      queryParams: {
        'userId': userId.toString(),
        'refId': sellerId.toString(),
        'type': 'S',
      },
      fromJson: (json) => json,
    );
  }

  /// Track seller view
  Future<ApiResponse<Map<String, dynamic>>> trackSellerView({
    required int userId,
    required int sellerId,
  }) async {
    return await post<Map<String, dynamic>>(
      '/TrackView',
      body: {'refId': sellerId, 'type': 'S'},
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }

  /// Get user's recently viewed products
  Future<ApiResponse<List<Product>>> getUserViewedProducts(int userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return await get<List<Product>>(
      '/UserView/Products/$userId',
      queryParams: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
      fromJson: (json) => (json as List).map((item) => Product.fromJson(item)).toList(),
    );
  }
}

// Helper classes for API requests/responses
class ProductSearchResponse {
  final List<Product> products;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  ProductSearchResponse({
    required this.products,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory ProductSearchResponse.fromJson(Map<String, dynamic> json) {
  final productsJson = (json['products'] ?? json['Products']) as List?;
    
    final products = productsJson?.map((item) {
      try {
        return Product.fromJson(item);
      } catch (e) {
        rethrow;
      }
    }).toList() ?? [];
    
    return ProductSearchResponse(
      products: products,
      totalCount: json['totalCount'] ?? json['TotalCount'] ?? products.length,
      page: json['page'] ?? json['Page'] ?? 1,
      pageSize: json['pageSize'] ?? json['PageSize'] ?? 20,
      totalPages: json['totalPages'] ?? json['TotalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? json['HasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? json['HasPreviousPage'] ?? false,
    );
  }
}

class CreateProductRequest {
  final int sellerId;
  final String productName;
  final String? description;
  final double? price;
  final bool priceOnInquiry;
  final bool isAvailable;
  final String? customAttributes;
  final List<int> categoryIds;
  final int? primaryCategoryId;
  final List<ProductMediaRequest> media;

  CreateProductRequest({
    required this.sellerId,
    required this.productName,
    this.description,
    this.price,
    this.priceOnInquiry = false,
    this.isAvailable = true,
    this.customAttributes,
    this.categoryIds = const [],
    this.primaryCategoryId,
    this.media = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'productName': productName,
      'description': description,
      'price': price,
      'priceOnInquiry': priceOnInquiry,
      'isAvailable': isAvailable,
      'customAttributes': customAttributes,
      'categoryIds': categoryIds,
      'primaryCategoryId': primaryCategoryId,
      'media': media.map((m) => m.toJson()).toList(),
    };
  }
}

class UpdateProductRequest {
  final int productId;
  final String productName;
  final String? description;
  final double? price;
  final bool priceOnInquiry;
  final bool isAvailable;
  final String? customAttributes;
  final List<int> categoryIds;
  final int? primaryCategoryId;
  final List<ProductMediaRequest> media;

  UpdateProductRequest({
    required this.productId,
    required this.productName,
    this.description,
    this.price,
    this.priceOnInquiry = false,
    this.isAvailable = true,
    this.customAttributes,
    this.categoryIds = const [],
    this.primaryCategoryId,
    this.media = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'price': price,
      'priceOnInquiry': priceOnInquiry,
      'isAvailable': isAvailable,
      'customAttributes': customAttributes,
      'categoryIds': categoryIds,
      'primaryCategoryId': primaryCategoryId,
      'media': media.map((m) => m.toJson()).toList(),
    };
  }
}

class ProductMediaRequest {
  final String mediaType;
  final String base64Content;
  final String fileName;
  final int mediaOrder;
  final bool isPrimary;
  final String? altText;
  final String? contentType;

  ProductMediaRequest({
    this.mediaType = 'image',
    required this.base64Content,
    required this.fileName,
    this.mediaOrder = 0,
    this.isPrimary = false,
    this.altText,
    this.contentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'mediaType': mediaType,
      'base64Content': base64Content,
      'fileName': fileName,
      'mediaOrder': mediaOrder,
      'isPrimary': isPrimary,
      'altText': altText,
      'contentType': contentType,
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
    return ProductMedia(
      mediaId: json['mediaId'],
      productId: json['productId'],
      mediaType: json['mediaType'] ?? 'image',
      mediaUrl: json['mediaUrl'] ?? '',
      mediaOrder: json['mediaOrder'] ?? 0,
      isPrimary: json['isPrimary'] ?? false,
      altText: json['altText'],
      s3Key: json['s3Key'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      durationSeconds: json['durationSeconds'],
      thumbnailUrl: json['thumbnailUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class BulkMediaUploadRequest {
  final int productId;
  final List<ProductMediaRequest> mediaFiles;

  BulkMediaUploadRequest({
    required this.productId,
    required this.mediaFiles,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'mediaFiles': mediaFiles.map((m) => m.toJson()).toList(),
    };
  }
}

class BulkMediaUploadResponse {
  final bool success;
  final List<ProductMedia> uploadedMedia;
  final List<String> errors;
  final int successCount;
  final int failureCount;

  BulkMediaUploadResponse({
    required this.success,
    required this.uploadedMedia,
    required this.errors,
    required this.successCount,
    required this.failureCount,
  });

  factory BulkMediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return BulkMediaUploadResponse(
      success: json['success'] ?? false,
      uploadedMedia: (json['uploadedMedia'] as List?)
          ?.map((item) => ProductMedia.fromJson(item))
          .toList() ?? [],
      errors: List<String>.from(json['errors'] ?? []),
      successCount: json['successCount'] ?? 0,
      failureCount: json['failureCount'] ?? 0,
    );
  }
}

class ImageUploadData {
  final String base64Content;
  final String fileName;
  final int mediaOrder;
  final bool isPrimary;
  final String? altText;
  final String contentType;

  ImageUploadData({
    required this.base64Content,
    required this.fileName,
    this.mediaOrder = 0,
    this.isPrimary = false,
    this.altText,
    this.contentType = 'image/jpeg',
  });
}

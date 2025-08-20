import '../data/models/product.dart';
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

  // Get all products with filtering and pagination
  Future<ApiResponse<ProductSearchResponse>> getProducts({
    int? sellerId,
    String? productName,
    List<int>? categoryIds,
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
    };

    if (sellerId != null) queryParams['sellerId'] = sellerId.toString();
    if (productName != null && productName.isNotEmpty) queryParams['productName'] = productName;
    if (categoryIds != null && categoryIds.isNotEmpty) {
      for (int i = 0; i < categoryIds.length; i++) {
        queryParams['categoryIds[$i]'] = categoryIds[i].toString();
      }
    }
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (isAvailable != null) queryParams['isAvailable'] = isAvailable.toString();
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (area != null && area.isNotEmpty) queryParams['area'] = area;

    return await get<ProductSearchResponse>(
      '/Products',
      queryParams: queryParams,
      fromJson: (json) => ProductSearchResponse.fromJson(json),
    );
  }

  // Get single product by ID
  Future<ApiResponse<Product>> getProduct(int productId) async {
    return await get<Product>(
      '/Product/$productId',
      fromJson: (json) => Product.fromJson(json),
    );
  }

  // Create new product
  Future<ApiResponse<Product>> createProduct(CreateProductRequest request) async {
    return await post<Product>(
      '/Product',
      body: request.toJson(),
      fromJson: (json) => Product.fromJson(json),
    );
  }

  // Update existing product
  Future<ApiResponse<Product>> updateProduct(int productId, UpdateProductRequest request) async {
    return await put<Product>(
      '/Product/$productId',
      body: request.toJson(),
      fromJson: (json) => Product.fromJson(json),
    );
  }

  // Delete product (soft delete)
  Future<ApiResponse<void>> deleteProduct(int productId) async {
    return await delete('/Product/$productId');
  }

  // Get products by seller
  Future<ApiResponse<ProductSearchResponse>> getProductsBySeller(
    int sellerId, {
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
    };

    return await get<ProductSearchResponse>(
      '/Seller/$sellerId/Products',
      queryParams: queryParams,
      fromJson: (json) => ProductSearchResponse.fromJson(json),
    );
  }

  // Bulk upload media for product
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

  // Delete single media
  Future<ApiResponse<void>> deleteProductMedia(int productId, int mediaId) async {
    return await delete('/Product/$productId/Media/$mediaId');
  }

  // Upload single image (convenience method)
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

  // Upload multiple images (convenience method)
  Future<ApiResponse<List<ProductMedia>>> uploadMultipleImages(
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
        response.data!.uploadedMedia,
        statusCode: response.statusCode,
      );
    } else {
      return ApiResponse.error(
        response.errorMessage ?? 'Failed to upload images',
        statusCode: response.statusCode,
      );
    }
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
    print('DEBUG: Raw API Response: $json'); // Debug log
    
    final productsJson = json['products'] as List?;
    print('DEBUG: Products JSON: $productsJson'); // Debug log
    
    final products = productsJson?.map((item) {
      print('DEBUG: Processing product item: $item'); // Debug log
      try {
        return Product.fromJson(item);
      } catch (e) {
        print('DEBUG: Error parsing product: $e'); // Debug log
        rethrow;
      }
    }).toList() ?? [];
    
    return ProductSearchResponse(
      products: products,
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
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

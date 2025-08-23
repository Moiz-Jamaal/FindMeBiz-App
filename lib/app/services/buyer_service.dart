import 'package:get/get.dart';
import 'package:souq/app/services/auth_service.dart';

import '../data/models/api/index.dart';
import '../services/product_service.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';

class BuyerService extends BaseApiService {
  // Search sellers with filters
  Future<ApiResponse<List<SellerDetails>>> searchSellers({
    String? businessName,
    String? city,
    String? area,
    int? categoryId,
  }) async {
    final queryParams = <String, String>{};
    
    if (businessName != null && businessName.isNotEmpty) {
      queryParams['businessName'] = businessName;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (area != null && area.isNotEmpty) {
      queryParams['area'] = area;
    }
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId.toString();
    }
    
    final response = await getList<SellerDetails>(
      '/SearchSellers',
      queryParams: queryParams,
      fromJson: (json) => SellerDetails.fromJson(json),
    );
    
    return response;
  }

  // Search products with filters
  Future<ApiResponse<ProductSearchResponse>> searchProducts({
    String? productName,
    List<int>? categoryIds,
    double? minPrice,
    double? maxPrice,
    bool? isAvailable,
    String? city,
    String? area,
    int? sellerId,
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

    if (productName != null && productName.isNotEmpty) {
      queryParams['productName'] = productName;
    }
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
    if (sellerId != null) queryParams['sellerId'] = sellerId.toString();

    return await get<ProductSearchResponse>(
      '/Products',
      queryParams: queryParams,
      fromJson: (json) => ProductSearchResponse.fromJson(json),
    );
  }

  // Get single seller details by ID
  Future<ApiResponse<SellerDetailsExtended>> getSellerDetails(int sellerId) async {
    final response = await get<SellerDetailsExtended>(
      '/Seller/$sellerId',
      fromJson: (json) => SellerDetailsExtended.fromJson(json),
    );
    
    return response;
  }

  // Get seller details by sellerId (new endpoint)
  Future<ApiResponse<SellerDetailsExtended>> getSellerDetailsBySellerId(int sellerId) async {
    final response = await get<SellerDetailsExtended>(
      '/SellerBySellerId/$sellerId',
      fromJson: (json) => SellerDetailsExtended.fromJson(json),
    );
    
    return response;
  }

  // Get single product details by ID
  Future<ApiResponse<Product>> getProductDetails(int productId) async {
    final response = await get<Product>(
      '/Product/$productId',
      fromJson: (json) => Product.fromJson(json),
    );
    
    return response;
  }

 
  // Get products by seller for buyer view
  Future<ApiResponse<ProductSearchResponse>> getSellerProducts(
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

  // Get all categories for filtering
  Future<ApiResponse<List<CategoryMaster>>> getCategories() async {
    final response = await getList<CategoryMaster>(
      '/Categories',
      fromJson: (json) => CategoryMaster.fromJson(json),
    );
    
    return response;
  }

  // Get category hierarchy for advanced filtering
  Future<ApiResponse<List<Map<String, dynamic>>>> getCategoryHierarchy() async {
    final response = await getList<Map<String, dynamic>>(
      '/CategoryHierarchy',
      fromJson: (json) => json,
    );
    
    return response;
  }

  // Combined search - both sellers and products
  Future<ApiResponse<BuyerSearchResult>> combinedSearch({
    required String query,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? city,
    String? area,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      // Search sellers
      final sellersResponse = await searchSellers(
        businessName: query,
        city: city,
        area: area,
        categoryId: categoryId,
      );

      // Search products
      final productsResponse = await searchProducts(
        productName: query,
        categoryIds: categoryId != null ? [categoryId] : null,
        minPrice: minPrice,
        maxPrice: maxPrice,
        city: city,
        area: area,
        page: page,
        pageSize: pageSize,
      );

      final result = BuyerSearchResult(
        sellers: sellersResponse.isSuccess ? sellersResponse.data! : [],
        products: productsResponse.isSuccess ? productsResponse.data! : null,
        query: query,
        hasResults: (sellersResponse.isSuccess && sellersResponse.data!.isNotEmpty) ||
                   (productsResponse.isSuccess && productsResponse.data!.products.isNotEmpty),
      );

      return ApiResponse.success(result);
    } catch (e) {
      return ApiResponse.error('Search failed: ${e.toString()}');
    }
  }

  // Favorites API
  Future<ApiResponse<Map<String, dynamic>>> addToFavorites({
    required int userId,
    required int refId,
    required String type,
  }) async {
    return await post<Map<String, dynamic>>(
      '/AddToFavorites',
      body: {'refId': refId, 'type': type},
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> removeFromFavorites({
    required int userId,
    required int refId,
    required String type,
  }) async {
    return await post<Map<String, dynamic>>(
      '/RemoveFromFavorites',
      body: {'refId': refId, 'type': type},
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> checkIfFavorite({
    required int userId,
    required int refId,
    required String type,
  }) async {
    return await get<Map<String, dynamic>>(
      '/CheckFavorite',
      queryParams: {
        'userId': userId.toString(),
        'refId': refId.toString(),
        'type': type,
      },
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserFavorites(int userId) async {
    return await get<Map<String, dynamic>>(
      '/UserFavorites/$userId',
      fromJson: (json) => json,
    );
  }

  // Reviews API
  Future<ApiResponse<Map<String, dynamic>>> createProductReview(
    int productId,
    int rating,
    String reviewText,
    String reviewTitle,
    bool isAnonymous,
  ) async {
    final authService = Get.find<AuthService>();
    final userId = authService.currentUser?.userid;
    if (userId == null) return ApiResponse.error('User ID required');

    return await post<Map<String, dynamic>>(
      '/ProductReview?productId=$productId',
      body: {
        'rating': rating,
        'reviewText': reviewText,
        'reviewTitle': reviewTitle,
        'isAnonymous': isAnonymous,
      },
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> createSellerReview(
    int sellerId,
    int rating,
    String reviewText,
    String reviewTitle,
    bool isAnonymous,
  ) async {
    final authService = Get.find<AuthService>();
    final userId = authService.currentUser?.userid;
    if (userId == null) return ApiResponse.error('User ID required');

    return await post<Map<String, dynamic>>(
      '/SellerReview?sellerId=$sellerId',
      body: {
        'rating': rating,
        'reviewText': reviewText,
        'reviewTitle': reviewTitle,
        'isAnonymous': isAnonymous,
      },
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getProductReviews(int productId) async {
    return await getList<Map<String, dynamic>>(
      '/ProductReviews/$productId',
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getSellerReviews(int sellerId) async {
    return await getList<Map<String, dynamic>>(
      '/SellerReviews/$sellerId',
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getProductReviewSummary(int productId) async {
    return await get<Map<String, dynamic>>(
      '/ProductReviewSummary/$productId',
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getSellerReviewSummary(int sellerId) async {
    return await get<Map<String, dynamic>>(
      '/SellerReviewSummary/$sellerId',
      fromJson: (json) => json,
    );
  }

  // View Tracking API
  Future<ApiResponse<Map<String, dynamic>>> trackView({
    required int userId,
    required int refId,
    required String type,
  }) async {
    return await post<Map<String, dynamic>>(
      '/TrackView',
      body: {'refId': refId, 'type': type},
      customHeaders: {'X-User-Id': userId.toString()},
      fromJson: (json) => json,
    );
  }
}

// Helper class for combined search results
class BuyerSearchResult {
  final List<SellerDetails> sellers;
  final ProductSearchResponse? products;
  final String query;
  final bool hasResults;

  BuyerSearchResult({
    required this.sellers,
    required this.products,
    required this.query,
    required this.hasResults,
  });

  int get totalSellerCount => sellers.length;
  int get totalProductCount => products?.totalCount ?? 0;
  
  bool get hasSellerResults => sellers.isNotEmpty;
  bool get hasProductResults => products != null && products!.products.isNotEmpty;
}

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

      // Use unified ProductService for product search
      final productService = ProductService.instance;
      final productsResponse = await productService.searchProducts(
        productName: query,
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

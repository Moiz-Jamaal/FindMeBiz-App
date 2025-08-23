import 'package:get/get.dart';
import '../data/models/api/index.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import 'auth_service.dart';

class ViewedHistoryService extends BaseApiService {
  final AuthService _authService = Get.find<AuthService>();

  // Record seller view
  Future<ApiResponse<void>> recordSellerView(int sellerId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Insert/Update users_viewed table with p_s_v = 'S' for seller
      final response = await post<void>(
        '/UserViewed',
        body: {
          'userid': userId,
          'refid': sellerId,
          'p_s_v': 'S', // 'S' for seller, 'P' for product, 'V' for vendor (if needed)
          'dtstamp': DateTime.now().toIso8601String(),
        },
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to record seller view: ${e.toString()}');
    }
  }

  // Record product view
  Future<ApiResponse<void>> recordProductView(int productId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Insert/Update users_viewed table with p_s_v = 'P' for product
      final response = await post<void>(
        '/UserViewed',
        body: {
          'userid': userId,
          'refid': productId,
          'p_s_v': 'P', // 'P' for product
          'dtstamp': DateTime.now().toIso8601String(),
        },
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to record product view: ${e.toString()}');
    }
  }

  // Get user's recently viewed sellers with details
  Future<ApiResponse<List<ViewedSellerItem>>> getRecentlyViewedSellers({
    int limit = 20,
  }) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await getList<ViewedSellerItem>(
        '/UserViewedSellers/$userId',
        queryParams: {'limit': limit.toString()},
        fromJson: (json) => ViewedSellerItem.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get viewed sellers: ${e.toString()}');
    }
  }

  // Get user's recently viewed products with details
  Future<ApiResponse<List<ViewedProductItem>>> getRecentlyViewedProducts({
    int limit = 20,
  }) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await getList<ViewedProductItem>(
        '/UserViewedProducts/$userId',
        queryParams: {'limit': limit.toString()},
        fromJson: (json) => ViewedProductItem.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get viewed products: ${e.toString()}');
    }
  }

  // Get all recently viewed items (combined sellers and products)
  Future<ApiResponse<ViewedHistoryResult>> getRecentlyViewedItems({
    int sellersLimit = 10,
    int productsLimit = 10,
  }) async {
    try {
      final sellersResponse = await getRecentlyViewedSellers(limit: sellersLimit);
      final productsResponse = await getRecentlyViewedProducts(limit: productsLimit);

      final result = ViewedHistoryResult(
        sellers: sellersResponse.isSuccess ? sellersResponse.data! : [],
        products: productsResponse.isSuccess ? productsResponse.data! : [],
        hasItems: (sellersResponse.isSuccess && sellersResponse.data!.isNotEmpty) ||
                 (productsResponse.isSuccess && productsResponse.data!.isNotEmpty),
      );

      return ApiResponse.success(result);
    } catch (e) {
      return ApiResponse.error('Failed to get viewed history: ${e.toString()}');
    }
  }

  // Clear all viewed history
  Future<ApiResponse<void>> clearViewedHistory() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await delete('/UserViewed/$userId');
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to clear viewed history: ${e.toString()}');
    }
  }

  // Clear seller viewed history
  Future<ApiResponse<void>> clearSellerViewedHistory() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await delete('/UserViewedSellers/$userId');
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to clear seller viewed history: ${e.toString()}');
    }
  }

  // Clear product viewed history
  Future<ApiResponse<void>> clearProductViewedHistory() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await delete('/UserViewedProducts/$userId');
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to clear product viewed history: ${e.toString()}');
    }
  }

  // Get viewed history stats
  Future<ApiResponse<ViewedHistoryStats>> getViewedHistoryStats() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await get<Map<String, dynamic>>(
        '/UserViewedStats/$userId',
        fromJson: (json) => json,
      );
      
      if (response.isSuccess && response.data != null) {
        final stats = ViewedHistoryStats.fromJson(response.data!);
        return ApiResponse.success(stats);
      }
      
      return ApiResponse.error('Failed to get viewed history stats');
    } catch (e) {
      return ApiResponse.error('Failed to get viewed history stats: ${e.toString()}');
    }
  }
}

// Helper classes for viewed history
class ViewedSellerItem {
  final SellerDetails seller;
  final DateTime viewedAt;

  ViewedSellerItem({
    required this.seller,
    required this.viewedAt,
  });

  factory ViewedSellerItem.fromJson(Map<String, dynamic> json) {
    return ViewedSellerItem(
      seller: SellerDetails.fromJson(json['seller'] ?? json),
      viewedAt: DateTime.parse(json['viewedAt'] ?? json['dtstamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller': seller.toJson(),
      'viewedAt': viewedAt.toIso8601String(),
    };
  }
}

class ViewedProductItem {
  final Product product;
  final DateTime viewedAt;

  ViewedProductItem({
    required this.product,
    required this.viewedAt,
  });

  factory ViewedProductItem.fromJson(Map<String, dynamic> json) {
    return ViewedProductItem(
      product: Product.fromJson(json['product'] ?? json),
      viewedAt: DateTime.parse(json['viewedAt'] ?? json['dtstamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'viewedAt': viewedAt.toIso8601String(),
    };
  }
}

class ViewedHistoryResult {
  final List<ViewedSellerItem> sellers;
  final List<ViewedProductItem> products;
  final bool hasItems;

  ViewedHistoryResult({
    required this.sellers,
    required this.products,
    required this.hasItems,
  });

  int get totalSellerCount => sellers.length;
  int get totalProductCount => products.length;
  int get totalCount => totalSellerCount + totalProductCount;
  
  bool get hasSellerHistory => sellers.isNotEmpty;
  bool get hasProductHistory => products.isNotEmpty;
}

class ViewedHistoryStats {
  final int totalViewedSellers;
  final int totalViewedProducts;
  final int totalViews;
  final DateTime? lastViewedAt;
  final DateTime? firstViewedAt;

  ViewedHistoryStats({
    required this.totalViewedSellers,
    required this.totalViewedProducts,
    required this.totalViews,
    this.lastViewedAt,
    this.firstViewedAt,
  });

  factory ViewedHistoryStats.fromJson(Map<String, dynamic> json) {
    return ViewedHistoryStats(
      totalViewedSellers: json['totalViewedSellers'] ?? 0,
      totalViewedProducts: json['totalViewedProducts'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      lastViewedAt: json['lastViewedAt'] != null 
          ? DateTime.parse(json['lastViewedAt']) 
          : null,
      firstViewedAt: json['firstViewedAt'] != null 
          ? DateTime.parse(json['firstViewedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalViewedSellers': totalViewedSellers,
      'totalViewedProducts': totalViewedProducts,
      'totalViews': totalViews,
      'lastViewedAt': lastViewedAt?.toIso8601String(),
      'firstViewedAt': firstViewedAt?.toIso8601String(),
    };
  }
}

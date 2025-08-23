import 'package:get/get.dart';
import '../data/models/api/index.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import 'auth_service.dart';

class FavoritesService extends BaseApiService {
  final AuthService _authService = Get.find<AuthService>();

  // Add seller to favorites
  Future<ApiResponse<void>> addSellerToFavorites(int sellerId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Insert into users_saved_fav table with p_s = 'S' for seller
      final response = await post<void>(
        '/UserFavorite',
        body: {
          'userid': userId,
          'refid': sellerId,
          'p_s': 'S', // 'S' for seller, 'P' for product
          'active': true,
        },
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to add seller to favorites: ${e.toString()}');
    }
  }

  // Remove seller from favorites
  Future<ApiResponse<void>> removeSellerFromFavorites(int sellerId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Update users_saved_fav table to set active = false
      final response = await put<void>(
        '/UserFavorite',
        body: {
          'userid': userId,
          'refid': sellerId,
          'p_s': 'S',
          'active': false,
        },
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to remove seller from favorites: ${e.toString()}');
    }
  }

  // Add product to favorites
  Future<ApiResponse<void>> addProductToFavorites(int productId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Insert into users_saved_fav table with p_s = 'P' for product
      final response = await post<void>(
        '/UserFavorite',
        body: {
          'userid': userId,
          'refid': productId,
          'p_s': 'P', // 'P' for product
          'active': true,
        },
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to add product to favorites: ${e.toString()}');
    }
  }

  // Remove product from favorites
  Future<ApiResponse<void>> removeProductFromFavorites(int productId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Update users_saved_fav table to set active = false
      final response = await put<void>(
        '/UserFavorite',
        body: {
          'userid': userId,
          'refid': productId,
          'p_s': 'P',
          'active': false,
        },
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to remove product from favorites: ${e.toString()}');
    }
  }

  // Get user's favorite sellers with details
  Future<ApiResponse<List<SellerDetails>>> getFavoriteSellers() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await getList<SellerDetails>(
        '/UserFavoriteSellers/$userId',
        fromJson: (json) => SellerDetails.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get favorite sellers: ${e.toString()}');
    }
  }

  // Get user's favorite products with details
  Future<ApiResponse<List<Product>>> getFavoriteProducts() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await getList<Product>(
        '/UserFavoriteProducts/$userId',
        fromJson: (json) => Product.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get favorite products: ${e.toString()}');
    }
  }

  // Check if seller is in favorites
  Future<bool> isSellerFavorite(int sellerId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) return false;

    try {
      final response = await get<Map<String, dynamic>>(
        '/UserFavoriteCheck',
        queryParams: {
          'userid': userId.toString(),
          'refid': sellerId.toString(),
          'p_s': 'S',
        },
        fromJson: (json) => json,
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!['isFavorite'] as bool? ?? false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if product is in favorites
  Future<bool> isProductFavorite(int productId) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) return false;

    try {
      final response = await get<Map<String, dynamic>>(
        '/UserFavoriteCheck',
        queryParams: {
          'userid': userId.toString(),
          'refid': productId.toString(),
          'p_s': 'P',
        },
        fromJson: (json) => json,
      );
      
      if (response.isSuccess && response.data != null) {
        return response.data!['isFavorite'] as bool? ?? false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Toggle seller favorite status
  Future<ApiResponse<bool>> toggleSellerFavorite(int sellerId) async {
    final isFav = await isSellerFavorite(sellerId);
    
    if (isFav) {
      final response = await removeSellerFromFavorites(sellerId);
      return response.isSuccess 
          ? ApiResponse.success(false) 
          : ApiResponse.error(response.errorMessage ?? 'Failed to remove from favorites');
    } else {
      final response = await addSellerToFavorites(sellerId);
      return response.isSuccess 
          ? ApiResponse.success(true) 
          : ApiResponse.error(response.errorMessage ?? 'Failed to add to favorites');
    }
  }

  // Toggle product favorite status
  Future<ApiResponse<bool>> toggleProductFavorite(int productId) async {
    final isFav = await isProductFavorite(productId);
    
    if (isFav) {
      final response = await removeProductFromFavorites(productId);
      return response.isSuccess 
          ? ApiResponse.success(false) 
          : ApiResponse.error(response.errorMessage ?? 'Failed to remove from favorites');
    } else {
      final response = await addProductToFavorites(productId);
      return response.isSuccess 
          ? ApiResponse.success(true) 
          : ApiResponse.error(response.errorMessage ?? 'Failed to add to favorites');
    }
  }

  // Get favorites count
  Future<ApiResponse<FavoritesCount>> getFavoritesCount() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await get<Map<String, dynamic>>(
        '/UserFavoritesCount/$userId',
        fromJson: (json) => json,
      );
      
      if (response.isSuccess && response.data != null) {
        final count = FavoritesCount.fromJson(response.data!);
        return ApiResponse.success(count);
      }
      
      return ApiResponse.error('Failed to get favorites count');
    } catch (e) {
      return ApiResponse.error('Failed to get favorites count: ${e.toString()}');
    }
  }
}

// Helper class for favorites count
class FavoritesCount {
  final int sellersCount;
  final int productsCount;
  final int totalCount;

  FavoritesCount({
    required this.sellersCount,
    required this.productsCount,
    required this.totalCount,
  });

  factory FavoritesCount.fromJson(Map<String, dynamic> json) {
    return FavoritesCount(
      sellersCount: json['sellersCount'] ?? 0,
      productsCount: json['productsCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellersCount': sellersCount,
      'productsCount': productsCount,
      'totalCount': totalCount,
    };
  }
}

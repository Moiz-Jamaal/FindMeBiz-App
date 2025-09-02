import 'dart:async';
import 'package:get/get.dart';
import '../data/models/product.dart';
import '../data/models/api/index.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import 'api/api_exception.dart';

/// Unified Product Management Service
/// 
/// This service centralizes all product-related operations, eliminating redundancy
/// and providing a consistent API for fetching, caching, and managing products
/// across the entire application.
class UnifiedProductService extends GetxService {
  static UnifiedProductService get to => Get.find<UnifiedProductService>();
  
  final ProductService _productService = ProductService.instance;
  final AuthService _authService = Get.find<AuthService>();
  
  // In-memory cache for products with TTL
  final Map<String, _CachedProduct> _productCache = {};
  final Map<String, _CachedProductList> _productListCache = {};
  
  // Cache TTL configurations (in milliseconds)
  static const int _singleProductTTL = 5 * 60 * 1000; // 5 minutes
  static const int _productListTTL = 2 * 60 * 1000; // 2 minutes
  static const int _maxCacheSize = 100; // Maximum cached items
  
  @override
  void onInit() {
    super.onInit();
    // Clear cache periodically
    _startCacheCleanupTimer();
  }
  
  // =================== SINGLE PRODUCT OPERATIONS ===================
  
  /// Get a single product by ID with caching
  /// 
  /// This is the primary method for fetching individual products.
  /// Use this instead of calling ProductService.getProduct() or BuyerService.getProductDetails() directly.
  Future<ApiResponse<Product>> getProduct(int productId, {bool forceRefresh = false}) async {
    final cacheKey = 'product_$productId';
    
    // Check cache first (unless force refresh)
    if (!forceRefresh && _productCache.containsKey(cacheKey)) {
      final cached = _productCache[cacheKey]!;
      if (!cached.isExpired) {
        return ApiResponse.success(cached.product);
      } else {
        _productCache.remove(cacheKey);
      }
    }
    
    try {
      // Use the unified ProductService for product details
      final response = await _productService.getProductDetails(productId);
      
      if (response.isSuccess && response.data != null) {
        // Cache the result
        _cacheProduct(cacheKey, response.data!);
        return response;
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch product: $e');
    }
  }
  
  // =================== PRODUCT LIST OPERATIONS ===================
  
  /// Search products with unified filtering and caching
  /// 
  /// This is the primary method for searching/filtering products.
  /// Replaces all other product search methods.
  Future<ApiResponse<ProductSearchResponse>> searchProducts({
    String? query,
    int? sellerId,
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
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateListCacheKey(
      query: query,
      sellerId: sellerId,
      categoryIds: categoryIds,
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
    
    // Check cache first (unless force refresh)
    if (!forceRefresh && _productListCache.containsKey(cacheKey)) {
      final cached = _productListCache[cacheKey]!;
      if (!cached.isExpired) {
        return ApiResponse.success(cached.response);
      } else {
        _productListCache.remove(cacheKey);
      }
    }
    
    try {
      // Use ProductService for comprehensive search
      final response = await _productService.searchProducts(
        productName: query,
        sellerId: sellerId,
        categoryIds: categoryIds,
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
      
      if (response.isSuccess && response.data != null) {
        // Cache the result
        _cacheProductList(cacheKey, response.data!);
        
        // Also cache individual products from the list
        for (final product in response.data!.products) {
          final productCacheKey = 'product_${product.id}';
          _cacheProduct(productCacheKey, product);
        }
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to search products: $e');
    }
  }
  
  /// Get products by seller with caching
  /// 
  /// Optimized method for fetching seller's products
  Future<ApiResponse<ProductSearchResponse>> getProductsBySeller(
    int sellerId, {
    int page = 1,
    int pageSize = 20,
    String sortBy = 'createdat',
    String sortOrder = 'desc',
    bool forceRefresh = false,
  }) async {
    return searchProducts(
      sellerId: sellerId,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
      forceRefresh: forceRefresh,
    );
  }
  
  /// Get related products based on categories or seller
  Future<ApiResponse<List<Product>>> getRelatedProducts(
    int productId, {
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    try {
      // First get the main product to understand its categories and seller
      final productResponse = await getProduct(productId, forceRefresh: forceRefresh);
      
      if (!productResponse.isSuccess || productResponse.data == null) {
        return ApiResponse.error('Could not fetch product for related products');
      }
      
      final product = productResponse.data!;
      final sellerId = int.tryParse(product.sellerId);
      
      if (sellerId == null) {
        return ApiResponse.success([]);
      }
      
      // Get other products from the same seller
      final relatedResponse = await getProductsBySeller(
        sellerId,
        pageSize: limit + 1, // +1 to account for excluding current product
        forceRefresh: forceRefresh,
      );
      
      if (relatedResponse.isSuccess && relatedResponse.data != null) {
        // Filter out the current product and limit results
        final filtered = relatedResponse.data!.products
            .where((p) => p.id != product.id)
            .take(limit)
            .toList();
        
        return ApiResponse.success(filtered);
      }
      
      return ApiResponse.success([]);
    } catch (e) {
      return ApiResponse.error('Failed to fetch related products: $e');
    }
  }
  
  // =================== SELLER-SPECIFIC OPERATIONS ===================
  
  /// Get current seller's products (for seller dashboard)
  Future<ApiResponse<ProductSearchResponse>> getCurrentSellerProducts({
    int page = 1,
    int pageSize = 20,
    String sortBy = 'createdat',
    String sortOrder = 'desc',
    bool forceRefresh = false,
  }) async {
    final sellerId = _authService.currentSeller?.sellerid;
    
    if (sellerId == null) {
      return ApiResponse.error('No seller found. Please login again.');
    }
    
    // Use ProductService for seller's own products (has more permissions)
    final cacheKey = _generateListCacheKey(
      sellerId: sellerId,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    
    // Check cache first
    if (!forceRefresh && _productListCache.containsKey(cacheKey)) {
      final cached = _productListCache[cacheKey]!;
      if (!cached.isExpired) {
        return ApiResponse.success(cached.response);
      } else {
        _productListCache.remove(cacheKey);
      }
    }
    
    try {
      final response = await _productService.getProducts(
        sellerId: sellerId,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      
      if (response.isSuccess && response.data != null) {
        _cacheProductList(cacheKey, response.data!);
        
        // Cache individual products
        for (final product in response.data!.products) {
          final productCacheKey = 'product_${product.id}';
          _cacheProduct(productCacheKey, product);
        }
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch seller products: $e');
    }
  }
  
  // =================== CACHE MANAGEMENT ===================
  
  /// Clear all cached products
  void clearProductCache() {
    _productCache.clear();
    _productListCache.clear();
  }
  
  /// Clear cache for a specific product
  void clearProductFromCache(int productId) {
    final cacheKey = 'product_$productId';
    _productCache.remove(cacheKey);
    
    // Also clear any product lists that might contain this product
    _productListCache.removeWhere((key, cached) => 
      cached.response.products.any((p) => p.id == productId.toString()));
  }
  
  /// Clear cache for seller products
  void clearSellerProductsFromCache(int sellerId) {
    _productListCache.removeWhere((key, cached) => key.contains('sellerId_$sellerId'));
  }
  
  /// Force refresh a product and update cache
  Future<ApiResponse<Product>> refreshProduct(int productId) async {
    clearProductFromCache(productId);
    return getProduct(productId, forceRefresh: true);
  }
  
  // =================== UTILITY METHODS ===================
  
  /// Generate cache key for product lists
  String _generateListCacheKey({
    String? query,
    int? sellerId,
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
  }) {
    final keyParts = <String>[
      if (query != null) 'query_$query',
      if (sellerId != null) 'sellerId_$sellerId',
      if (categoryIds != null && categoryIds.isNotEmpty) 'cats_${categoryIds.join(',')}',
      if (minPrice != null) 'minPrice_$minPrice',
      if (maxPrice != null) 'maxPrice_$maxPrice',
      if (isAvailable != null) 'available_$isAvailable',
      if (city != null) 'city_$city',
      if (area != null) 'area_$area',
      'page_$page',
      'size_$pageSize',
      'sort_${sortBy}_$sortOrder',
    ];
    
    return keyParts.join('|');
  }
  
  /// Cache a single product
  void _cacheProduct(String key, Product product) {
    if (_productCache.length >= _maxCacheSize) {
      // Remove oldest entries
      final sortedEntries = _productCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      
      for (int i = 0; i < _maxCacheSize ~/ 4; i++) {
        _productCache.remove(sortedEntries[i].key);
      }
    }
    
    _productCache[key] = _CachedProduct(
      product: product,
      cachedAt: DateTime.now(),
    );
  }
  
  /// Cache a product list response
  void _cacheProductList(String key, ProductSearchResponse response) {
    if (_productListCache.length >= _maxCacheSize) {
      // Remove oldest entries
      final sortedEntries = _productListCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      
      for (int i = 0; i < _maxCacheSize ~/ 4; i++) {
        _productListCache.remove(sortedEntries[i].key);
      }
    }
    
    _productListCache[key] = _CachedProductList(
      response: response,
      cachedAt: DateTime.now(),
    );
  }
  
  /// Start periodic cache cleanup timer
  void _startCacheCleanupTimer() {
    // Clean cache every 10 minutes
    Timer.periodic(const Duration(minutes: 10), (_) {
      _cleanExpiredCache();
    });
  }
  
  /// Remove expired cache entries
  void _cleanExpiredCache() {
    _productCache.removeWhere((key, cached) => cached.isExpired);
    _productListCache.removeWhere((key, cached) => cached.isExpired);
  }
  
  // =================== STATISTICS & MONITORING ===================
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'productCacheSize': _productCache.length,
      'productListCacheSize': _productListCache.length,
      'totalCacheSize': _productCache.length + _productListCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }
}

// =================== INTERNAL CACHE CLASSES ===================

class _CachedProduct {
  final Product product;
  final DateTime cachedAt;
  
  _CachedProduct({
    required this.product,
    required this.cachedAt,
  });
  
  bool get isExpired => 
    DateTime.now().millisecondsSinceEpoch - cachedAt.millisecondsSinceEpoch > 
    UnifiedProductService._singleProductTTL;
}

class _CachedProductList {
  final ProductSearchResponse response;
  final DateTime cachedAt;
  
  _CachedProductList({
    required this.response,
    required this.cachedAt,
  });
  
  bool get isExpired => 
    DateTime.now().millisecondsSinceEpoch - cachedAt.millisecondsSinceEpoch > 
    UnifiedProductService._productListTTL;
}

// =================== IMPORT FIXES ===================

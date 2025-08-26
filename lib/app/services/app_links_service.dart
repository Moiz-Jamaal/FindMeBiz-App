import 'package:get/get.dart';
import 'package:flutter/services.dart';

/// Service to handle app links and deep linking for https://findmebiz.com
/// Supports both web and mobile app routing
class AppLinksService extends GetxService {
  static const String baseUrl = 'https://findmebiz.com';
  
  @override
  void onInit() {
    super.onInit();
    _initializeAppLinks();
  }

  /// Initialize app links handling
  void _initializeAppLinks() {
    // Listen to app links when app is running
    _handleIncomingLinks();
    
    // Handle app link when app is launched
    _handleInitialLink();
  }

  /// Handle incoming links while app is running
  void _handleIncomingLinks() {
    // This would typically use package like 'app_links' or 'uni_links'
    // For now, we'll set up the structure
  }

  /// Handle initial link when app is launched
  void _handleInitialLink() async {
    try {
      // Get initial link if app was opened via deep link
      // This would use platform-specific implementation
    } catch (e) {
      // Handle error silently
    }
  }

  /// Generate full app link URL from route
  String generateAppLink(String route, {Map<String, dynamic>? parameters}) {
    final uri = Uri.parse('$baseUrl$route');
    
    if (parameters != null && parameters.isNotEmpty) {
      final queryParams = parameters.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return uri.replace(queryParameters: queryParams).toString();
    }
    
    return uri.toString();
  }

  /// Parse app link URL and navigate to appropriate route
  Future<bool> handleAppLink(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // Only handle our domain
      if (uri.host != 'findmebiz.com') {
        return false;
      }

      final path = uri.path;
      final queryParams = uri.queryParameters;

      // Route to appropriate screen based on path
      return await _routeToScreen(path, queryParams);
    } catch (e) {
      return false;
    }
  }

  /// Route to appropriate screen based on path
  Future<bool> _routeToScreen(String path, Map<String, String> params) async {
    try {
      switch (path) {
        // Seller routes
        case '/seller':
          final sellerId = params['id'];
          if (sellerId != null) {
            Get.toNamed('/buyer-seller-view', arguments: int.tryParse(sellerId));
            return true;
          }
          break;

        // Product routes
        case '/product':
          final productId = params['id'];
          if (productId != null) {
            Get.toNamed('/buyer-product-view', arguments: int.tryParse(productId));
            return true;
          }
          break;

        // Category routes
        case '/category':
          final categoryId = params['id'];
          final categoryName = params['name'];
          if (categoryId != null) {
            Get.toNamed('/buyer-search', arguments: {
              'categoryId': int.tryParse(categoryId),
              'categoryName': categoryName,
            });
            return true;
          }
          break;

        // Search routes
        case '/search':
          final query = params['q'];
          Get.toNamed('/buyer-search', arguments: {
            if (query != null) 'query': query,
            ...params,
          });
          return true;

        // Home route
        case '/':
        case '/home':
          Get.toNamed('/buyer-home');
          return true;

        // Default: try direct route mapping
        default:
          try {
            Get.toNamed(path, arguments: params);
            return true;
          } catch (e) {
            // Route doesn't exist or navigation failed
            return false;
          }
      }
    } catch (e) {
      // Handle error silently
    }

    return false;
  }

  /// Generate seller profile link by username
  String generateSellerLinkByUsername(String username) {
    return '$baseUrl/@$username';
  }

  /// Generate seller profile link
  String generateSellerLink(int sellerId, {String? sellerName}) {
    final params = <String, dynamic>{'id': sellerId.toString()};
    if (sellerName != null) {
      params['name'] = sellerName;
    }
    return generateAppLink('/seller', parameters: params);
  }

  /// Generate product link
  String generateProductLink(int productId, {String? productName}) {
    final params = <String, dynamic>{'id': productId.toString()};
    if (productName != null) {
      params['name'] = productName;
    }
    return generateAppLink('/product', parameters: params);
  }

  /// Generate category link
  String generateCategoryLink(int categoryId, {String? categoryName}) {
    final params = <String, dynamic>{'id': categoryId.toString()};
    if (categoryName != null) {
      params['name'] = categoryName;
    }
    return generateAppLink('/category', parameters: params);
  }

  /// Generate search link
  String generateSearchLink({
    String? query,
    int? categoryId,
    String? location,
  }) {
    final params = <String, dynamic>{};
    if (query != null) params['q'] = query;
    if (categoryId != null) params['category'] = categoryId.toString();
    if (location != null) params['location'] = location;
    
    return generateAppLink('/search', parameters: params);
  }

  /// Share seller via app link
  Future<void> shareSeller(int sellerId, String sellerName) async {
    final link = generateSellerLink(sellerId, sellerName: sellerName);
    await _shareLink(link, 'Check out $sellerName on FindMeBiz');
  }

  /// Share product via app link
  Future<void> shareProduct(int productId, String productName) async {
    final link = generateProductLink(productId, productName: productName);
    await _shareLink(link, 'Check out $productName on FindMeBiz');
  }

  /// Generic share function
  Future<void> _shareLink(String link, String text) async {
    try {
      // This would use share_plus package
      // await Share.share('$text\n\n$link');
    } catch (e) {
      // Handle error - could copy to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: link));
    }
  }
}
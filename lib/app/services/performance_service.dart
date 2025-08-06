import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PerformanceService extends GetxService {
  static PerformanceService get to => Get.find();

  // Performance metrics
  final RxInt totalApiCalls = 0.obs;
  final RxInt cachedResponses = 0.obs;
  final RxDouble averageLoadTime = 0.0.obs;
  
  // Cache management
  final Map<String, CacheItem> _cache = {};
  final Duration _defaultCacheExpiry = const Duration(minutes: 15);
  
  // Network optimization
  final RxBool isOfflineMode = false.obs;
  final RxBool hasSlowConnection = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializePerformanceMonitoring();
  }

  void _initializePerformanceMonitoring() {
    // Start monitoring app performance
    // Monitor theme changes if available
    try {
      // Listen to theme mode changes instead
      ever(RxBool(Get.isDarkMode).obs, (_) {
        _optimizeThemeTransitions();
      });
    } catch (e) {
      debugPrint('Theme monitoring not available: $e');
    }
  }

  /// Cache management for API responses
  Future<T?> getCachedData<T>(String key) async {
    final item = _cache[key];
    
    if (item != null && !item.isExpired) {
      cachedResponses.value++;
      return item.data as T?;
    }
    
    // Remove expired item
    if (item != null && item.isExpired) {
      _cache.remove(key);
    }
    
    return null;
  }

  void setCachedData<T>(String key, T data, {Duration? expiry}) {
    _cache[key] = CacheItem(
      data: data,
      timestamp: DateTime.now(),
      expiry: expiry ?? _defaultCacheExpiry,
    );
  }

  void clearCache() {
    _cache.clear();
    Get.snackbar(
      'Cache Cleared',
      'App cache has been cleared for better performance',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void clearExpiredCache() {
    _cache.removeWhere((key, item) => item.isExpired);
  }

  /// Image optimization helpers
  Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return placeholder ?? Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error, color: Colors.grey),
        );
      },
      // Optimize for mobile
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  /// List performance optimization
  Widget optimizedListBuilder({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Performance optimizations
      cacheExtent: 500.0, // Pre-cache more items
      addAutomaticKeepAlives: false, // Don't keep all items alive
      addRepaintBoundaries: true, // Optimize repaints
    );
  }

  /// Memory management
  void optimizeMemoryUsage() {
    // Clear expired cache
    clearExpiredCache();
    
    // Force garbage collection (Android/iOS will handle this)
    // This is more for monitoring than actual optimization
    debugPrint('Memory optimization triggered');
  }

  /// Network request optimization
  Future<T> optimizedApiCall<T>({
    required Future<T> Function() apiCall,
    required String cacheKey,
    Duration? cacheExpiry,
    bool forceRefresh = false,
  }) async {
    final startTime = DateTime.now();
    
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await getCachedData<T>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    try {
      totalApiCalls.value++;
      
      // Make API call
      final result = await apiCall();
      
      // Cache the result
      setCachedData(cacheKey, result, expiry: cacheExpiry);
      
      // Update performance metrics
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      _updateAverageLoadTime(loadTime.toDouble());
      
      return result;
    } catch (e) {
      // Handle network errors gracefully
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        hasSlowConnection.value = true;
        
        // Try to return cached data even if expired
        final cachedData = _cache[cacheKey]?.data as T?;
        if (cachedData != null) {
          Get.snackbar(
            'Offline Mode',
            'Showing cached data due to network issues',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return cachedData;
        }
      }
      
      rethrow;
    }
  }

  void _updateAverageLoadTime(double newTime) {
    if (averageLoadTime.value == 0) {
      averageLoadTime.value = newTime;
    } else {
      // Simple moving average
      averageLoadTime.value = (averageLoadTime.value + newTime) / 2;
    }
  }

  /// Theme transition optimization
  void _optimizeThemeTransitions() {
    // Add smooth theme transitions
    Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  /// App startup optimization
  Future<void> preloadCriticalData() async {
    try {
      // Preload categories
      await optimizedApiCall(
        apiCall: () async {
          // Simulate loading categories
          await Future.delayed(const Duration(milliseconds: 500));
          return ['Apparel', 'Jewelry', 'Food', 'Crafts', 'Electronics'];
        },
        cacheKey: 'categories',
        cacheExpiry: const Duration(hours: 24),
      );
      
      // Preload featured sellers
      await optimizedApiCall(
        apiCall: () async {
          // Simulate loading featured sellers
          await Future.delayed(const Duration(milliseconds: 800));
          return ['seller1', 'seller2', 'seller3'];
        },
        cacheKey: 'featured_sellers',
        cacheExpiry: const Duration(hours: 1),
      );
      
    } catch (e) {
      debugPrint('Error preloading critical data: $e');
    }
  }

  /// UI performance helpers
  Widget performantContainer({
    required Widget child,
    Color? color,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
    double? width,
    double? height,
  }) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: decoration,
        child: child,
      ),
    );
  }

  /// Error handling optimization
  void handleError(dynamic error, {String? context}) {
    debugPrint('Error in $context: $error');
    
    // Show user-friendly error message
    if (error.toString().contains('network') || 
        error.toString().contains('connection')) {
      Get.snackbar(
        'Connection Issue',
        'Please check your internet connection and try again',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Something went wrong',
        'Please try again in a moment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'totalApiCalls': totalApiCalls.value,
      'cachedResponses': cachedResponses.value,
      'cacheHitRate': totalApiCalls.value > 0 
          ? (cachedResponses.value / totalApiCalls.value * 100).toStringAsFixed(1)
          : '0.0',
      'averageLoadTime': '${averageLoadTime.value.toStringAsFixed(0)}ms',
      'cacheSize': _cache.length,
      'isOfflineMode': isOfflineMode.value,
      'hasSlowConnection': hasSlowConnection.value,
    };
  }

  void showPerformanceReport() {
    final metrics = getPerformanceMetrics();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Performance Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('API Calls: ${metrics['totalApiCalls']}'),
              Text('Cached Responses: ${metrics['cachedResponses']}'),
              Text('Cache Hit Rate: ${metrics['cacheHitRate']}%'),
              Text('Average Load Time: ${metrics['averageLoadTime']}'),
              Text('Cache Size: ${metrics['cacheSize']} items'),
              const SizedBox(height: 16),
              const Text(
                'Performance Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Clear cache regularly for optimal performance'),
              const Text('• Use Wi-Fi for better loading speeds'),
              const Text('• Close unused apps to free memory'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: clearCache,
            child: const Text('Clear Cache'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class CacheItem {
  final dynamic data;
  final DateTime timestamp;
  final Duration expiry;

  CacheItem({
    required this.data,
    required this.timestamp,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().isAfter(timestamp.add(expiry));
}
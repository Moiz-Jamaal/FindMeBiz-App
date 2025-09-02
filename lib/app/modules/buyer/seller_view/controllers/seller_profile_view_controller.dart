import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/services/api/api_exception.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/seller.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/api/seller_details.dart';
import '../../../../services/buyer_service.dart';
import '../../../../services/product_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class SellerProfileViewController extends GetxController {
  // Services
  final ProductService _productService = ProductService.instance;
  
  // Seller data
  final Rx<Seller?> seller = Rx<Seller?>(null);
  final RxList<Product> products = <Product>[].obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isFavorite = false.obs;
  final RxInt selectedProductCategory = 0.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Product categories for this seller
  final RxList<String> sellerCategories = <String>[].obs;
  
  // Interaction tracking
  final RxBool hasContacted = false.obs;
  final RxBool hasViewed = false.obs;
  
  // Review data
  final RxDouble averageRating = 0.0.obs;
  final RxInt totalReviews = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Use post-frame callback to avoid build context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSellerData();
    });
  }

  void loadSellerData() {
    _loadSellerData();
  }

  void _setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
    isLoading.value = false;
  }

  void _clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }

  void retryLoading() {
    _clearError();
    _loadSellerData();
  }

  void _loadSellerData() {
    _clearError();
    isLoading.value = true;
    
    // Get seller from arguments
    final sellerData = Get.arguments;
    
    
    if (sellerData is Seller) {
      // Full seller object passed (e.g., from search)
      
      seller.value = sellerData;
      _loadSellerProducts();
      _checkIfFavorite();
      _markAsViewed();
      _trackSellerView();
      _loadReviewSummary();
      isLoading.value = false;
    } else if (sellerData is String) {
      // Only seller ID passed (e.g., from home)
      
      _loadSellerById(sellerData);
    } else if (sellerData is int) {
      // Seller ID as int
      
      _loadSellerById(sellerData.toString());
    } else {
      // No valid data provided
      
      _setError('Unable to load seller information. Invalid data provided.');
    }
  }

  void _loadSellerById(String sellerId) {
    isLoading.value = true;
    
    
    // Use actual API service to fetch seller details
    final sellerIdInt = int.tryParse(sellerId);
    
    if (sellerIdInt == null) {
      
      _setError('Invalid seller ID. Please try again.');
      return;
    }
    
    // Try the new API endpoint first (searches by sellerId)
    _productService.getSellerDetailsBySellerId(sellerIdInt).then((response) {
      if (response.isSuccess && response.data != null) {
        
        
        // Convert SellerDetailsExtended to Seller model
        final sellerData = _convertToSellerModel(response.data!);
        seller.value = sellerData;
        _loadSellerProducts();
        _checkIfFavorite();
        _markAsViewed();
        _trackSellerView();
        _loadReviewSummary();
        isLoading.value = false;
      } else {
        
        _setError(response.errorMessage ?? 'Failed to load seller information. Please try again.');
      }
    }).catchError((e) {
      
      _setError('Network error. Please check your connection and try again.');
    });
  }

  // Convert SellerDetailsExtended to Seller model
  Seller _convertToSellerModel(SellerDetailsExtended sellerDetailsExtended) {
    return Seller(
      id: sellerDetailsExtended.sellerid?.toString() ?? '0',
      email: '', // Email is not available in SellerDetails API model
      fullName: sellerDetailsExtended.profilename ?? 'Business Owner',
      createdAt: DateTime.now().subtract(const Duration(days: 30)), // TODO: Use actual created date from API
      updatedAt: DateTime.now(),
      businessName: sellerDetailsExtended.businessname ?? 'Local Business',
      bio: sellerDetailsExtended.bio ?? 'Welcome to our business!',
      whatsappNumber: sellerDetailsExtended.whatsappno ?? sellerDetailsExtended.mobileno,
      stallLocation: StallLocation(
        latitude: _parseLatitude(sellerDetailsExtended.geolocation),
        longitude: _parseLongitude(sellerDetailsExtended.geolocation),
        stallNumber: _generateStallNumber(sellerDetailsExtended.sellerid),
        area: sellerDetailsExtended.area ?? 'Business Area',
        address: sellerDetailsExtended.address,
      ),
      businessLogo: sellerDetailsExtended.logo, // This should now have fresh presigned URL
      isProfilePublished: sellerDetailsExtended.ispublished ?? true,
    );
  }

  // Helper method to parse latitude from geolocation string
  double _parseLatitude(String? geoLocation) {
    if (geoLocation == null || geoLocation.isEmpty) return 0.0;

      // Assuming geolocation format is "lat,lng" or similar
      final parts = geoLocation.split(',');
      if (parts.length >= 2) {
        return double.tryParse(parts[0].trim()) ?? 0.0;
      }
  
    return 0.0;
  }

  // Helper method to parse longitude from geolocation string
  double _parseLongitude(String? geoLocation) {
    if (geoLocation == null || geoLocation.isEmpty) return 0.0;

      // Assuming geolocation format is "lat,lng" or similar
      final parts = geoLocation.split(',');
      if (parts.length >= 2) {
        return double.tryParse(parts[1].trim()) ?? 0.0;
      }
   
    return 0.0;
  }

  // Helper method to generate stall number from seller ID
  String _generateStallNumber(dynamic sellerId) {
    if (sellerId == null) return 'A-00';
    final idStr = sellerId.toString();
    if (idStr.length >= 2) {
      return 'A-${idStr.substring(0, 2)}';
    }
    return 'A-${idStr.padLeft(2, '0')}';
  }

  void _loadSellerProducts() {
    if (seller.value == null) return;
    
    
    
    // Use actual API service to fetch seller's products
    final sellerIdInt = int.tryParse(seller.value!.id);
    
    if (sellerIdInt == null) {
      
      // Don't load any products if seller ID is invalid
      products.clear();
      _extractProductCategories();
      return;
    }
    
    _productService.searchProducts(
      sellerId: sellerIdInt,
      pageSize: 50, // Get more products for seller profile
    ).then((response) {
      if (response.isSuccess && response.data != null) {
        print('=== PRODUCTS & MEDIA DEBUG ===');
        print('Total products received: ${response.data!.products.length}');
        
        for (int i = 0; i < response.data!.products.length; i++) {
          final product = response.data!.products[i];
          print('Product $i: ${product.name} (ID: ${product.id})');
          print('  - Media count: ${product.media?.length ?? 0}');
          print('  - Images count: ${product.images.length}');
          if (product.media?.isNotEmpty == true) {
            print('  - First media URL: ${product.media!.first.mediaUrl}');
          }
          print('  - Primary image URL: ${product.primaryImageUrl}');
          print('  - Categories: ${product.categories}');
        }
        
        products.clear();
        products.addAll(response.data!.products);
        _extractProductCategories();
        
        print('=== AFTER ADDING TO PRODUCTS LIST ===');
        print('Total products in controller: ${products.length}');
        for (int i = 0; i < products.length; i++) {
          final product = products[i];
          print('Controller Product $i: ${product.name} (ID: ${product.id})');
          print('  - Media count: ${product.media?.length ?? 0}');
          print('  - Primary image URL: ${product.primaryImageUrl}');
        }
        
        print('=== FILTERED PRODUCTS ===');
        print('Filtered products count: ${filteredProducts.length}');
        for (int i = 0; i < filteredProducts.length; i++) {
          final product = filteredProducts[i];
          print('Filtered Product $i: ${product.name} (ID: ${product.id})');
          print('  - Media count: ${product.media?.length ?? 0}');
          print('  - Primary image URL: ${product.primaryImageUrl}');
        }
        print('=== END DEBUG ===');
      } else {
        // Clear products if API call fails - no fallback to mock data
        products.clear();
        _extractProductCategories();
      }
    }).catchError((e) {
      // Clear products if API call fails - no fallback to mock data
      products.clear();
      _extractProductCategories();
    });
  }

  void _extractProductCategories() {
    final categories = <String>{'All'};
    for (final product in products) {
      categories.addAll(product.categories);
    }
    sellerCategories.clear();
    sellerCategories.addAll(categories.toList());
  }

  void _checkIfFavorite() {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null || seller.value?.id == null) {
      isFavorite.value = false;
      return;
    }
    
    final sellerId = int.tryParse(seller.value!.id);
    if (sellerId == null) {
      isFavorite.value = false;
      return;
    }
    
    _productService.checkIfSellerFavorite(
      userId: currentUser!.userid!,
      sellerId: sellerId,
    ).then((response) {
      if (response.isSuccess && response.data != null) {
        isFavorite.value = response.data!['isFavorite'] == true;
        
      } else {
        isFavorite.value = false;
        
      }
    }).catchError((e) {
      isFavorite.value = false;
      
    });
  }

  void _markAsViewed() {
    if (!hasViewed.value) {
      hasViewed.value = true;
      // TODO: Track this view for analytics via API
    }
  }

  void _loadReviewSummary() async {
    if (seller.value?.id == null) return;
    
    final sellerId = int.tryParse(seller.value!.id);
    if (sellerId == null) return;
    
    try {
      final buyerService = Get.find<BuyerService>();
      final response = await buyerService.getSellerReviewSummary(sellerId);
      
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Handle statistics from API response structure
        final apiRating = (data['averageRating'] ?? data['avgSellerRating'] ?? 0.0).toDouble();
        final apiReviews = data['totalReviews'] ?? data['totalSellerReviews'] ?? 0;
        
        // Use API data if valid, otherwise calculate from individual reviews
        if (apiRating > 0 || apiReviews > 0) {
          averageRating.value = apiRating;
          totalReviews.value = apiReviews;
        } else {
          // Fallback: calculate from individual reviews
          await _calculateReviewSummaryFromReviews(sellerId);
        }
      } else {
        // Fallback: calculate from individual reviews
        await _calculateReviewSummaryFromReviews(sellerId);
      }
    } catch (e) {
      // Fallback: calculate from individual reviews
      await _calculateReviewSummaryFromReviews(sellerId);
    }
  }

  Future<void> _calculateReviewSummaryFromReviews(int sellerId) async {
    try {
      final buyerService = Get.find<BuyerService>();
      final response = await buyerService.getSellerReviews(sellerId);
      
      if (response.isSuccess && response.data != null) {
        final reviews = List<Map<String, dynamic>>.from(response.data ?? []);
        
        if (reviews.isEmpty) {
          averageRating.value = 0.0;
          totalReviews.value = 0;
          return;
        }
        
        // Calculate average rating from individual reviews
        double totalRating = 0.0;
        for (final review in reviews) {
          final rating = review['rating'] ?? review['sellerRating'] ?? review['productRating'] ?? 0;
          totalRating += rating.toDouble();
        }
        
        final calculatedAverage = totalRating / reviews.length;
        averageRating.value = calculatedAverage;
        totalReviews.value = reviews.length;
        
      } else {
        averageRating.value = 0.0;
        totalReviews.value = 0;
      }
    } catch (e) {
      averageRating.value = 0.0;
      totalReviews.value = 0;
    }
  }

  void _trackSellerView() {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null || seller.value?.id == null) {
      return; // Don't track if user not logged in or no seller
    }
    
    final sellerId = int.tryParse(seller.value!.id);
    if (sellerId == null) return;
    
    _productService.trackSellerView(
      userId: currentUser!.userid!,
      sellerId: sellerId,
    ).then((response) {
      if (response.isSuccess) {
        
      } else {
        
      }
    }).catchError((e) {
      
    });
  }

  void toggleFavorite() {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null) {
      Get.snackbar(
        'Login Required',
        'Please login to add sellers to favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    if (seller.value?.id == null) {
      Get.snackbar(
        'Error',
        'Unable to favorite this seller',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    final sellerId = int.tryParse(seller.value!.id);
    if (sellerId == null) {
      Get.snackbar(
        'Error',
        'Invalid seller information',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Optimistically update UI
    final wasAlreadyFavorite = isFavorite.value;
    isFavorite.value = !isFavorite.value;
    
    Future<ApiResponse<Map<String, dynamic>>> apiCall;
    if (wasAlreadyFavorite) {
      // Remove from favorites
      apiCall = _productService.removeSellerFromFavorites(
        userId: currentUser!.userid!,
        sellerId: sellerId,
      );
    } else {
      // Add to favorites
      apiCall = _productService.addSellerToFavorites(
        userId: currentUser!.userid!,
        sellerId: sellerId,
      );
    }
    
    apiCall.then((response) {
      if (response.isSuccess) {
        final message = isFavorite.value 
            ? 'Added to favorites'
            : 'Removed from favorites';
        
        Get.snackbar(
          'Favorites',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: isFavorite.value 
              ? AppTheme.buyerPrimary.withValues(alpha: 0.9)
              : Colors.grey.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        
        
      } else {
        // Revert optimistic update on failure
        isFavorite.value = wasAlreadyFavorite;
        Get.snackbar(
          'Error',
          'Failed to update favorites. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        
      }
    }).catchError((e) {
      // Revert optimistic update on error
      isFavorite.value = wasAlreadyFavorite;
      Get.snackbar(
        'Error',
        'Network error. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      
    });
  }

  void contactSeller() {
    final seller = this.seller.value!;
    final phoneNumber = seller.whatsappNumber ?? seller.phoneNumber;
    
    if (phoneNumber == null) {
      Get.snackbar(
        'Contact Info',
        'No contact information available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    hasContacted.value = true;
    _launchPhoneDialer(phoneNumber);
  }

  void _launchPhoneDialer(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = 'tel:$cleanNumber';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      Get.snackbar(
        'Phone Call',
        'Could not open phone dialer',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  

  void getDirections() {
    if (seller.value?.stallLocation == null) {
      Get.snackbar(
        'Location',
        'Stall location not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final location = seller.value!.stallLocation!;
    _launchMaps(location.latitude, location.longitude);
  }

  void _launchMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      Get.snackbar(
        'Google Maps',
        'Could not open Google Maps',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  

  void filterProductsByCategory(int categoryIndex) {
    selectedProductCategory.value = categoryIndex;
  }

  List<Product> get filteredProducts {
    if (selectedProductCategory.value == 0) {
      return products; // "All" category
    }
    
    final categoryName = sellerCategories[selectedProductCategory.value];
    return products.where((product) => 
        categoryName == 'All' || product.categories.contains(categoryName)).toList();
  }

  void viewProduct(Product product) {
    // Track view before navigation
    _trackProductViewFromSeller(product);
    Get.toNamed('/buyer-product-view', arguments: product);
  }

  void _trackProductViewFromSeller(Product product) {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null) return;
    
    final productId = int.tryParse(product.id);
    if (productId == null) return;
    
    _productService.trackProductView(
      userId: currentUser!.userid!,
      productId: productId,
    ).then((response) {
      if (response.isSuccess) {
        
      }
    }).catchError((e) {
      
    });
  }

  void shareProfile() {
    // TODO: Generate shareable link via API
    Get.snackbar(
      'Share',
      'Profile link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void reportProfile() {
    Get.dialog(
      AlertDialog(
        title: const Text('Report Profile'),
        content: const Text('Are you sure you want to report this profile?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Send report to API
              Get.snackbar(
                'Reported',
                'Profile has been reported for review',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

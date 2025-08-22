import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/services/api/api_exception.dart';
// import 'package:url_launcher/url_launcher.dart'; // Add this dependency to pubspec.yaml
import '../../../../data/models/seller.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/api/seller_details.dart';
import '../../../../services/buyer_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';

class SellerProfileViewController extends GetxController {
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
    print('🔍 SellerProfileViewController: Received arguments: $sellerData (type: ${sellerData.runtimeType})');
    
    if (sellerData is Seller) {
      // Full seller object passed (e.g., from search)
      print('✅ SellerProfileViewController: Loading seller object directly');
      seller.value = sellerData;
      _loadSellerProducts();
      _checkIfFavorite();
      _markAsViewed();
      isLoading.value = false;
    } else if (sellerData is String) {
      // Only seller ID passed (e.g., from home)
      print('✅ SellerProfileViewController: Loading seller by string ID: $sellerData');
      _loadSellerById(sellerData);
    } else if (sellerData is int) {
      // Seller ID as int
      print('✅ SellerProfileViewController: Loading seller by int ID: $sellerData');
      _loadSellerById(sellerData.toString());
    } else {
      // No valid data provided
      print('❌ SellerProfileViewController: Invalid data provided - $sellerData');
      _setError('Unable to load seller information. Invalid data provided.');
    }
  }

  void _loadSellerById(String sellerId) {
    isLoading.value = true;
    print('🔄 SellerProfileViewController: Loading seller by ID: $sellerId');
    
    // Use actual API service to fetch seller details
    final buyerService = Get.find<BuyerService>();
    final sellerIdInt = int.tryParse(sellerId);
    
    if (sellerIdInt == null) {
      print('❌ SellerProfileViewController: Invalid seller ID format: $sellerId');
      _setError('Invalid seller ID. Please try again.');
      return;
    }
    
    // Try the new API endpoint first (searches by sellerId)
    buyerService.getSellerDetailsBySellerId(sellerIdInt).then((response) {
      if (response.isSuccess && response.data != null) {
        print('✅ SellerProfileViewController: Seller data loaded from sellerId API successfully');
        
        // Convert SellerDetailsExtended to Seller model
        final sellerData = _convertToSellerModel(response.data!);
        seller.value = sellerData;
        _loadSellerProducts();
        _checkIfFavorite();
        _markAsViewed();
        isLoading.value = false;
      } else {
        print('❌ SellerProfileViewController: API call failed: ${response.errorMessage}');
        _setError(response.errorMessage ?? 'Failed to load seller information. Please try again.');
      }
    }).catchError((e) {
      print('❌ SellerProfileViewController: Exception during API call: $e');
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
    try {
      // Assuming geolocation format is "lat,lng" or similar
      final parts = geoLocation.split(',');
      if (parts.length >= 2) {
        return double.tryParse(parts[0].trim()) ?? 0.0;
      }
    } catch (e) {
      print('Error parsing latitude from: $geoLocation');
    }
    return 0.0;
  }

  // Helper method to parse longitude from geolocation string
  double _parseLongitude(String? geoLocation) {
    if (geoLocation == null || geoLocation.isEmpty) return 0.0;
    try {
      // Assuming geolocation format is "lat,lng" or similar
      final parts = geoLocation.split(',');
      if (parts.length >= 2) {
        return double.tryParse(parts[1].trim()) ?? 0.0;
      }
    } catch (e) {
      print('Error parsing longitude from: $geoLocation');
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
    
    print('🔄 SellerProfileViewController: Loading products for seller ID: ${seller.value!.id}');
    
    // Use actual API service to fetch seller's products
    final buyerService = Get.find<BuyerService>();
    final sellerIdInt = int.tryParse(seller.value!.id);
    
    if (sellerIdInt == null) {
      print('❌ SellerProfileViewController: Invalid seller ID for products: ${seller.value!.id}');
      // Don't load any products if seller ID is invalid
      products.clear();
      _extractProductCategories();
      return;
    }
    
    buyerService.searchProducts(
      sellerId: sellerIdInt,
      pageSize: 50, // Get more products for seller profile
    ).then((response) {
      if (response.isSuccess && response.data != null) {
        print('✅ SellerProfileViewController: Products loaded from API successfully (${response.data!.products.length} products)');
        products.clear();
        products.addAll(response.data!.products);
        _extractProductCategories();
      } else {
        print('❌ SellerProfileViewController: Failed to load products from API: ${response.errorMessage}');
        // Clear products if API call fails - no fallback to mock data
        products.clear();
        _extractProductCategories();
      }
    }).catchError((e) {
      print('❌ SellerProfileViewController: Exception during products API call: $e');
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
    
    final buyerService = Get.find<BuyerService>();
    buyerService.checkIfFavorite(
      userId: currentUser!.userid!,
      refId: sellerId,
      type: 'S', // 'S' for seller
    ).then((response) {
      if (response.isSuccess && response.data != null) {
        isFavorite.value = response.data!['isFavorite'] == true;
        print('✅ Seller favorite status loaded: ${isFavorite.value}');
      } else {
        isFavorite.value = false;
        print('❌ Failed to check seller favorite status: ${response.errorMessage}');
      }
    }).catchError((e) {
      isFavorite.value = false;
      print('❌ Exception checking seller favorite status: $e');
    });
  }

  void _markAsViewed() {
    if (!hasViewed.value) {
      hasViewed.value = true;
      // TODO: Track this view for analytics via API
    }
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
    
    final buyerService = Get.find<BuyerService>();
    
    Future<ApiResponse<Map<String, dynamic>>> apiCall;
    if (wasAlreadyFavorite) {
      // Remove from favorites
      apiCall = buyerService.removeFromFavorites(
        userId: currentUser!.userid!,
        refId: sellerId,
        type: 'S',
      );
    } else {
      // Add to favorites
      apiCall = buyerService.addToFavorites(
        userId: currentUser!.userid!,
        refId: sellerId,
        type: 'S',
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
              ? AppTheme.buyerPrimary.withOpacity(0.9)
              : Colors.grey.withOpacity(0.9),
          colorText: Colors.white,
        );
        
        print('✅ Seller favorite status updated successfully: ${isFavorite.value}');
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
        print('❌ Failed to update seller favorite status: ${response.errorMessage}');
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
      print('❌ Exception updating seller favorite status: $e');
    });
  }

  void contactSeller() {
    if (seller.value?.whatsappNumber == null) {
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
    _launchWhatsApp();
  }

  void _launchWhatsApp() async {
    final seller = this.seller.value!;
    
    // Placeholder implementation - In real app, add url_launcher dependency
    Get.snackbar(
      'WhatsApp',
      'Opening WhatsApp to contact ${seller.businessName}...\nNumber: ${seller.whatsappNumber}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    
    // TODO: Uncomment when url_launcher is added to pubspec.yaml
    /*
    const message = 'Hi, I found your profile on FindMeBiz and I\'m interested in your products.';
    final whatsappNumber = seller.whatsappNumber!.replaceAll(RegExp(r'[^\d]'), '');
    final url = 'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showContactAlternatives();
      }
    } catch (e) {
      _showContactAlternatives();
    }
    */
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
    // Placeholder implementation - In real app, add url_launcher dependency
    Get.snackbar(
      'Maps',
      'Opening maps for location: $lat, $lng',
      snackPosition: SnackPosition.BOTTOM,
    );
    
    // TODO: Uncomment when url_launcher is added to pubspec.yaml
    /*
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Maps',
        'Could not open maps',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    */
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
    Get.toNamed('/buyer-product-view', arguments: product);
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

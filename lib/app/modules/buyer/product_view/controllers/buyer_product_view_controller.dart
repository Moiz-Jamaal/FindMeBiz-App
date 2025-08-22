import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/data/models/product.dart';
import 'package:souq/app/data/models/seller.dart';
import 'package:souq/app/data/models/api/seller_details.dart';
import 'package:souq/app/services/api/api_exception.dart';
import 'package:souq/app/services/buyer_service.dart';
import 'package:souq/app/services/auth_service.dart';

import '../../../../core/theme/app_theme.dart';

class BuyerProductViewController extends GetxController {
  // Product data
  final Rx<Product?> product = Rx<Product?>(null);
  final Rx<Seller?> seller = Rx<Seller?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isFavorite = false.obs;
  
  // Error handling
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Product images
  final RxList<String> productImages = <String>[].obs;
  final RxInt currentImageIndex = 0.obs;
  
  // Related products
  final RxList<Product> relatedProducts = <Product>[].obs;
  
  // UI state
  final RxBool showFullDescription = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Use post-frame callback to avoid build context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductData();
    });
  }

  void _loadProductData() {
    final productArg = Get.arguments;
    print('🔍 BuyerProductViewController: Received arguments: $productArg (type: ${productArg.runtimeType})');
    
    if (productArg is Product) {
      // Full product object passed
      print('✅ BuyerProductViewController: Loading full product object');
      product.value = productArg;
      _loadProductDetails();
    } else if (productArg is int && productArg > 0) {
      // Product ID as int
      print('✅ BuyerProductViewController: Loading product by int ID: $productArg');
      _loadProductById(productArg.toString());
    } else if (productArg is String && productArg.isNotEmpty) {
      // Product ID as string
      final productId = int.tryParse(productArg);
      if (productId != null && productId > 0) {
        print('✅ BuyerProductViewController: Loading product by string ID: $productArg');
        _loadProductById(productArg);
      } else {
        print('❌ BuyerProductViewController: Invalid string product ID: $productArg');
        _setError('Invalid product ID format. Please try again.');
      }
    } else {
      // Invalid data provided
      print('❌ BuyerProductViewController: Invalid data provided - $productArg');
      _setError('Product information is missing or invalid. Please try selecting the product again.');
    }
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
    _loadProductData();
  }

  void _loadProductById(String productId) {
    isLoading.value = true;
    _clearError();
    
    print('🔄 BuyerProductViewController: Loading product by ID: $productId');
    
    // Use the buyer service to load product details
    final buyerService = Get.find<BuyerService>();
    final productIdInt = int.tryParse(productId);
    
    if (productIdInt == null) {
      print('❌ BuyerProductViewController: Invalid product ID format: $productId');
      _setError('Invalid product ID format. Please try again.');
      return;
    }
    
    buyerService.getProductDetails(productIdInt).then((response) {
      if (response.isSuccess && response.data != null) {
        print('✅ BuyerProductViewController: Product data loaded successfully');
        product.value = response.data;
        _loadProductDetails();
      } else {
        print('❌ BuyerProductViewController: API call failed: ${response.errorMessage}');
        _setError(response.errorMessage ?? 'Product not found. It may have been removed or is no longer available.');
      }
    }).catchError((e) {
      print('❌ BuyerProductViewController: Exception during API call: $e');
      _setError('Network error. Please check your connection and try again.');
    });
  }
  

  void _loadProductDetails() {
    if (product.value == null) return;
    
    isLoading.value = true;
    
    try {
      // Check if seller info is already included in product response
      if (product.value?.seller != null) {
        print('✅ BuyerProductViewController: Using seller data from product response');
        seller.value = _convertSellerInfoToSeller(product.value!.seller!);
      } else {
        // Fallback: try to load seller info via separate API call
        print('🔄 BuyerProductViewController: Seller not in product response, loading separately');
        _loadSellerInfo();
      }
      
      // Load product images
      _loadProductImages();
      
      // Load related products via API
      _loadRelatedProducts();
      
      // Check if favorited by current user
      _checkIfFavorited();
      
      isLoading.value = false;
    } catch (e) {
      _setError('Failed to load product information');
    }
  }

  void _checkIfFavorited() {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null || product.value?.id == null) {
      isFavorite.value = false;
      return;
    }
    
    final productId = int.tryParse(product.value!.id);
    if (productId == null) {
      isFavorite.value = false;
      return;
    }
    
    final buyerService = Get.find<BuyerService>();
    buyerService.checkIfFavorite(
      userId: currentUser!.userid!,
      refId: productId,
      type: 'P',
    ).then((response) {
      if (response.isSuccess && response.data != null) {
        isFavorite.value = response.data!['isFavorite'] == true;
        print('✅ Favorite status loaded: ${isFavorite.value}');
      } else {
        isFavorite.value = false;
        print('❌ Failed to check favorite status: ${response.errorMessage}');
      }
    }).catchError((e) {
      isFavorite.value = false;
      print('❌ Exception checking favorite status: $e');
    });
  }

  // Convert SellerInfo from product API response to Seller model
  Seller _convertSellerInfoToSeller(dynamic sellerInfo) {
    return Seller(
      id: (sellerInfo.sellerId ?? sellerInfo.id)?.toString() ?? '0',
      email: '', // Not available in SellerInfo
      fullName: sellerInfo.profileName ?? 'Business Owner',
      createdAt: DateTime.now().subtract(const Duration(days: 30)), // Not available in SellerInfo
      updatedAt: DateTime.now(),
      businessName: sellerInfo.businessName ?? 'Local Business',
      bio: 'Welcome to our business!', // Not available in SellerInfo
      whatsappNumber: null, // Not available in SellerInfo
      stallLocation: StallLocation(
        latitude: 0.0, // Not available in SellerInfo
        longitude: 0.0, // Not available in SellerInfo
        stallNumber: _generateStallNumber(sellerInfo.sellerId ?? sellerInfo.id),
        area: sellerInfo.area ?? 'Business Area',
        address: null, // Not available in SellerInfo
      ),
      businessLogo: sellerInfo.logo,
      isProfilePublished: true, // Assume true if included in product response
    );
  }

  void _loadProductImages() {
    try {
      productImages.clear();
      // Use the product's media URLs if available
      if (product.value?.images != null && product.value!.images.isNotEmpty) {
        productImages.addAll(product.value!.images);
      }
      // No fallback placeholder images - if no images, show empty state
    } catch (e) {
      // Handle image loading errors gracefully
      print('Failed to load product images: $e');
      productImages.clear();
    }
  }

  void _loadSellerInfo() {
    if (product.value?.sellerId == null) {
      print('❌ BuyerProductViewController: No seller ID available for product');
      return;
    }
    
    print('🔄 BuyerProductViewController: Loading seller info for sellerId: ${product.value!.sellerId}');
    
    // Use the new API endpoint that searches by sellerId
    final buyerService = Get.find<BuyerService>();
    final sellerIdInt = int.tryParse(product.value!.sellerId);
    
    if (sellerIdInt == null) {
      print('❌ BuyerProductViewController: Invalid seller ID format: ${product.value!.sellerId}');
      return;
    }
    
    buyerService.getSellerDetailsBySellerId(sellerIdInt).then((response) {
      if (response.isSuccess && response.data != null) {
        print('✅ BuyerProductViewController: Seller data loaded from new API successfully');
        
        // Convert SellerDetailsExtended to Seller model
        final sellerData = _convertSellerDetailsToSeller(response.data!);
        seller.value = sellerData;
      } else {
        print('❌ BuyerProductViewController: Failed to load seller from new API: ${response.errorMessage}');
        // No fallback - let UI handle gracefully
      }
    }).catchError((e) {
      print('❌ BuyerProductViewController: Exception during seller API call: $e');
      // No fallback - let UI handle gracefully
    });
  }

  // Convert API response to Seller model
  Seller _convertSellerDetailsToSeller(dynamic sellerDetailsExtended) {
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
      businessLogo: sellerDetailsExtended.logo,
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

  void _loadRelatedProducts() {
    if (product.value == null) return;
    
    print('🔄 BuyerProductViewController: Loading related products');
    
    // Use actual API service to fetch related products
    final buyerService = Get.find<BuyerService>();
    
    // Search for products in the same categories
    final categories = product.value!.categories;
    if (categories.isNotEmpty) {
      // TODO: Convert category names to category IDs for API call
      // For now, search by seller ID to get other products from same seller
      final sellerIdInt = int.tryParse(product.value!.sellerId);
      
      if (sellerIdInt != null) {
        buyerService.searchProducts(
          sellerId: sellerIdInt,
          pageSize: 10, // Get up to 10 related products
        ).then((response) {
          if (response.isSuccess && response.data != null) {
            print('✅ BuyerProductViewController: Related products loaded from API (${response.data!.products.length} products)');
            relatedProducts.clear();
            // Exclude current product from related products
            final filtered = response.data!.products.where((p) => p.id != product.value!.id).toList();
            relatedProducts.addAll(filtered);
          } else {
            print('❌ BuyerProductViewController: Failed to load related products: ${response.errorMessage}');
            relatedProducts.clear();
          }
        }).catchError((e) {
          print('❌ BuyerProductViewController: Exception during related products API call: $e');
          relatedProducts.clear();
        });
      } else {
        relatedProducts.clear();
      }
    } else {
      relatedProducts.clear();
    }
  }

  void changeImage(int index) {
    if (index >= 0 && index < productImages.length) {
      currentImageIndex.value = index;
    }
  }

  void toggleFavorite() {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null) {
      _showSnackbar(
        'Login Required',
        'Please login to add products to favorites',
        Colors.orange,
      );
      return;
    }
    
    if (product.value?.id == null) {
      _showSnackbar('Error', 'Unable to favorite this product', Colors.red);
      return;
    }
    
    final productId = int.tryParse(product.value!.id);
    if (productId == null) {
      _showSnackbar('Error', 'Invalid product information', Colors.red);
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
        refId: productId,
        type: 'P',
      );
    } else {
      // Add to favorites
      apiCall = buyerService.addToFavorites(
        userId: currentUser!.userid!,
        refId: productId,
        type: 'P',
      );
    }
    
    apiCall.then((response) {
      if (response.isSuccess) {
        final message = isFavorite.value 
            ? 'Added to favorites'
            : 'Removed from favorites';
        
        _showSnackbar(
          'Favorites',
          message,
          isFavorite.value 
              ? AppTheme.buyerPrimary.withOpacity(0.9)
              : Colors.grey.withOpacity(0.9),
        );
        
        print('✅ Favorite status updated successfully: ${isFavorite.value}');
      } else {
        // Revert optimistic update on failure
        isFavorite.value = wasAlreadyFavorite;
        _showSnackbar(
          'Error',
          'Failed to update favorites. Please try again.',
          Colors.red,
        );
        print('❌ Failed to update favorite status: ${response.errorMessage}');
      }
    }).catchError((e) {
      // Revert optimistic update on error
      isFavorite.value = wasAlreadyFavorite;
      _showSnackbar(
        'Error',
        'Network error. Please try again.',
        Colors.red,
      );
      print('❌ Exception updating favorite status: $e');
    });
  }

  void toggleDescription() {
    showFullDescription.value = !showFullDescription.value;
  }

  void viewSeller() {
    if (seller.value != null) {
      Get.toNamed('/buyer-seller-view', arguments: seller.value);
    } else {
      _showSnackbar('Error', 'Seller information not available', Colors.red);
    }
  }

  void contactSeller() {
    if (seller.value?.whatsappNumber != null && seller.value!.whatsappNumber!.isNotEmpty) {
      _showSnackbar(
        'Opening WhatsApp',
        'Opening WhatsApp to contact ${seller.value?.businessName}',
        Colors.green.withOpacity(0.9),
      );
      // In real app: launch WhatsApp
    } else if (seller.value != null) {
      _showSnackbar(
        'Contact Info',
        'Contact details will be available when you view the seller profile. Tap "View Profile" above.',
        Colors.blue,
        duration: const Duration(seconds: 4),
      );
    } else {
      _showSnackbar('Error', 'Seller information not available', Colors.red);
    }
  }

  void getDirections() {
    if (seller.value?.stallLocation != null && 
        seller.value!.stallLocation!.latitude != 0.0 && 
        seller.value!.stallLocation!.longitude != 0.0) {
      _showSnackbar(
        'Opening Maps',
        'Getting directions to ${seller.value?.businessName}',
        Colors.blue,
      );
      // In real app: launch maps
    } else if (seller.value != null) {
      _showSnackbar(
        'Location Info',
        'Detailed location will be available when you view the seller profile. Tap "View Profile" above.',
        Colors.blue,
        duration: const Duration(seconds: 4),
      );
    } else {
      _showSnackbar('Error', 'Seller information not available', Colors.red);
    }
  }

  void shareProduct() {
    _showSnackbar(
      'Share Product',
      'Sharing ${product.value?.name}',
      Colors.blue,
    );
    // In real app: use share package
  }

  void viewRelatedProduct(Product relatedProduct) {
    // Navigate to product view with new product
    Get.toNamed('/buyer-product-view', arguments: relatedProduct);
  }

  void inquireAboutProduct() {
    if (seller.value == null) {
      _showSnackbar('Error', 'Seller information not available', Colors.red);
      return;
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Seller',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Quick inquiry buttons
            _buildInquiryOption(
              icon: Icons.chat,
              title: 'Ask about availability',
              subtitle: 'Is this product available?',
              onTap: () {
                Get.back();
                _sendQuickMessage('Is this product available?');
              },
            ),
            
            _buildInquiryOption(
              icon: Icons.info,
              title: 'Ask for more details',
              subtitle: 'Can you provide more details?',
              onTap: () {
                Get.back();
                _sendQuickMessage('Can you provide more details about this product?');
              },
            ),
            
            _buildInquiryOption(
              icon: Icons.local_shipping,
              title: 'Ask about delivery',
              subtitle: 'Do you provide delivery?',
              onTap: () {
                Get.back();
                _sendQuickMessage('Do you provide delivery for this product?');
              },
            ),
            
            _buildInquiryOption(
              icon: Icons.phone,
              title: 'Custom message',
              subtitle: 'Send your own message',
              onTap: () {
                Get.back();
                contactSeller();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.buyerPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.buyerPrimary,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _sendQuickMessage(String message) {
    _showSnackbar(
      'Opening WhatsApp',
      'Opening WhatsApp with: "$message"',
      Colors.green.withOpacity(0.9),
      duration: const Duration(seconds: 3),
    );
    // In real app: launch WhatsApp with pre-filled message
  }

  // Safe snackbar method
  void _showSnackbar(String title, String message, Color backgroundColor, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: duration,
    );
  }
}

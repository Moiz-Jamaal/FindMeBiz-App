import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/data/models/product.dart';
import 'package:souq/app/data/models/seller.dart';
import 'package:souq/app/services/api/api_exception.dart';
import 'package:souq/app/services/product_service.dart';
import 'package:souq/app/services/auth_service.dart';

import '../../../../core/theme/app_theme.dart';

class BuyerProductViewController extends GetxController {
  // Unified service
  final ProductService _productService = ProductService.instance;
  final AuthService _authService = Get.find<AuthService>();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductData();
    });
  }

  void _loadProductData() {
    final productArg = Get.arguments;
    
    if (productArg is Product) {
      product.value = productArg;
      _loadProductDetails();
    } else if (productArg is int && productArg > 0) {
      _loadProductById(productArg.toString());
    } else if (productArg is String && productArg.isNotEmpty) {
      final productId = int.tryParse(productArg);
      if (productId != null && productId > 0) {
        _loadProductById(productArg);
      } else {
        _setError('Invalid product ID format. Please try again.');
      }
    } else {
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
    
    final productIdInt = int.tryParse(productId);
    
    if (productIdInt == null) {
      _setError('Invalid product ID format. Please try again.');
      return;
    }
    
    // Use unified ProductService
    _productService.getProductDetails(productIdInt).then((response) {
      if (response.isSuccess && response.data != null) {
        product.value = response.data;
        _loadProductDetails();
      } else {
        _setError(response.errorMessage ?? 'Product not found. It may have been removed or is no longer available.');
      }
    }).catchError((e) {
      _setError('Network error. Please check your connection and try again.');
    });
  }

  void _loadProductDetails() {
    if (product.value == null) return;
    
    isLoading.value = true;
    
    try {
      // Check if seller info is already included in product response
      if (product.value?.seller != null) {
        seller.value = _convertSellerInfoToSeller(product.value!.seller!);
      } else {
        _loadSellerInfo();
      }
      
      _loadProductImages();
      _loadRelatedProducts();
      _checkIfFavorited();
      _trackProductView();
      
      isLoading.value = false;
    } catch (e) {
      _setError('Failed to load product information');
    }
  }

  void _checkIfFavorited() {
    final currentUser = _authService.currentUser;
    
    if (currentUser?.userid == null || product.value?.id == null) {
      isFavorite.value = false;
      return;
    }
    
    final productId = int.tryParse(product.value!.id);
    if (productId == null) {
      isFavorite.value = false;
      return;
    }
    
    _productService.checkIfProductFavorite(
      userId: currentUser!.userid!,
      productId: productId,
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

  void _trackProductView() {
    final currentUser = _authService.currentUser;
    
    if (currentUser?.userid == null || product.value?.id == null) {
      return;
    }
    
    final productId = int.tryParse(product.value!.id);
    if (productId == null) return;
    
    _productService.trackProductView(
      userId: currentUser!.userid!,
      productId: productId,
    ).then((response) {
      // Track view succeeded
    }).catchError((e) {
      // Track view failed - not critical
    });
  }

  // Convert SellerInfo from product API response to Seller model
  Seller _convertSellerInfoToSeller(dynamic sellerInfo) {
    return Seller(
      id: (sellerInfo.sellerId ?? sellerInfo.id)?.toString() ?? '0',
      email: '',
      fullName: sellerInfo.profileName ?? 'Business Owner',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      businessName: sellerInfo.businessName ?? 'Local Business',
      bio: 'Welcome to our business!',
      whatsappNumber: null,
      stallLocation: StallLocation(
        latitude: 0.0,
        longitude: 0.0,
        stallNumber: _generateStallNumber(sellerInfo.sellerId ?? sellerInfo.id),
        area: sellerInfo.area ?? 'Business Area',
        address: null,
      ),
      businessLogo: sellerInfo.logo,
      isProfilePublished: true,
    );
  }

  void _loadProductImages() {
    try {
      productImages.clear();
      if (product.value?.images != null && product.value!.images.isNotEmpty) {
        productImages.addAll(product.value!.images);
      }
    } catch (e) {
      productImages.clear();
    }
  }

  void _loadSellerInfo() {
    if (product.value?.sellerId == null) {
      return;
    }
    
    final sellerIdInt = int.tryParse(product.value!.sellerId);
    
    if (sellerIdInt == null) {
      return;
    }
    
    // Use unified ProductService for seller details
    _productService.getSellerDetailsBySellerId(sellerIdInt).then((response) {
      if (response.isSuccess && response.data != null) {
        final sellerData = _convertSellerDetailsToSeller(response.data!);
        seller.value = sellerData;
      }
    }).catchError((e) {
      // No fallback - let UI handle gracefully
    });
  }

  // Convert API response to Seller model
  Seller _convertSellerDetailsToSeller(dynamic sellerDetailsExtended) {
    return Seller(
      id: sellerDetailsExtended.sellerid?.toString() ?? '0',
      email: '',
      fullName: sellerDetailsExtended.profilename ?? 'Business Owner',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
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

  double _parseLatitude(String? geoLocation) {
    if (geoLocation == null || geoLocation.isEmpty) return 0.0;
    final parts = geoLocation.split(',');
    if (parts.length >= 2) {
      return double.tryParse(parts[0].trim()) ?? 0.0;
    }
    return 0.0;
  }

  double _parseLongitude(String? geoLocation) {
    if (geoLocation == null || geoLocation.isEmpty) return 0.0;
    final parts = geoLocation.split(',');
    if (parts.length >= 2) {
      return double.tryParse(parts[1].trim()) ?? 0.0;
    }
    return 0.0;
  }

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
    
    final sellerIdInt = int.tryParse(product.value!.sellerId);
    
    if (sellerIdInt != null) {
      // Use unified ProductService
      _productService.searchProducts(
        sellerId: sellerIdInt,
        pageSize: 10,
      ).then((response) {
        if (response.isSuccess && response.data != null) {
          print('=== RELATED PRODUCTS DEBUG ===');
          print('Related products count: ${response.data!.products.length}');
          if (response.data!.products.isNotEmpty) {
            final firstProduct = response.data!.products.first;
            print('First related product: ${firstProduct.name}');
            print('Price: ${firstProduct.price}');
            print('Images count: ${firstProduct.images.length}');
            print('Primary image URL: ${firstProduct.primaryImageUrl}');
          }
          print('=== END RELATED DEBUG ===');
          
          relatedProducts.clear();
          final filtered = response.data!.products.where((p) => p.id != product.value!.id).toList();
          relatedProducts.addAll(filtered);
        } else {
          print('=== RELATED PRODUCTS ERROR ===');
          print('Error: ${response.errorMessage}');
          print('=== END RELATED ERROR ===');
          relatedProducts.clear();
        }
      }).catchError((e) {
        print('=== RELATED PRODUCTS EXCEPTION ===');
        print('Exception: $e');
        print('=== END RELATED EXCEPTION ===');
        relatedProducts.clear();
      });
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
    final currentUser = _authService.currentUser;
    
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
    
    Future<ApiResponse<Map<String, dynamic>>> apiCall;
    if (wasAlreadyFavorite) {
      apiCall = _productService.removeProductFromFavorites(
        userId: currentUser!.userid!,
        productId: productId,
      );
    } else {
      apiCall = _productService.addProductToFavorites(
        userId: currentUser!.userid!,
        productId: productId,
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
              ? AppTheme.buyerPrimary.withValues(alpha: 0.9)
              : Colors.grey.withValues(alpha: 0.9),
        );
      } else {
        // Revert optimistic update on failure
        isFavorite.value = wasAlreadyFavorite;
        _showSnackbar(
          'Error',
          'Failed to update favorites. Please try again.',
          Colors.red,
        );
      }
    }).catchError((e) {
      // Revert optimistic update on error
      isFavorite.value = wasAlreadyFavorite;
      _showSnackbar(
        'Error',
        'Network error. Please try again.',
        Colors.red,
      );
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
        Colors.green.withValues(alpha: 0.9),
      );
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
  }

  void viewRelatedProduct(Product relatedProduct) {
    _trackRelatedProductView(relatedProduct);
    Get.toNamed('/buyer-product-view', arguments: relatedProduct);
  }

  void _trackRelatedProductView(Product product) {
    final currentUser = _authService.currentUser;
    
    if (currentUser?.userid == null) return;
    
    final productId = int.tryParse(product.id);
    if (productId == null) return;
    
    _productService.trackProductView(
      userId: currentUser!.userid!,
      productId: productId,
    ).then((response) {
      // Track view succeeded
    }).catchError((e) {
      // Track view failed - not critical
    });
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
          color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
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
      Colors.green.withValues(alpha: 0.9),
      duration: const Duration(seconds: 3),
    );
  }

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

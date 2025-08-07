import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/seller.dart';
import '../../../../core/theme/app_theme.dart';
import '../views/buyer_product_view.dart';
import '../bindings/buyer_product_view_binding.dart';

class BuyerProductViewController extends GetxController {
  // Product data
  final Rx<Product?> product = Rx<Product?>(null);
  final Rx<Seller?> seller = Rx<Seller?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isFavorite = false.obs;
  
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
    _loadProductData();
  }

  void _loadProductData() {
    // Get product from arguments
    final productArg = Get.arguments;
    if (productArg is Product) {
      product.value = productArg;
      _loadProductDetails();
    } else if (productArg is String) {
      _loadProductById(productArg);
    }
  }

  void _loadProductById(String productId) {
    isLoading.value = true;
    
    Future.delayed(const Duration(milliseconds: 800), () {
      // Mock product loading
      product.value = Product(
        id: productId,
        sellerId: 'seller_001',
        name: 'Premium Silk Saree',
        description: 'Beautiful Banarasi silk saree with intricate gold thread work. Handwoven by skilled artisans with traditional techniques passed down through generations. Perfect for weddings, festivals, and special occasions.',
        price: 5500.0,
        categories: ['Apparel'],
        images: ['image1', 'image2', 'image3'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      );
      
      _loadProductDetails();
    });
  }

  void _loadProductDetails() {
    if (product.value == null) return;
    
    isLoading.value = true;
    
    // Load seller info
    _loadSellerInfo();
    
    // Load product images
    productImages.addAll([
      'https://via.placeholder.com/400x400',
      'https://via.placeholder.com/400x400/FF0000',
      'https://via.placeholder.com/400x400/00FF00',
    ]);
    
    // Load related products
    _loadRelatedProducts();
    
    // Check if favorited
    isFavorite.value = false; // Mock check
    
    isLoading.value = false;
  }

  void _loadSellerInfo() {
    Future.delayed(const Duration(milliseconds: 300), () {
      seller.value = Seller(
        id: 'seller_001',
        email: 'rajesh@suratsik.com',
        fullName: 'Rajesh Patel',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        businessName: 'Surat Silk Emporium',
        bio: 'Premium silk sarees and traditional wear. Family business since 1985.',
        whatsappNumber: '+91 98765 43210',
        stallLocation: StallLocation(
          latitude: 21.1702,
          longitude: 72.8311,
          stallNumber: 'A-23',
          area: 'Textile Zone',
        ),
        isProfilePublished: true,
      );
    });
  }

  void _loadRelatedProducts() {
    // Mock related products
    relatedProducts.addAll([
      Product(
        id: 'p2',
        sellerId: 'seller_001',
        name: 'Cotton Saree',
        description: 'Traditional cotton saree',
        price: 2500.0,
        categories: ['Apparel'],
        images: ['img1'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'p3',
        sellerId: 'seller_002',
        name: 'Designer Blouse',
        description: 'Elegant designer blouse',
        price: 1200.0,
        categories: ['Apparel'],
        images: ['img2'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  void changeImage(int index) {
    currentImageIndex.value = index;
  }

  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
    
    Get.snackbar(
      isFavorite.value ? 'Added to Favorites' : 'Removed from Favorites',
      isFavorite.value 
          ? '${product.value?.name} added to your favorites'
          : '${product.value?.name} removed from your favorites',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isFavorite.value 
          ? AppTheme.buyerPrimary.withOpacity(0.9)
          : Colors.red.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  void toggleDescription() {
    showFullDescription.value = !showFullDescription.value;
  }

  void viewSeller() {
    if (seller.value != null) {
      Get.toNamed('/buyer-seller-view', arguments: seller.value);
    }
  }

  void contactSeller() {
    if (seller.value?.whatsappNumber != null) {
      Get.snackbar(
        'Opening WhatsApp',
        'Opening WhatsApp to contact ${seller.value?.businessName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
      // In real app: launch WhatsApp
    }
  }

  void getDirections() {
    if (seller.value?.stallLocation != null) {
      Get.snackbar(
        'Opening Maps',
        'Getting directions to ${seller.value?.businessName}',
        snackPosition: SnackPosition.BOTTOM,
      );
      // In real app: launch maps
    }
  }

  void shareProduct() {
    Get.snackbar(
      'Share Product',
      'Sharing ${product.value?.name}',
      snackPosition: SnackPosition.BOTTOM,
    );
    // In real app: use share package
  }

  void viewRelatedProduct(Product relatedProduct) {
    Get.to(
      () => const BuyerProductView(),
      arguments: relatedProduct,
      binding: BuyerProductViewBinding(),
    );
  }

  void inquireAboutProduct() {
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
    Get.snackbar(
      'Opening WhatsApp',
      'Opening WhatsApp with: "$message"',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    // In real app: launch WhatsApp with pre-filled message
  }
}

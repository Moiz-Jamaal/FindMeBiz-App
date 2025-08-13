import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart'; // Add this dependency to pubspec.yaml
import '../../../../data/models/seller.dart';
import '../../../../data/models/product.dart';
import '../../../../core/theme/app_theme.dart';

class SellerProfileViewController extends GetxController {
  // Seller data
  final Rx<Seller?> seller = Rx<Seller?>(null);
  final RxList<Product> products = <Product>[].obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isFavorite = false.obs;
  final RxInt selectedProductCategory = 0.obs;
  
  // Product categories for this seller
  final RxList<String> sellerCategories = <String>[].obs;
  
  // Interaction tracking
  final RxBool hasContacted = false.obs;
  final RxBool hasViewed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSellerData();
  }

  void _loadSellerData() {
    // Get seller from arguments
    final sellerData = Get.arguments;
    
    if (sellerData is Seller) {
      // Full seller object passed (e.g., from search)
      seller.value = sellerData;
      _loadSellerProducts();
      _checkIfFavorite();
      _markAsViewed();
    } else if (sellerData is String) {
      // Only seller ID passed (e.g., from home)
      _loadSellerById(sellerData);
    } else {
      // No valid data provided
      Get.back();
      Get.snackbar(
        'Error',
        'Unable to load seller information',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _loadSellerById(String sellerId) {
    isLoading.value = true;
    
    // Simulate API call to fetch seller by ID
    Future.delayed(const Duration(seconds: 1), () {
      final sellerData = _getMockSellerById(sellerId);
      
      if (sellerData != null) {
        seller.value = sellerData;
        _loadSellerProducts();
        _checkIfFavorite();
        _markAsViewed();
      } else {
        // Seller not found
        isLoading.value = false;
        Get.back();
        Get.snackbar(
          'Error',
          'Seller not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    });
  }

  void _loadSellerProducts() {
    if (seller.value == null) return;
    
    isLoading.value = true;
    
    // Simulate API call to load seller's products
    Future.delayed(const Duration(seconds: 1), () {
      products.addAll(_getMockProductsForSeller(seller.value!.id));
      _extractProductCategories();
      isLoading.value = false;
    });
  }

  void _extractProductCategories() {
    final categories = <String>{'All'};
    for (final product in products) {
      categories.addAll(product.categories);
    }
    sellerCategories.addAll(categories.toList());
  }

  void _checkIfFavorite() {
    // Simulate checking if seller is in user's favorites
    // In real app, this would check local storage or API
    isFavorite.value = false;
  }

  void _markAsViewed() {
    if (!hasViewed.value) {
      hasViewed.value = true;
      // In real app, track this view for analytics
    }
  }

  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
    
    final message = isFavorite.value 
        ? 'Added to favorites'
        : 'Removed from favorites';
    
    Get.snackbar(
      'Favorites',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isFavorite.value 
          ? AppTheme.successColor 
          : AppTheme.textSecondary,
      colorText: Colors.white,
    );
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
    // In real app, generate shareable link
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

  // Mock method to fetch seller by ID
  Seller? _getMockSellerById(String sellerId) {
    // Mock seller data - in real app, this would fetch from API/database
    switch (sellerId) {
      case '1':
        return Seller(
          id: '1',
          email: 'rajesh@suratsik.com',
          fullName: 'Rajesh Patel',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          businessName: 'Surat Silk Emporium',
          bio: 'Premium silk sarees and traditional wear from Surat. Family business since 1985.',
          whatsappNumber: '+91 98765 43210',
          stallLocation: StallLocation(
            latitude: 21.1702,
            longitude: 72.8311,
            stallNumber: 'A-23',
            area: 'Textile Zone',
          ),
          isProfilePublished: true,
        );
      case '2':
        return Seller(
          id: '2',
          email: 'meera@crafts.com',
          fullName: 'Meera Shah',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
          businessName: 'Gujarati Crafts',
          bio: 'Authentic handmade crafts and artwork from Gujarat.',
          whatsappNumber: '+91 98765 43211',
          stallLocation: StallLocation(
            latitude: 21.1700,
            longitude: 72.8308,
            stallNumber: 'B-12',
            area: 'Handicraft Section',
          ),
          isProfilePublished: true,
        );
      case '3':
        return Seller(
          id: '3',
          email: 'spice@paradise.com',
          fullName: 'Kiran Joshi',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
          businessName: 'Spice Paradise',
          bio: 'Authentic Gujarat spices and traditional food items.',
          whatsappNumber: '+91 98765 43212',
          stallLocation: StallLocation(
            latitude: 21.1698,
            longitude: 72.8315,
            stallNumber: 'C-45',
            area: 'Food Court',
          ),
          isProfilePublished: true,
        );
      case '4':
        return Seller(
          id: '4',
          email: 'diamond@jewelry.com',
          fullName: 'Amit Jain',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
          businessName: 'Diamond Jewelry',
          bio: 'Exquisite diamond and gold jewelry for special occasions.',
          whatsappNumber: '+91 98765 43213',
          stallLocation: StallLocation(
            latitude: 21.1705,
            longitude: 72.8320,
            stallNumber: 'D-78',
            area: 'Main Entrance',
          ),
          isProfilePublished: true,
        );
      case '5':
        return Seller(
          id: '5',
          email: 'homedecor@plus.com',
          fullName: 'Priya Desai',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
          businessName: 'Home Decor Plus',
          bio: 'Beautiful home decoration items and furniture accessories.',
          whatsappNumber: '+91 98765 43214',
          stallLocation: StallLocation(
            latitude: 21.1695,
            longitude: 72.8325,
            stallNumber: 'E-34',
            area: 'Home Decor Zone',
          ),
          isProfilePublished: true,
        );
      default:
        return null;
    }
  }

  // Mock data for products
  List<Product> _getMockProductsForSeller(String sellerId) {
    final mockProducts = <Product>[];
    
    switch (sellerId) {
      case '1': // Surat Silk Emporium
        mockProducts.addAll([
          Product(
            id: 'p1', sellerId: sellerId, name: 'Premium Silk Saree',
            description: 'Beautiful Banarasi silk saree with gold thread work',
            price: 5500.0, categories: ['Apparel'], images: ['mock1'],
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'p2', sellerId: sellerId, name: 'Traditional Lehenga',
            description: 'Elegant wedding lehenga with intricate embroidery',
            price: 8500.0, categories: ['Apparel'], images: ['mock2'],
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'p3', sellerId: sellerId, name: 'Silk Dupatta',
            description: 'Matching silk dupatta with golden border',
            price: 1200.0, categories: ['Apparel'], images: ['mock3'],
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            updatedAt: DateTime.now(),
          ),
        ]);
        break;
        
      case '2': // Gujarati Handicrafts
        mockProducts.addAll([
          Product(
            id: 'p4', sellerId: sellerId, name: 'Handwoven Wall Hanging',
            description: 'Traditional Gujarati wall art with mirror work',
            price: 1200.0, categories: ['Art & Crafts'], images: ['mock4'],
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'p5', sellerId: sellerId, name: 'Wooden Handicraft',
            description: 'Hand-carved wooden decorative items',
            price: 800.0, categories: ['Home Decor'], images: ['mock5'],
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now(),
          ),
        ]);
        break;
        
      case '3': // Spice Paradise
        mockProducts.addAll([
          Product(
            id: 'p6', sellerId: sellerId, name: 'Gujarati Thali Special',
            description: 'Authentic Gujarati thali with 12 varieties of traditional dishes',
            price: 350.0, categories: ['Food & Beverages'], images: ['mock6'],
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'p7', sellerId: sellerId, name: 'Traditional Spice Mix',
            description: 'Homemade Gujarati spice blend for authentic flavors',
            price: 120.0, categories: ['Food & Beverages'], images: ['mock7'],
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now(),
          ),
        ]);
        break;
        
      case '4': // Diamond Jewelry
        mockProducts.addAll([
          Product(
            id: 'p8', sellerId: sellerId, name: 'Diamond Necklace Set',
            description: 'Elegant diamond necklace with matching earrings',
            price: 25000.0, categories: ['Jewelry'], images: ['mock8'],
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'p9', sellerId: sellerId, name: 'Gold Ring Collection',
            description: 'Beautiful gold rings with precious stones',
            price: 8500.0, categories: ['Jewelry'], images: ['mock9'],
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            updatedAt: DateTime.now(),
          ),
        ]);
        break;
        
      case '5': // Home Decor Plus
        mockProducts.addAll([
          Product(
            id: 'p10', sellerId: sellerId, name: 'Decorative Vases Set',
            description: 'Elegant ceramic vases for home decoration',
            price: 1200.0, categories: ['Home Decor'], images: ['mock10'],
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'p11', sellerId: sellerId, name: 'Wall Art Collection',
            description: 'Beautiful framed wall art pieces',
            price: 800.0, categories: ['Home Decor'], images: ['mock11'],
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            updatedAt: DateTime.now(),
          ),
        ]);
        break;
        
      default:
        // Default products for other sellers
        mockProducts.addAll([
          Product(
            id: 'p_default', sellerId: sellerId, name: 'Sample Product',
            description: 'Sample product description',
            price: 500.0, categories: ['Others'], images: ['mock_default'],
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now(),
          ),
        ]);
    }
    
    return mockProducts;
  }
}

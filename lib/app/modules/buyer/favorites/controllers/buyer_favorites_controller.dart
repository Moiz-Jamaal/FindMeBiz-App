import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/seller.dart';
import '../../../../core/theme/app_theme.dart';

class BuyerFavoritesController extends GetxController {
  // Favorites data
  final RxList<Seller> favoriteSellers = <Seller>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isEmpty = false.obs;
  
  // Filter and sort
  final RxString selectedCategory = 'All'.obs;
  final RxString sortBy = 'Recently Added'.obs;
  
  // Filter options
  final List<String> categories = [
    'All',
    'Apparel',
    'Jewelry', 
    'Food & Beverages',
    'Art & Crafts',
    'Home Decor',
    'Electronics',
  ];
  
  final List<String> sortOptions = [
    'Recently Added',
    'A to Z',
    'Rating (High to Low)',
    'Distance (Near to Far)',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }

  void _loadFavorites() {
    isLoading.value = true;
    
    Future.delayed(const Duration(milliseconds: 800), () {
      // Mock favorite sellers data
      favoriteSellers.addAll([
        Seller(
          id: '1',
          email: 'rajesh@suratsik.com',
          fullName: 'Rajesh Patel',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
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
        ),
        Seller(
          id: '2',
          email: 'meera@crafts.com',
          fullName: 'Meera Shah',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
          businessName: 'Gujarati Handicrafts',
          bio: 'Authentic handmade crafts and artwork from Gujarat.',
          whatsappNumber: '+91 98765 43211',
          stallLocation: StallLocation(
            latitude: 21.1700,
            longitude: 72.8308,
            stallNumber: 'B-12',
            area: 'Handicraft Section',
          ),
          isProfilePublished: true,
        ),
        Seller(
          id: '3',
          email: 'amit@jewelry.com',
          fullName: 'Amit Jain',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now(),
          businessName: 'Diamond Jewelry House',
          bio: 'Exquisite diamond and gold jewelry for special occasions.',
          whatsappNumber: '+91 98765 43212',
          stallLocation: StallLocation(
            latitude: 21.1698,
            longitude: 72.8315,
            stallNumber: 'C-45',
            area: 'Main Entrance',
          ),
          isProfilePublished: true,
        ),
      ]);
      
      isEmpty.value = favoriteSellers.isEmpty;
      isLoading.value = false;
    });
  }

  void toggleFavorite(Seller seller) {
    if (isFavorite(seller.id)) {
      removeFavorite(seller);
    } else {
      addFavorite(seller);
    }
  }

  bool isFavorite(String sellerId) {
    return favoriteSellers.any((seller) => seller.id == sellerId);
  }

  void addFavorite(Seller seller) {
    if (!isFavorite(seller.id)) {
      favoriteSellers.insert(0, seller);
      isEmpty.value = false;
      
      Get.snackbar(
        'Added to Favorites',
        '${seller.businessName} added to your favorites',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.buyerPrimary.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void removeFavorite(Seller seller) {
    favoriteSellers.removeWhere((s) => s.id == seller.id);
    isEmpty.value = favoriteSellers.isEmpty;
    
    Get.snackbar(
      'Removed from Favorites',
      '${seller.businessName} removed from your favorites',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      mainButton: TextButton(
        onPressed: () {
          addFavorite(seller);
          Get.back();
        },
        child: const Text('Undo', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void updateSortOption(String sortOption) {
    sortBy.value = sortOption;
    _applySorting();
  }

  void _applyFilters() {
    // In a real app, this would filter the results
    // For now, we're just updating the observable
  }

  void _applySorting() {
    final sellers = List<Seller>.from(favoriteSellers);
    
    switch (sortBy.value) {
      case 'A to Z':
        sellers.sort((a, b) => a.businessName.compareTo(b.businessName));
        break;
      case 'Rating (High to Low)':
        // Mock rating sort
        sellers.sort((a, b) => b.id.compareTo(a.id)); // Using ID as mock rating
        break;
      case 'Distance (Near to Far)':
        // Mock distance sort
        break;
      case 'Recently Added':
      default:
        sellers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    favoriteSellers.assignAll(sellers);
  }

  void viewSeller(Seller seller) {
    // Add to recently viewed
    Get.toNamed('/buyer-seller-view', arguments: seller);
  }

  void contactSeller(Seller seller) {
    if (seller.whatsappNumber != null) {
      Get.snackbar(
        'Opening WhatsApp',
        'Opening WhatsApp to contact ${seller.businessName}',
        snackPosition: SnackPosition.BOTTOM,
      );
      // In real app: launch WhatsApp with seller.whatsappNumber
    }
  }

  void getDirections(Seller seller) {
    if (seller.stallLocation != null) {
      Get.snackbar(
        'Opening Maps',
        'Getting directions to ${seller.businessName}',
        snackPosition: SnackPosition.BOTTOM,
      );
      // In real app: launch maps with coordinates
    }
  }

  void shareProfile(Seller seller) {
    Get.snackbar(
      'Share',
      'Sharing ${seller.businessName} profile',
      snackPosition: SnackPosition.BOTTOM,
    );
    // In real app: use share package
  }

  void refreshFavorites() {
    _loadFavorites();
  }

  void clearAllFavorites() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text('Are you sure you want to remove all favorites? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              favoriteSellers.clear();
              isEmpty.value = true;
              Get.back();
              
              Get.snackbar(
                'Favorites Cleared',
                'All favorites have been removed',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withOpacity(0.9),
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

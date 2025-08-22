import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/favorites_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/viewed_history_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../data/models/product.dart';
import '../../../../core/theme/app_theme.dart';

class BuyerFavoritesController extends GetxController {
  // Services
  final FavoritesService _favoritesService = Get.find<FavoritesService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ViewedHistoryService _viewedHistoryService = Get.find<ViewedHistoryService>();
  
  // Favorites data
  final RxList<SellerDetails> favoriteSellers = <SellerDetails>[].obs;
  final RxList<Product> favoriteProducts = <Product>[].obs;
  final Rx<FavoritesCount?> favoritesCount = Rx<FavoritesCount?>(null);
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isEmpty = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentTab = 'sellers'.obs; // 'sellers' or 'products'
  
  // Filter and sort
  final RxString selectedCategory = 'All'.obs;
  final RxString sortBy = 'Recently Added'.obs;
  final RxList<CategoryMaster> availableCategories = <CategoryMaster>[].obs;
  
  // Filter options
  final List<String> categories = ['All']; // For dropdown compatibility
  final List<String> sortOptions = [
    'Recently Added',
    'A to Z',
    'Business Name',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  void _loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      await _loadCategories();
      await _loadFavoritesCount();
      await _loadFavorites();
    } catch (e) {
      errorMessage.value = 'Failed to load favorites: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      if (response.isSuccess && response.data != null) {
        availableCategories.assignAll(response.data!);
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadFavoritesCount() async {
    try {
      final response = await _favoritesService.getFavoritesCount();
      if (response.isSuccess && response.data != null) {
        favoritesCount.value = response.data!;
      }
    } catch (e) {
      print('Error loading favorites count: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      if (currentTab.value == 'sellers') {
        await _loadFavoriteSellers();
      } else {
        await _loadFavoriteProducts();
      }
      
      isEmpty.value = (currentTab.value == 'sellers' ? favoriteSellers.isEmpty : favoriteProducts.isEmpty);
    } catch (e) {
      print('Error loading favorites: $e');
      errorMessage.value = 'Failed to load favorites: ${e.toString()}';
    }
  }

  Future<void> _loadFavoriteSellers() async {
    try {
      final response = await _favoritesService.getFavoriteSellers();
      if (response.isSuccess && response.data != null) {
        favoriteSellers.assignAll(response.data!);
        _applySorting();
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to load favorite sellers';
      }
    } catch (e) {
      print('Error loading favorite sellers: $e');
    }
  }

  Future<void> _loadFavoriteProducts() async {
    try {
      final response = await _favoritesService.getFavoriteProducts();
      if (response.isSuccess && response.data != null) {
        favoriteProducts.assignAll(response.data!);
        _applySorting();
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to load favorite products';
      }
    } catch (e) {
      print('Error loading favorite products: $e');
    }
  }

  void switchTab(String tab) {
    if (currentTab.value != tab) {
      currentTab.value = tab;
      _loadFavorites();
    }
  }

  Future<void> toggleSellerFavorite(int sellerId, String businessName) async {
    try {
      final response = await _favoritesService.toggleSellerFavorite(sellerId);
      if (response.isSuccess) {
        final isFavorite = response.data ?? false;
        
        if (isFavorite) {
          Get.snackbar(
            'Added to Favorites',
            '$businessName added to your favorites',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.buyerPrimary.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          // Remove from local list
          favoriteSellers.removeWhere((s) => s.sellerid == sellerId);
          isEmpty.value = favoriteSellers.isEmpty;
          
          Get.snackbar(
            'Removed from Favorites',
            '$businessName removed from your favorites',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
        
        // Refresh count
        await _loadFavoritesCount();
      } else {
        Get.snackbar(
          'Error',
          response.errorMessage ?? 'Failed to update favorites',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update favorites: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleProductFavorite(int productId, String productName) async {
    try {
      final response = await _favoritesService.toggleProductFavorite(productId);
      if (response.isSuccess) {
        final isFavorite = response.data ?? false;
        
        if (isFavorite) {
          Get.snackbar(
            'Added to Favorites',
            '$productName added to your favorites',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.buyerPrimary.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          // Remove from local list
          favoriteProducts.removeWhere((p) => int.tryParse(p.id) == productId);
          isEmpty.value = favoriteProducts.isEmpty;
          
          Get.snackbar(
            'Removed from Favorites',
            '$productName removed from your favorites',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
        
        // Refresh count
        await _loadFavoritesCount();
      } else {
        Get.snackbar(
          'Error',
          response.errorMessage ?? 'Failed to update favorites',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update favorites: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<bool> isSellerFavorite(int sellerId) async {
    return await _favoritesService.isSellerFavorite(sellerId);
  }

  Future<bool> isProductFavorite(int productId) async {
    return await _favoritesService.isProductFavorite(productId);
  }

  // Legacy compatibility methods for UI
  void removeFavorite(SellerDetails seller) async {
    if (seller.sellerid != null) {
      await toggleSellerFavorite(seller.sellerid!, seller.businessname ?? 'Seller');
    }
  }

  void addFavorite(SellerDetails seller) async {
    if (seller.sellerid != null) {
      await toggleSellerFavorite(seller.sellerid!, seller.businessname ?? 'Seller');
    }
  }

  bool isFavorite(String sellerId) {
    final id = int.tryParse(sellerId);
    if (id != null) {
      return favoriteSellers.any((seller) => seller.sellerid == id);
    }
    return false;
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
    // Apply category filter
    // In a more complex implementation, you might need to reload from API with filters
    _applySorting();
  }

  void _applySorting() {
    if (currentTab.value == 'sellers') {
      final sellers = List<SellerDetails>.from(favoriteSellers);
      
      switch (sortBy.value) {
        case 'A to Z':
        case 'Business Name':
          sellers.sort((a, b) => (a.businessname ?? '').compareTo(b.businessname ?? ''));
          break;
        case 'Recently Added':
        default:
          // Keep original order (recently added should be first from API)
          break;
      }
      
      favoriteSellers.assignAll(sellers);
    } else {
      final products = List<Product>.from(favoriteProducts);
      
      switch (sortBy.value) {
        case 'A to Z':
          products.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'Recently Added':
        default:
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
      
      favoriteProducts.assignAll(products);
    }
  }

  void viewSeller(int sellerId) async {
    try {
      // Record the view
      await _viewedHistoryService.recordSellerView(sellerId);
      
      // Navigate to seller view
      Get.toNamed('/buyer-seller-view', arguments: sellerId);
    } catch (e) {
      print('Error recording seller view: $e');
      // Still navigate even if recording fails
      Get.toNamed('/buyer-seller-view', arguments: sellerId);
    }
  }

  void viewProduct(int productId) async {
    try {
      // Record the view
      await _viewedHistoryService.recordProductView(productId);
      
      // Navigate to product view
      Get.toNamed('/buyer-product-view', arguments: productId);
    } catch (e) {
      print('Error recording product view: $e');
      // Still navigate even if recording fails
      Get.toNamed('/buyer-product-view', arguments: productId);
    }
  }

  void contactSeller(SellerDetails seller) {
    if (seller.whatsappno != null) {
      Get.snackbar(
        'Opening WhatsApp',
        'Opening WhatsApp to contact ${seller.businessname}',
        snackPosition: SnackPosition.BOTTOM,
      );
      // In real app: launch WhatsApp with seller.whatsappno
    }
  }

  void getDirections(SellerDetails seller) {
    if (seller.geolocation != null) {
      Get.snackbar(
        'Opening Maps',
        'Getting directions to ${seller.businessname}',
        snackPosition: SnackPosition.BOTTOM,
      );
      // In real app: launch maps with coordinates
    }
  }

  void shareProfile(SellerDetails seller) {
    Get.snackbar(
      'Share',
      'Sharing ${seller.businessname} profile',
      snackPosition: SnackPosition.BOTTOM,
    );
    // In real app: use share package
  }

  void refreshFavorites() async {
     _loadInitialData();
  }

  void clearAllFavorites() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Favorites'),
        content: Text('Are you sure you want to remove all ${currentTab.value}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // Clear favorites (this would need API implementation)
              if (currentTab.value == 'sellers') {
                favoriteSellers.clear();
              } else {
                favoriteProducts.clear();
              }
              
              isEmpty.value = true;
              await _loadFavoritesCount();
              
              Get.snackbar(
                'Favorites Cleared',
                'All ${currentTab.value} have been removed from favorites',
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

  // Helper methods
  String getCategoryName(int categoryId) {
    final category = availableCategories.firstWhereOrNull((c) => c.catid == categoryId);
    return category?.catname ?? 'Category';
  }

  bool get hasFavorites => 
      (currentTab.value == 'sellers' ? favoriteSellers.isNotEmpty : favoriteProducts.isNotEmpty);

  int get currentTabCount => 
      currentTab.value == 'sellers' 
          ? (favoritesCount.value?.sellersCount ?? 0)
          : (favoritesCount.value?.productsCount ?? 0);
}

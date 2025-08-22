import 'package:get/get.dart';
import '../../../../services/buyer_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/viewed_history_service.dart';
import '../../../../services/favorites_service.dart';
import '../../../../data/models/api/index.dart';

class BuyerHomeController extends GetxController {
  // Services
  final BuyerService _buyerService = Get.find<BuyerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ViewedHistoryService _viewedHistoryService = Get.find<ViewedHistoryService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();
  
  // Current navigation index
  final RxInt currentIndex = 0.obs;
  
  // Search functionality
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  
  // Data - using real API models now
  final RxList<SellerDetails> featuredSellers = <SellerDetails>[].obs;
  final RxList<SellerDetails> newSellers = <SellerDetails>[].obs;
  final RxList<CategoryMaster> categories = <CategoryMaster>[].obs;
  final RxList<ViewedSellerItem> recentlyViewedSellers = <ViewedSellerItem>[].obs;
  final RxList<ViewedProductItem> recentlyViewedProducts = <ViewedProductItem>[].obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Load categories
      await _loadCategories();
      
      // Load recently viewed items
      await _loadRecentlyViewed();
      
      // For now, we don't load featured sellers from database
      // as per user request, but we can load some sample published sellers
      // await _loadFeaturedSellers();
      
    } catch (e) {
      errorMessage.value = 'Failed to load data: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      if (response.isSuccess && response.data != null) {
        categories.assignAll(response.data!);
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadRecentlyViewed() async {
    try {
      final response = await _viewedHistoryService.getRecentlyViewedItems(
        sellersLimit: 5,
        productsLimit: 5,
      );
      if (response.isSuccess && response.data != null) {
        recentlyViewedSellers.assignAll(response.data!.sellers);
        recentlyViewedProducts.assignAll(response.data!.products);
      }
    } catch (e) {
      print('Error loading recently viewed: $e');
    }
  }

  // Load some featured sellers (for future use)
  Future<void> _loadFeaturedSellers() async {
    try {
      final response = await _buyerService.searchSellers();
      if (response.isSuccess && response.data != null) {
        // Take first 5 as featured
        featuredSellers.assignAll(response.data!.take(5).toList());
        // Take next 3 as new sellers  
        if (response.data!.length > 5) {
          newSellers.assignAll(response.data!.skip(5).take(3).toList());
        }
      }
    } catch (e) {
      print('Error loading featured sellers: $e');
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void performSearch() async {
    if (searchQuery.value.trim().isEmpty) return;
    
    isSearching.value = true;
    
    try {
      // Navigate to search results with query
      Get.toNamed('/buyer-search', arguments: {
        'query': searchQuery.value.trim(),
      });
    } finally {
      isSearching.value = false;
    }
  }

  void changeTab(int index) {
    if (index == 1) {
      // Navigate to dedicated search screen instead of showing search tab
      Get.toNamed('/buyer-search');
    } else if (index == 2) {
      // Navigate to enquiry screen
      Get.toNamed('/buyer-enquiry');
    } else if (index == 3) {
      // Navigate to map screen
      Get.toNamed('/buyer-map');
    } else if (index == 4) {
      // Navigate to profile screen
      Get.toNamed('/buyer-profile');
    } else {
      currentIndex.value = index;
    }
  }

  void refreshData() async {
    isRefreshing.value = true;
    
    try {
      await _loadInitialData();
    } finally {
      isRefreshing.value = false;
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

  void browseCategory(int categoryId, String categoryName) {
    Get.toNamed('/buyer-search', arguments: {
      'categoryId': categoryId,
      'categoryName': categoryName,
    });
  }

  void openMap() {
    changeTab(3); // Map tab index
  }

  // Helper methods for UI
  String getCategoryName(int categoryId) {
    final category = categories.firstWhereOrNull((c) => c.catid == categoryId);
    return category?.catname ?? 'Category';
  }

  bool get hasRecentlyViewed => 
      recentlyViewedSellers.isNotEmpty || recentlyViewedProducts.isNotEmpty;

  bool get hasCategories => categories.isNotEmpty;
}

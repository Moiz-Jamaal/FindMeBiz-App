import 'package:get/get.dart';

class BuyerHomeController extends GetxController {
  // Current navigation index
  final RxInt currentIndex = 0.obs;
  
  // Search functionality
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  
  // Featured sellers (placeholder data)
  final RxList<Map<String, dynamic>> featuredSellers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> newSellers = <Map<String, dynamic>>[].obs;
  final RxList<String> categories = <String>[].obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  void _loadInitialData() {
    isLoading.value = true;
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      // Mock data for featured sellers
      featuredSellers.addAll([
        {
          'id': '1',
          'businessName': 'Surat Silk Emporium',
          'category': 'Apparel',
          'rating': 4.8,
          'image': 'https://via.placeholder.com/150',
          'stallNumber': 'A-23',
        },
        {
          'id': '2',
          'businessName': 'Gujarati Crafts',
          'category': 'Art & Crafts',
          'rating': 4.6,
          'image': 'https://via.placeholder.com/150',
          'stallNumber': 'B-12',
        },
        {
          'id': '3',
          'businessName': 'Spice Paradise',
          'category': 'Food & Beverages',
          'rating': 4.9,
          'image': 'https://via.placeholder.com/150',
          'stallNumber': 'C-45',
        },
      ]);
      
      // Mock data for new sellers
      newSellers.addAll([
        {
          'id': '4',
          'businessName': 'Diamond Jewelry',
          'category': 'Jewelry',
          'image': 'https://via.placeholder.com/150',
          'stallNumber': 'D-78',
        },
        {
          'id': '5',
          'businessName': 'Home Decor Plus',
          'category': 'Home Decor',
          'image': 'https://via.placeholder.com/150',
          'stallNumber': 'E-34',
        },
      ]);
      
      // Categories
      categories.addAll([
        'Apparel',
        'Jewelry',
        'Food & Beverages',
        'Art & Crafts',
        'Home Decor',
        'Electronics',
      ]);
      
      isLoading.value = false;
    });
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void performSearch() {
    if (searchQuery.value.trim().isEmpty) return;
    
    isSearching.value = true;
    
    // Simulate search
    Future.delayed(const Duration(milliseconds: 800), () {
      isSearching.value = false;
      // Navigate to search results
      Get.toNamed('/buyer-search', arguments: searchQuery.value);
    });
  }

  void changeTab(int index) {
    if (index == 1) {
      // Navigate to dedicated search screen instead of showing search tab
      Get.toNamed('/buyer-search');
    } else if (index == 2) {
      // Navigate to map screen
      Get.toNamed('/buyer-map');
    } else if (index == 3) {
      // Navigate to profile screen
      Get.toNamed('/buyer-profile');
    } else {
      currentIndex.value = index;
    }
  }

  void refreshData() {
    isRefreshing.value = true;
    
    Future.delayed(const Duration(seconds: 1), () {
      isRefreshing.value = false;
      // Refresh data logic here
    });
  }

  void viewSeller(String sellerId) {
    Get.toNamed('/buyer-seller-view', arguments: sellerId);
  }

  void browseCategory(String category) {
    Get.toNamed('/buyer-search', arguments: {'category': category});
  }

  void openMap() {
    changeTab(2); // Map tab index
  }
}

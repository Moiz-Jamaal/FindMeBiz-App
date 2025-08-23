import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/data/models/seller.dart';
import '../../../../services/buyer_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/viewed_history_service.dart';
import '../../../../services/product_service.dart';
import '../../../../data/models/api/index.dart';

class BuyerSearchController extends GetxController {
  // Services
  final BuyerService _buyerService = Get.find<BuyerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ViewedHistoryService _viewedHistoryService = Get.find<ViewedHistoryService>();
  
  // Search controllers
  final searchTextController = TextEditingController();
  
  // Search state
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Results
  final RxList<SellerDetails> sellerResults = <SellerDetails>[].obs;
  final RxList<Product> productResults = <Product>[].obs;
  final Rx<ProductSearchResponse?> productSearchResponse = Rx<ProductSearchResponse?>(null);
  
  // Filters
  final RxList<int> selectedCategoryIds = <int>[].obs;
  final RxString selectedCity = ''.obs;
  final RxString selectedArea = ''.obs;
  final RxString sortBy = 'createdat'.obs;
  final RxString sortOrder = 'desc'.obs;
  final RxString searchType = 'All'.obs; // All, Sellers, Products
  final Rx<double?> minPrice = Rx<double?>(null);
  final Rx<double?> maxPrice = Rx<double?>(null);
  
  // Filter options
  final RxList<CategoryMaster> availableCategories = <CategoryMaster>[].obs;
  final RxList<String> availableCities = <String>[].obs;
  final RxList<String> availableAreas = <String>[].obs;
  
  final List<String> sortOptions = [
    'createdat', // Recently Added
    'productname', // A to Z
    'price', // Price
  ];
  final List<String> sortOrderOptions = ['desc', 'asc'];
  final List<String> searchTypes = ['All', 'Sellers', 'Products'];
  
  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt pageSize = 20.obs;
  final RxBool hasMoreResults = false.obs;
  final RxBool isLoadingMore = false.obs;
  
  // UI state
  final RxBool showFilters = false.obs;
  final RxInt totalResultsCount = 0.obs;
  
  // Recent searches
  final RxList<String> recentSearches = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _setupSearchListener();
    
    // Check for arguments passed from other screens
    final arguments = Get.arguments;
    if (arguments != null) {
      _handleArguments(arguments);
    }
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  void _handleArguments(dynamic arguments) {
    if (arguments is String) {
      // Simple search query
      searchTextController.text = arguments;
      searchQuery.value = arguments;
      performSearch();
    } else if (arguments is Map<String, dynamic>) {
      // Advanced search with filters
      if (arguments['query'] != null) {
        searchTextController.text = arguments['query'];
        searchQuery.value = arguments['query'];
      }
      if (arguments['categoryId'] != null) {
        selectedCategoryIds.add(arguments['categoryId']);
      }
      if (arguments['categoryName'] != null) {
        // Find category by name and add ID
        final category = availableCategories.firstWhereOrNull(
          (c) => c.catname == arguments['categoryName'],
        );
        if (category != null) {
          selectedCategoryIds.add(category.catid!);
        }
      }
      performSearch();
    }
  }

  void _loadInitialData() async {
    try {
      await _loadCategories();
      await _loadRecentSearches();
    } catch (e) {
      errorMessage.value = 'Failed to load initial data: ${e.toString()}';
    }
  }

  Future<void> _loadCategories() async {
  
      final response = await _categoryService.getCategories();
      if (response.isSuccess && response.data != null) {
        availableCategories.assignAll(response.data!);
      }
 
  }

  Future<void> _loadRecentSearches() async {
    // TODO: Load from local storage or user preferences API
    // For now, start with empty list - will be populated as user searches
    recentSearches.clear();
  }

  void _setupSearchListener() {
    // Debounced search as user types
    searchTextController.addListener(() {
      if (searchTextController.text != searchQuery.value) {
        searchQuery.value = searchTextController.text;
        
        if (searchQuery.value.length >= 2) {
          _debounceSearch();
        } else if (searchQuery.value.isEmpty) {
          _clearResults();
        }
      }
    });
  }

  void _debounceSearch() {
    // Simple debounce simulation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (searchQuery.value == searchTextController.text && searchQuery.value.length >= 2) {
        performSearch();
      }
    });
  }
  Future<void> performSearch({String? query, bool resetPage = true}) async {
    final searchTerm = query ?? searchQuery.value;
    if (searchTerm.trim().isEmpty && selectedCategoryIds.isEmpty) return;

    isSearching.value = true;
    errorMessage.value = '';
    
    if (resetPage) {
      currentPage.value = 1;
      sellerResults.clear();
      productResults.clear();
    }

    hasSearched.value = true;

    // Add to recent searches
    if (searchTerm.isNotEmpty && !recentSearches.contains(searchTerm.toLowerCase())) {
      recentSearches.insert(0, searchTerm.toLowerCase());
      if (recentSearches.length > 10) {
        recentSearches.removeLast();
      }
    }

    try {
      if (searchType.value == 'All' || searchType.value == 'Sellers') {
        await _searchSellers(searchTerm);
      }
      
      if (searchType.value == 'All' || searchType.value == 'Products') {
        await _searchProducts(searchTerm);
      }
      
      _updateResultsCount();
    } catch (e) {
      errorMessage.value = 'Search failed: ${e.toString()}';
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> _searchSellers(String query) async {
 
      final response = await _buyerService.searchSellers(
        businessName: query.isNotEmpty ? query : null,
        city: selectedCity.value.isNotEmpty ? selectedCity.value : null,
        area: selectedArea.value.isNotEmpty ? selectedArea.value : null,
        categoryId: selectedCategoryIds.isNotEmpty ? selectedCategoryIds.first : null,
      );
      
      if (response.isSuccess && response.data != null) {
        if (currentPage.value == 1) {
          sellerResults.assignAll(response.data!);
        } else {
          sellerResults.addAll(response.data!);
        }
      }
   
  }

  Future<void> _searchProducts(String query) async {
 
      final response = await _buyerService.searchProducts(
        productName: query.isNotEmpty ? query : null,
        categoryIds: selectedCategoryIds.isNotEmpty ? selectedCategoryIds : null,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        city: selectedCity.value.isNotEmpty ? selectedCity.value : null,
        area: selectedArea.value.isNotEmpty ? selectedArea.value : null,
        page: currentPage.value,
        pageSize: pageSize.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );
      
      if (response.isSuccess && response.data != null) {
        productSearchResponse.value = response.data!;
        
        if (currentPage.value == 1) {
          productResults.assignAll(response.data!.products);
        } else {
          productResults.addAll(response.data!.products);
        }
        
        hasMoreResults.value = response.data!.hasNextPage;
      }
  
  }

  void loadMoreResults() async {
    if (isLoadingMore.value || !hasMoreResults.value) return;
    
    isLoadingMore.value = true;
    currentPage.value++;
    
    try {
      await performSearch(resetPage: false);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _updateResultsCount() {
    totalResultsCount.value = sellerResults.length + productResults.length;
  }

  void _clearResults() {
    sellerResults.clear();
    productResults.clear();
    productSearchResponse.value = null;
    hasSearched.value = false;
    totalResultsCount.value = 0;
    currentPage.value = 1;
    hasMoreResults.value = false;
  }

  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    _clearResults();
    _clearFilters();
  }

  void _clearFilters() {
    selectedCategoryIds.clear();
    selectedCity.value = '';
    selectedArea.value = '';
    minPrice.value = null;
    maxPrice.value = null;
    sortBy.value = 'createdat';
    sortOrder.value = 'desc';
    searchType.value = 'All';
  }

  void selectRecentSearch(String query) {
    searchTextController.text = query;
    searchQuery.value = query;
    performSearch(query: query);
  }

  // Filter methods
  void addCategoryFilter(int categoryId) {
    if (!selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.add(categoryId);
      if (hasSearched.value) {
        performSearch();
      }
    }
  }

  void removeCategoryFilter(int categoryId) {
    selectedCategoryIds.remove(categoryId);
    if (hasSearched.value) {
      performSearch();
    }
  }

  void updateCity(String city) {
    selectedCity.value = city;
    if (hasSearched.value) {
      performSearch();
    }
  }

  void updateArea(String area) {
    selectedArea.value = area;
    if (hasSearched.value) {
      performSearch();
    }
  }

  void updatePriceRange(double? min, double? max) {
    minPrice.value = min;
    maxPrice.value = max;
    if (hasSearched.value) {
      performSearch();
    }
  }

  void updateSortBy(String sort) {
    sortBy.value = sort;
    if (hasSearched.value) {
      performSearch();
    }
  }

  void updateSortOrder(String order) {
    sortOrder.value = order;
    if (hasSearched.value) {
      performSearch();
    }
  }

  void updateSearchType(String type) {
    searchType.value = type;
    _clearResults();
    if (hasSearched.value) {
      performSearch();
    }
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  // Navigation methods with debouncing
  DateTime? _lastSellerViewTime;
  DateTime? _lastProductViewTime;
  
  void viewSeller(dynamic sellerData) async {
    // Debounce rapid taps
    final now = DateTime.now();
    if (_lastSellerViewTime != null && 
        now.difference(_lastSellerViewTime!).inMilliseconds < 1000) {
      return; // Ignore rapid taps within 1 second
    }
    _lastSellerViewTime = now;
    
    int? sellerId;
    dynamic sellerToPass;
    
    if (sellerData is int) {
      // Just seller ID passed - use it directly
      sellerId = sellerData;
      sellerToPass = sellerId;
    } else if (sellerData != null && sellerData.sellerid != null) {
      // Complete SellerDetails object passed - convert it to Seller model
      sellerId = sellerData.sellerid;
      sellerToPass = _convertSellerDetailsToSeller(sellerData);
      
    } else {
      
      return;
    }
    
    try {
      // Record the view
      if (sellerId != null) {
        await _viewedHistoryService.recordSellerView(sellerId);
      }
    } catch (e) {
      
      // Continue with navigation even if recording fails
    }
    
    // Navigate to seller view with the seller data
    Get.toNamed('/buyer-seller-view', arguments: sellerToPass);
  }

  // Convert SellerDetails from search API to Seller model
  Seller _convertSellerDetailsToSeller(dynamic sellerDetails) {
    return Seller(
      id: sellerDetails.sellerid?.toString() ?? '0',
      email: '', // Email is not available in SellerDetails API model
      fullName: sellerDetails.profilename ?? 'Business Owner',
      createdAt: DateTime.now().subtract(const Duration(days: 30)), // TODO: Use actual created date from API
      updatedAt: DateTime.now(),
      businessName: sellerDetails.businessname ?? 'Local Business',
      bio: sellerDetails.bio ?? 'Welcome to our business!',
      whatsappNumber: sellerDetails.whatsappno ?? sellerDetails.mobileno,
      stallLocation: StallLocation(
        latitude: _parseLatitude(sellerDetails.geolocation),
        longitude: _parseLongitude(sellerDetails.geolocation),
        stallNumber: _generateStallNumber(sellerDetails.sellerid),
        area: sellerDetails.area ?? 'Business Area',
        address: sellerDetails.address,
      ),
      businessLogo: sellerDetails.logo, // Should have fresh presigned URL from backend
      isProfilePublished: sellerDetails.ispublished ?? true,
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

  void viewProduct(dynamic productData) async {
    // Debounce rapid taps
    final now = DateTime.now();
    if (_lastProductViewTime != null && 
        now.difference(_lastProductViewTime!).inMilliseconds < 1000) {
      return; // Ignore rapid taps within 1 second
    }
    _lastProductViewTime = now;
    
    int? productId;
    
    // Handle different types of product data
    if (productData is int && productData > 0) {
      productId = productData;
    } else if (productData is String) {
      productId = int.tryParse(productData);
    } else if (productData != null && productData.id != null) {
      // Product object with ID property
      if (productData.id is int) {
        productId = productData.id as int;
      } else if (productData.id is String) {
        productId = int.tryParse(productData.id as String);
      }
    }
    
    // Validate product ID before proceeding
    if (productId == null || productId <= 0) {
      
      Get.snackbar(
        'Error',
        'Invalid product information. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      // Record the view
      await _viewedHistoryService.recordProductView(productId);
    } catch (e) {
      
      // Continue with navigation even if recording fails
    }
    
    // Navigate to product view with the product ID
    
    Get.toNamed('/buyer-product-view', arguments: productId);
  }

  // Helper methods
  String getCategoryName(int categoryId) {
    final category = availableCategories.firstWhereOrNull((c) => c.catid == categoryId);
    return category?.catname ?? 'Category';
  }

  List<String> getSelectedCategoryNames() {
    return selectedCategoryIds
        .map((id) => getCategoryName(id))
        .toList();
  }

  bool get hasActiveFilters =>
      selectedCategoryIds.isNotEmpty ||
      selectedCity.value.isNotEmpty ||
      selectedArea.value.isNotEmpty ||
      minPrice.value != null ||
      maxPrice.value != null;

  bool get hasSellerResults => sellerResults.isNotEmpty;
  bool get hasProductResults => productResults.isNotEmpty;
  bool get hasAnyResults => hasSellerResults || hasProductResults;

  String get resultsCountText {
    if (!hasSearched.value) return '';
    
    final sellerCount = sellerResults.length;
    final productCount = productResults.length;
    final totalCount = productSearchResponse.value?.totalCount ?? productCount;
    
    if (searchType.value == 'Sellers') {
      return '$sellerCount seller${sellerCount != 1 ? 's' : ''} found';
    } else if (searchType.value == 'Products') {
      return '$totalCount product${totalCount != 1 ? 's' : ''} found';
    } else {
      return '$sellerCount seller${sellerCount != 1 ? 's' : ''}, $totalCount product${totalCount != 1 ? 's' : ''} found';
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/data/models/seller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final ProductService _productService = ProductService.instance;
  
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
  
  // Debounce and request tracking
  Timer? _debounceTimer;
  int _searchToken = 0; // monotonically increasing token to ignore stale searches
  
  // Location methods
  Future<void> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Disabled',
          'Please enable location services in your device settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required for nearby search',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Get.dialog(
          AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text('Location permission is permanently denied. Please enable it in app settings to use nearby search.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  openAppSettings();
                },
                child: const Text('Settings'),
              ),
            ],
          ),
        );
        return;
      }

      // Show loading
      Get.snackbar(
        'Getting Location',
        'Please wait while we get your current location...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      userLatitude.value = position.latitude;
      userLongitude.value = position.longitude;
      useLocation.value = true;
      
      Get.snackbar(
        'Location Found',
        'Loading nearby sellers...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Automatically search for nearby sellers
      await _searchNearbySellers();
      
    } on LocationServiceDisabledException {
      Get.snackbar(
        'Location Services Disabled',
        'Please enable location services in your device settings',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } on PermissionDeniedException {
      Get.snackbar(
        'Permission Denied',
        'Location permission is required for nearby search',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } on TimeoutException {
      Get.snackbar(
        'Location Timeout',
        'Could not get location. Please try again or check GPS signal',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
Get.snackbar(
        'Location Error',
        'Could not get location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Auto-search nearby sellers when location is obtained
  Future<void> _searchNearbySellers() async {
    try {
      isSearching.value = true;
      hasSearched.value = true;
      
      // Clear previous results
      sellerResults.clear();
      productResults.clear();
      currentPage.value = 1;
      
      // Search for nearby sellers without any search query
      await _searchSellers('');
      
      _updateResultsCount();
      
      if (sellerResults.isNotEmpty) {
        Get.snackbar(
          'Nearby Sellers Found',
          'Found ${sellerResults.length} sellers near you',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'No Nearby Sellers',
          'No sellers found within ${radiusKm.value.toInt()} km',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to load nearby sellers: ${e.toString()}';
    } finally {
      isSearching.value = false;
    }
  }

  void toggleLocationSearch() async {
    if (useLocation.value) {
      // Disable location search
      useLocation.value = false;
      if (hasSearched.value) {
        performSearch();
      }
    } else {
      // Enable location search - get current location
      await getCurrentLocation();
    }
  }

  // Check if we have valid location data
  bool get hasValidLocation => 
      userLatitude.value != null && 
      userLongitude.value != null &&
      userLatitude.value! >= -90 && 
      userLatitude.value! <= 90 &&
      userLongitude.value! >= -180 && 
      userLongitude.value! <= 180;

  // Location-based search
  final Rx<double?> userLatitude = Rx<double?>(null);
  final Rx<double?> userLongitude = Rx<double?>(null);
  final RxDouble radiusKm = 10.0.obs;
  final RxBool useLocation = false.obs;
  
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
  // Clean up controllers and timers
  _debounceTimer?.cancel();
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
  
  final response = await _categoryService.getAvailableCategories();
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
    // Debounced search as user types (cancellable)
    searchTextController.addListener(() {
      final text = searchTextController.text;
      if (text != searchQuery.value) {
        searchQuery.value = text;
        // Cancel any pending debounce
        _debounceTimer?.cancel();
        if (text.length >= 2) {
          _debounceTimer = Timer(const Duration(milliseconds: 600), () {
            // Ensure the text hasn't changed during the debounce period
            if (searchQuery.value == searchTextController.text) {
              // If user typed an exact category name, sync selectedCategoryIds
              _syncCategoryFromTypedQuery();
              performSearch();
            }
          });
        } else if (text.isEmpty) {
          _clearResults();
        }
      }
    });
  }

  // If the typed query exactly matches a known category name, set that as the only selected category
  void _syncCategoryFromTypedQuery() {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return;
    final match = availableCategories.firstWhereOrNull(
      (c) => (c.catname).toLowerCase() == q,
    );
    if (match != null && match.catid != null) {
      // Avoid duplicates and keep it single-source-of-truth
      selectedCategoryIds
        ..clear()
        ..add(match.catid!);
    }
  }

  // Removed legacy _debounceSearch in favor of Timer-based listener
  Future<void> performSearch({String? query, bool resetPage = true}) async {
  final searchTerm = query ?? searchQuery.value;
    if (searchTerm.trim().isEmpty && selectedCategoryIds.isEmpty) return;

    // Increment token to invalidate any in-flight older searches
    final int token = ++_searchToken;

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
        await _searchSellers(searchTerm, token: token);
      }
      
      if (searchType.value == 'All' || searchType.value == 'Products') {
  await _searchProducts(searchTerm, token: token);
      }
      // Only update counts if this is still the latest search
      if (token == _searchToken) {
        _updateResultsCount();
      }
    } catch (e) {
      errorMessage.value = 'Search failed: ${e.toString()}';
    } finally {
      // Avoid toggling off loading for stale searches
      if (token == _searchToken) {
        isSearching.value = false;
      }
    }
  }

  Future<void> _searchSellers(String query, {int? token}) async {
    try {
      String? effectiveQuery;
      if (query.isNotEmpty) {
        final isExactCategory = availableCategories.any((c) =>
          c.catname.toLowerCase() == query.trim().toLowerCase());
        effectiveQuery = isExactCategory ? null : query;
      }
      final response = await _buyerService.searchSellers(
        businessName: (effectiveQuery != null && effectiveQuery.isNotEmpty) ? effectiveQuery : null,
        city: selectedCity.value.isNotEmpty ? selectedCity.value : null,
        area: selectedArea.value.isNotEmpty ? selectedArea.value : null,
        categoryId: selectedCategoryIds.isNotEmpty ? selectedCategoryIds.first : null,
        address: null, // Can add address filter if needed
        userLat: useLocation.value ? userLatitude.value : null,
        userLng: useLocation.value ? userLongitude.value : null,
        radiusKm: useLocation.value ? radiusKm.value : null,
      );
      
      // Ignore stale responses
      if (token != null && token != _searchToken) return;

      if (response.isSuccess && response.data != null) {
        if (currentPage.value == 1) {
          sellerResults.assignAll(response.data!);
        } else {
          sellerResults.addAll(response.data!);
        }
      }
    } catch (e) {
}
  }

  Future<void> _searchProducts(String query, {int? token}) async {
      // If the typed query exactly matches a selected category's name,
      // avoid passing productName to prevent conflicting filters and improve relevance.
      String? effectiveQuery;
      if (query.isNotEmpty) {
        final isExactCategory = availableCategories.any((c) =>
          c.catname.toLowerCase() == query.trim().toLowerCase());
        effectiveQuery = isExactCategory ? null : query;
      }

    // Pass category name for backends that filter by name
    final selectedName = (selectedCategoryIds.isNotEmpty)
      ? availableCategories.firstWhereOrNull((c) => c.catid == selectedCategoryIds.first)?.catname
      : null;

  final response = await _productService.searchProducts(
        productName: (effectiveQuery != null && effectiveQuery.isNotEmpty) ? effectiveQuery : null,
        categoryIds: selectedCategoryIds.isNotEmpty ? selectedCategoryIds : null,
        categoryName: selectedName,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        city: selectedCity.value.isNotEmpty ? selectedCity.value : null,
        area: selectedArea.value.isNotEmpty ? selectedArea.value : null,
        page: currentPage.value,
        pageSize: pageSize.value,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );
      
      // Ignore stale responses
      if (token != null && token != _searchToken) return;

      if (response.isSuccess && response.data != null) {
        // Apply client-side category filter as a safety net if backend doesn't filter correctly.
        List<Product> fetched = response.data!.products;
        if (selectedCategoryIds.isNotEmpty || (selectedName != null && selectedName.isNotEmpty)) {
          final selIds = selectedCategoryIds.toList();
          final selNameLower = selectedName?.toLowerCase();
          fetched = fetched.where((p) {
            bool byId = selIds.isEmpty
                ? true
                : (p.productCategories?.any((pc) => selIds.contains(pc.catId)) ?? false);
            if (!byId) return false;
            if (selNameLower == null || selNameLower.isEmpty) return true;
            final names = p.categoryNames ?? p.categories;
            return names.any((n) => n.toLowerCase() == selNameLower);
          }).toList();
        }

        if (currentPage.value == 1) {
          productResults.assignAll(fetched);
        } else {
          productResults.addAll(fetched);
        }

        // Keep original paging flags from server
        productSearchResponse.value = response.data!;
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

  // Unified handler when user taps a category chip/card in UI
  void onCategorySelected(CategoryMaster category) {
    final id = category.catid;
    if (id == null) return;
    // Put category name into the textbox so user sees what is searched
    final name = category.catname;
    searchTextController.text = name;
    searchQuery.value = name;
    // Ensure only this category is selected for relevance
    selectedCategoryIds
      ..clear()
      ..add(id);
    // Reset pagination and run search
    performSearch(query: name, resetPage: true);
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

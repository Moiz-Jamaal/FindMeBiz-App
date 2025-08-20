import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/seller.dart';
import '../../../../data/models/product.dart';
import '../../../../core/constants/app_constants.dart';

class SearchController extends GetxController {
  // Search controllers
  final searchTextController = TextEditingController();
  
  // Search state
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  
  // Results
  final RxList<Seller> searchResults = <Seller>[].obs;
  final RxList<Product> productResults = <Product>[].obs;
  
  // Filters
  final RxList<String> selectedCategories = <String>[].obs;
  final RxString selectedLocation = 'All Areas'.obs;
  final RxString sortBy = 'Relevance'.obs;
  final RxString searchType = 'All'.obs; // All, Sellers, Products
  
  // Filter options
  final List<String> categories = ['All', ...AppConstants.productCategories];
  final List<String> locations = [
    'All Areas',
    'Main Entrance',
    'Food Court',
    'Handicraft Section', 
    'Textile Zone',
    'Electronics Area',
    'Art & Crafts Zone',
  ];
  final List<String> sortOptions = [
    'Relevance',
    'Rating (High to Low)',
    'Distance (Near to Far)',
    'Recently Added',
    'A to Z',
  ];
  final List<String> searchTypes = ['All', 'Sellers', 'Products'];
  
  // UI state
  final RxBool showFilters = false.obs;
  final RxInt activeResultsCount = 0.obs;
  
  // Recent searches
  final RxList<String> recentSearches = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _setupSearchListener();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery.value == searchTextController.text && searchQuery.value.length >= 2) {
        performSearch();
      }
    });
  }

  void _loadRecentSearches() {
    // Mock recent searches
    recentSearches.addAll([
      'silk sarees',
      'handmade jewelry',
      'gujarati food',
      'traditional crafts',
    ]);
  }

  void performSearch({String? query}) {
    final searchTerm = query ?? searchQuery.value;
    if (searchTerm.trim().isEmpty) return;

    isSearching.value = true;
    hasSearched.value = true;

    // Add to recent searches
    if (!recentSearches.contains(searchTerm.toLowerCase())) {
      recentSearches.insert(0, searchTerm.toLowerCase());
      if (recentSearches.length > 10) {
        recentSearches.removeLast();
      }
    }

    // Simulate search API call
    Future.delayed(const Duration(milliseconds: 800), () {
      _mockSearch(searchTerm);
      isSearching.value = false;
    });
  }

  void _mockSearch(String query) {
    // Mock search results
    final mockSellers = _getMockSellers();
    final mockProducts = _getMockProducts();
    
    // Filter based on search query
    searchResults.clear();
    productResults.clear();
    
    // Simple text matching
    for (final seller in mockSellers) {
      if (_matchesQuery(seller.businessName, query) ||
          _matchesQuery(seller.bio ?? '', query) ||
          _matchesQuery(seller.fullName, query)) {
        searchResults.add(seller);
      }
    }
    
    for (final product in mockProducts) {
      if (_matchesQuery(product.name, query) ||
          _matchesQuery(product.description ?? '', query) ||
          (product.categories.isNotEmpty && _matchesQuery(product.categories.first, query))) {
        productResults.add(product);
      }
    }
    
    // Apply filters
    _applyFilters();
    _applySorting();
    
    _updateResultsCount();
  }

  bool _matchesQuery(String text, String query) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  void _applyFilters() {
    // Filter by categories
    if (selectedCategories.isNotEmpty && !selectedCategories.contains('All')) {
      searchResults.removeWhere((seller) => 
          !selectedCategories.contains('All')); // Simplified for sellers
      
      productResults.removeWhere((product) => 
          product.categories.isEmpty || !selectedCategories.any((cat) => product.categories.contains(cat)));
    }
    
    // Filter by search type
    if (searchType.value == 'Sellers') {
      productResults.clear();
    } else if (searchType.value == 'Products') {
      searchResults.clear();
    }
  }

  void _applySorting() {
    switch (sortBy.value) {
      case 'A to Z':
        searchResults.sort((a, b) => a.businessName.compareTo(b.businessName));
        productResults.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Recently Added':
        searchResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        productResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      // Add more sorting options as needed
    }
  }

  void _updateResultsCount() {
    activeResultsCount.value = searchResults.length + productResults.length;
  }

  void _clearResults() {
    searchResults.clear();
    productResults.clear();
    hasSearched.value = false;
    activeResultsCount.value = 0;
  }

  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    _clearResults();
  }

  void selectRecentSearch(String query) {
    searchTextController.text = query;
    searchQuery.value = query;
    performSearch(query: query);
  }

  void addCategoryFilter(String category) {
    if (!selectedCategories.contains(category)) {
      selectedCategories.add(category);
      if (hasSearched.value) {
        _mockSearch(searchQuery.value);
      }
    }
  }

  void removeCategoryFilter(String category) {
    selectedCategories.remove(category);
    if (hasSearched.value) {
      _mockSearch(searchQuery.value);
    }
  }

  void updateSortBy(String sort) {
    sortBy.value = sort;
    if (hasSearched.value) {
      _applySorting();
    }
  }

  void updateSearchType(String type) {
    searchType.value = type;
    if (hasSearched.value) {
      _mockSearch(searchQuery.value);
    }
  }

  void updateLocation(String location) {
    selectedLocation.value = location;
    if (hasSearched.value) {
      _mockSearch(searchQuery.value);
    }
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void viewSeller(Seller seller) {
    Get.toNamed('/buyer-seller-view', arguments: seller);
  }

  void viewProduct(Product product) {
    Get.toNamed('/buyer-product-view', arguments: product);
  }

  // Mock data generators
  List<Seller> _getMockSellers() {
    return [
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
      Seller(
        id: '4',
        email: 'priya@food.com',
        fullName: 'Priya Desai',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        businessName: 'Gujarati Delights',
        bio: 'Authentic Gujarati cuisine and traditional sweets.',
        whatsappNumber: '+91 98765 43213',
        stallLocation: StallLocation(
          latitude: 21.1705,
          longitude: 72.8320,
          stallNumber: 'D-78',
          area: 'Food Court',
        ),
        isProfilePublished: true,
      ),
    ];
  }

  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1', sellerId: '1', name: 'Premium Silk Saree',
        description: 'Beautiful Banarasi silk saree with gold thread work',
        price: 5500.0, categories: ['Apparel'], images: ['mock1'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2', sellerId: '2', name: 'Handwoven Wall Hanging',
        description: 'Traditional Gujarati wall art with mirror work',
        price: 1200.0, categories: ['Art & Crafts'], images: ['mock2'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '3', sellerId: '3', name: 'Diamond Necklace Set',
        description: 'Elegant diamond necklace with matching earrings',
        price: 25000.0, categories: ['Jewelry'], images: ['mock3'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '4', sellerId: '4', name: 'Gujarati Thali',
        description: 'Complete traditional Gujarati meal with 12 varieties',
        price: 350.0, categories: ['Food & Beverages'], images: ['mock4'],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

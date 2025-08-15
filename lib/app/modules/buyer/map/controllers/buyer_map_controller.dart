import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/seller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/communication_service.dart';
import '../../../../services/analytics_service.dart';

class BuyerMapController extends GetxController {
  // Map state
  final RxDouble currentLatitude = AppConstants.defaultLatitude.obs;
  final RxDouble currentLongitude = AppConstants.defaultLongitude.obs;
  final RxDouble currentZoom = AppConstants.defaultZoom.obs;
  
  // Sellers data
  final RxList<Seller> allSellers = <Seller>[].obs;
  final RxList<Seller> visibleSellers = <Seller>[].obs;
  
  // Selected seller
  final Rx<Seller?> selectedSeller = Rx<Seller?>(null);
  final RxBool showSellerPreview = false.obs;
  
  // Filters
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedArea = 'All Areas'.obs;
  final RxBool showOnlyFavorites = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool showFilters = false.obs;
  
  // Filter options
  final List<String> categories = ['All', ...AppConstants.productCategories];
  final List<String> areas = [
    'All Areas',
    'Main Entrance',
    'Food Court', 
    'Handicraft Section',
    'Textile Zone',
    'Electronics Area',
    'Art & Crafts Zone',
  ];
  
  // Favorites (simulated)
  final RxList<String> favoriteSellerIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSellersData();
  }

  void _loadSellersData() {
    isLoading.value = true;
    
    // Simulate API call to load all published sellers
    Future.delayed(const Duration(seconds: 1), () {
      allSellers.addAll(_getMockSellers());
      _applyFilters();
      isLoading.value = false;
    });
  }

  void _applyFilters() {
    var filtered = allSellers.toList();
    
    // Filter by category
    if (selectedCategory.value != 'All') {
      // In real app, filter by seller's main category or products
      // For now, we'll show all sellers for any category selection
    }
    
    // Filter by area
    if (selectedArea.value != 'All Areas') {
      filtered = filtered.where((seller) {
        return seller.stallLocation?.area == selectedArea.value;
      }).toList();
    }
    
    // Filter by favorites
    if (showOnlyFavorites.value) {
      filtered = filtered.where((seller) {
        return favoriteSellerIds.contains(seller.id);
      }).toList();
    }
    
    visibleSellers.assignAll(filtered);
  }

  void selectSeller(Seller seller) {
    selectedSeller.value = seller;
    showSellerPreview.value = true;
    
    // Center map on selected seller
    if (seller.stallLocation != null) {
      currentLatitude.value = seller.stallLocation!.latitude;
      currentLongitude.value = seller.stallLocation!.longitude;
    }
  }

  void deselectSeller() {
    selectedSeller.value = null;
    showSellerPreview.value = false;
  }

  void viewSellerProfile() {
    if (selectedSeller.value != null) {
      Get.toNamed('/buyer-seller-view', arguments: selectedSeller.value);
    }
  }

  void contactSeller() {
    if (selectedSeller.value != null) {
      final seller = selectedSeller.value!;
      
      CommunicationService.to.showContactOptionsDialog(
        businessName: seller.businessName,
        phoneNumber: seller.whatsappNumber,
        whatsappNumber: seller.whatsappNumber,
        email: seller.email,
        latitude: seller.stallLocation?.latitude,
        longitude: seller.stallLocation?.longitude,
        address: seller.stallLocation?.address,
      );
    }
  }

  void toggleFavorite(Seller seller) {
    if (favoriteSellerIds.contains(seller.id)) {
      favoriteSellerIds.remove(seller.id);
    } else {
      favoriteSellerIds.add(seller.id);
    }
    
    // Reapply filters if showing only favorites
    if (showOnlyFavorites.value) {
      _applyFilters();
    }
  }

  bool isFavorite(String sellerId) {
    return favoriteSellerIds.contains(sellerId);
  }

  void updateCategoryFilter(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void updateAreaFilter(String area) {
    selectedArea.value = area;
    _applyFilters();
  }

  void toggleFavoritesFilter() {
    showOnlyFavorites.value = !showOnlyFavorites.value;
    _applyFilters();
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void zoomIn() {
    if (currentZoom.value < AppConstants.maxZoom) {
      currentZoom.value = currentZoom.value + 1;
    }
  }

  void zoomOut() {
    if (currentZoom.value > AppConstants.minZoom) {
      currentZoom.value = currentZoom.value - 1;
    }
  }

  void centerOnUserLocation() {
    // Simulate getting user location
    Get.snackbar(
      'Location',
      'Centering map on your location...',
      snackPosition: SnackPosition.BOTTOM,
    );
    
    // Mock user location (slightly offset from default)
    currentLatitude.value = AppConstants.defaultLatitude + 0.001;
    currentLongitude.value = AppConstants.defaultLongitude + 0.001;
  }

  void resetMapView() {
    currentLatitude.value = AppConstants.defaultLatitude;
    currentLongitude.value = AppConstants.defaultLongitude;
    currentZoom.value = AppConstants.defaultZoom;
    deselectSeller();
  }

  void getDirectionsToSeller(Seller seller) {
    if (seller.stallLocation == null) {
      Get.snackbar(
        'Directions',
        'Location not available for this seller',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    CommunicationService.to.launchDirections(
      latitude: seller.stallLocation!.latitude,
      longitude: seller.stallLocation!.longitude,
      businessName: seller.businessName,
      address: seller.stallLocation!.address,
    );
    AnalyticsService.to.logEvent('buyer_get_directions', parameters: {
      'seller_id': seller.id,
      'lat': seller.stallLocation!.latitude,
      'lng': seller.stallLocation!.longitude,
    });
  }

  // Mock sellers data with locations
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
          address: 'Textile Zone, Istefada Ground, Surat',
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
          address: 'Handicraft Section, Istefada Ground, Surat',
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
          address: 'Main Entrance, Istefada Ground, Surat',
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
          address: 'Food Court, Istefada Ground, Surat',
        ),
        isProfilePublished: true,
      ),
      Seller(
        id: '5',
        email: 'kiran@electronics.com',
        fullName: 'Kiran Modi',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
        businessName: 'Tech Solutions',
        bio: 'Latest gadgets and electronic accessories.',
        whatsappNumber: '+91 98765 43214',
        stallLocation: StallLocation(
          latitude: 21.1697,
          longitude: 72.8312,
          stallNumber: 'E-56',
          area: 'Electronics Area',
          address: 'Electronics Area, Istefada Ground, Surat',
        ),
        isProfilePublished: true,
      ),
      Seller(
        id: '6',
        email: 'ravi@arts.com',
        fullName: 'Ravi Sharma',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now(),
        businessName: 'Creative Arts Studio',
        bio: 'Paintings, sculptures and handmade art pieces.',
        whatsappNumber: '+91 98765 43215',
        stallLocation: StallLocation(
          latitude: 21.1703,
          longitude: 72.8307,
          stallNumber: 'F-34',
          area: 'Art & Crafts Zone',
          address: 'Art & Crafts Zone, Istefada Ground, Surat',
        ),
        isProfilePublished: true,
      ),
    ];
  }

  String get filterStatusText {
    final activeFilters = <String>[];
    
    if (selectedCategory.value != 'All') {
      activeFilters.add(selectedCategory.value);
    }
    
    if (selectedArea.value != 'All Areas') {
      activeFilters.add(selectedArea.value);
    }
    
    if (showOnlyFavorites.value) {
      activeFilters.add('Favorites');
    }
    
    if (activeFilters.isEmpty) {
      return 'Showing all ${visibleSellers.length} sellers';
    } else {
      return 'Filtered: ${activeFilters.join(', ')} (${visibleSellers.length} sellers)';
    }
  }

  int get activeFiltersCount {
    int count = 0;
    if (selectedCategory.value != 'All') count++;
    if (selectedArea.value != 'All Areas') count++;
    if (showOnlyFavorites.value) count++;
    return count;
  }
}

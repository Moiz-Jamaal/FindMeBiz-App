import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/seller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class StallLocationController extends GetxController {
  // Map related
  final RxDouble selectedLatitude = AppConstants.defaultLatitude.obs;
  final RxDouble selectedLongitude = AppConstants.defaultLongitude.obs;
  final RxDouble currentZoom = AppConstants.defaultZoom.obs;
  
  // Form controllers
  final stallNumberController = TextEditingController();
  final areaController = TextEditingController();
  final addressController = TextEditingController();
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool hasLocationSelected = false.obs;
  final RxString locationSearchQuery = ''.obs;
  
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _loadExistingLocation();
  }

  @override
  void onClose() {
    stallNumberController.dispose();
    areaController.dispose();
    addressController.dispose();
    super.onClose();
  }

  void _loadExistingLocation() {
    // Load existing stall location if available
    // In a real app, this would come from the current seller's profile
    _setDefaultLocation();
  }

  void _setDefaultLocation() {
    // Set default to Surat coordinates
    selectedLatitude.value = AppConstants.defaultLatitude;
    selectedLongitude.value = AppConstants.defaultLongitude;
    hasLocationSelected.value = false;
  }

  void onMapTap(double latitude, double longitude) {
    selectedLatitude.value = latitude;
    selectedLongitude.value = longitude;
    hasLocationSelected.value = true;
    
    // Reverse geocoding simulation (would be real API call)
    _updateAddressFromCoordinates(latitude, longitude);
    
    Get.snackbar(
      'Location Selected',
      'Tap "Save Location" to confirm your stall position',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _updateAddressFromCoordinates(double lat, double lng) {
    // Simulate reverse geocoding
    // In a real app, this would use Google Maps Geocoding API
    Future.delayed(const Duration(milliseconds: 500), () {
      addressController.text = 'Istefada Ground, Surat, Gujarat, India';
    });
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

  void resetToDefault() {
    _setDefaultLocation();
    stallNumberController.clear();
    areaController.clear();
    addressController.clear();
  }

  void useCurrentLocation() {
    // Simulate getting current location
    isLoading.value = true;
    
    Future.delayed(const Duration(seconds: 2), () {
      // Mock current location (would be real GPS in actual app)
      selectedLatitude.value = 21.1698 + (0.001 * (DateTime.now().millisecondsSinceEpoch % 10));
      selectedLongitude.value = 72.8309 + (0.001 * (DateTime.now().millisecondsSinceEpoch % 10));
      hasLocationSelected.value = true;
      isLoading.value = false;
      
      _updateAddressFromCoordinates(
        selectedLatitude.value, 
        selectedLongitude.value,
      );
      
      Get.snackbar(
        'Location Found',
        'Using your current location',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    });
  }

  void searchLocation(String query) {
    if (query.trim().isEmpty) return;
    
    locationSearchQuery.value = query;
    isLoading.value = true;
    
    // Simulate location search
    Future.delayed(const Duration(seconds: 1), () {
      // Mock search result (would be real geocoding in actual app)
      selectedLatitude.value = AppConstants.defaultLatitude + 0.001;
      selectedLongitude.value = AppConstants.defaultLongitude + 0.001;
      hasLocationSelected.value = true;
      isLoading.value = false;
      
      addressController.text = query;
      
      Get.snackbar(
        'Location Found',
        'Location found for: $query',
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  void saveLocation() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!hasLocationSelected.value) {
      Get.snackbar(
        'Location Required',
        'Please select your stall location on the map',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Create stall location object
    final stallLocation = StallLocation(
      latitude: selectedLatitude.value,
      longitude: selectedLongitude.value,
      address: addressController.text.trim(),
      stallNumber: stallNumberController.text.trim(),
      area: areaController.text.trim(),
    );

    // Simulate API call to save location
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      
      Get.snackbar(
        'Success',
        'Stall location saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      
      // Return to previous screen
      Get.back(result: stallLocation);
    });
  }

  bool get canSave {
    return hasLocationSelected.value && 
           addressController.text.trim().isNotEmpty;
  }

  String get selectedLocationText {
    if (hasLocationSelected.value) {
      return 'Lat: ${selectedLatitude.value.toStringAsFixed(6)}, '
             'Lng: ${selectedLongitude.value.toStringAsFixed(6)}';
    }
    return 'Tap on map to select location';
  }

  // Predefined locations for quick selection
  List<Map<String, dynamic>> get quickLocations {
    return [
      {
        'name': 'Main Entrance',
        'lat': 21.1702,
        'lng': 72.8311,
        'area': 'Main Gate Area',
      },
      {
        'name': 'Food Court',
        'lat': 21.1705,
        'lng': 72.8315,
        'area': 'Food & Beverages Section',
      },
      {
        'name': 'Handicraft Section',
        'lat': 21.1700,
        'lng': 72.8308,
        'area': 'Arts & Crafts Zone',
      },
      {
        'name': 'Textile Zone',
        'lat': 21.1698,
        'lng': 72.8320,
        'area': 'Apparel & Textiles',
      },
    ];
  }

  void selectQuickLocation(Map<String, dynamic> location) {
    selectedLatitude.value = location['lat'];
    selectedLongitude.value = location['lng'];
    hasLocationSelected.value = true;
    areaController.text = location['area'];
    
    _updateAddressFromCoordinates(
      location['lat'], 
      location['lng'],
    );
  }
}

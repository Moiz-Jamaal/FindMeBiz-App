import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/location_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/seller.dart';

class LocationSelectorController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();
  
  // Map controller
  final MapController mapController = MapController();
  
  // Map related
  final RxDouble selectedLatitude = AppConstants.defaultLatitude.obs;
  final RxDouble selectedLongitude = AppConstants.defaultLongitude.obs;
  final RxDouble currentZoom = AppConstants.defaultZoom.obs;
  
  // Form controllers
  final addressController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final searchTextController = TextEditingController();
  
  // Geolocation
  final RxString currentGeoLocation = ''.obs; // Format: "latitude,longitude"
  final RxBool isGettingLocation = false.obs;
  final RxBool hasLocationSelected = false.obs;
  final RxBool showMapSelection = false.obs;
  
  // Search functionality
  final RxString locationSearchQuery = ''.obs;
  final RxList<Map<String, dynamic>> _searchResults = <Map<String, dynamic>>[].obs;
  late Worker _searchDebounce;
  
  // UI state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setDefaultLocation();
    
    // Setup search debounce for location search
    _searchDebounce = debounce<String>(
      locationSearchQuery,
      (query) {
        if (query.trim().isNotEmpty) {
          searchLocation(query);
        } else {
          _searchResults.clear();
        }
      },
      time: const Duration(milliseconds: 500),
    );
  }

  @override
  void onClose() {
    addressController.dispose();
    areaController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    searchTextController.dispose();
    _searchDebounce.dispose();
    super.onClose();
  }

  // Initialize with existing location data
  void initializeWithLocation({
    String? geoLocation,
    String? address,
    String? area,
    String? city,
    String? state,
    String? pincode,
  }) {
    if (geoLocation != null && geoLocation.isNotEmpty) {
      currentGeoLocation.value = geoLocation;
      final coords = _locationService.parseGeoLocation(geoLocation);
      if (coords != null) {
        selectedLatitude.value = coords['latitude']!;
        selectedLongitude.value = coords['longitude']!;
        hasLocationSelected.value = true;
        _moveMap();
      }
    }
    
    addressController.text = address ?? '';
    areaController.text = area ?? '';
    cityController.text = city ?? '';
    stateController.text = state ?? '';
    pincodeController.text = pincode ?? '';
  }

  void _setDefaultLocation() {
    selectedLatitude.value = AppConstants.defaultLatitude;
    selectedLongitude.value = AppConstants.defaultLongitude;
    hasLocationSelected.value = false;
  }

  void toggleMapSelection() {
    showMapSelection.value = !showMapSelection.value;
  }

  void onMapTap(double latitude, double longitude) {
    selectedLatitude.value = latitude;
    selectedLongitude.value = longitude;
    hasLocationSelected.value = true;
    
    // Update geolocation coordinates
    currentGeoLocation.value = '$latitude,$longitude';
    
    // Reverse geocoding
    _updateAddressFromCoordinates(latitude, longitude);
    
    // Move map to tapped location
    _moveMap();
    
    Get.snackbar(
      'Location Selected',
      'Location coordinates updated',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      final locationDetails = await _locationService.getAddressFromCoordinates(lat, lng);
      if (locationDetails != null) {
        addressController.text = locationDetails.formattedAddress;
        areaController.text = locationDetails.area;
        cityController.text = locationDetails.city;
        stateController.text = locationDetails.state;
        pincodeController.text = locationDetails.pincode;
      }
    } catch (e) {
      // Handle silently, user can manually fill address fields
    }
  }

  void zoomIn() {
    if (currentZoom.value < AppConstants.maxZoom) {
      currentZoom.value = currentZoom.value + 1;
      _moveMap();
    }
  }

  void zoomOut() {
    if (currentZoom.value > AppConstants.minZoom) {
      currentZoom.value = currentZoom.value - 1;
      _moveMap();
    }
  }

  void _moveMap({double? zoom}) {
    final target = ll.LatLng(selectedLatitude.value, selectedLongitude.value);
    final z = zoom ?? currentZoom.value;
    try {
      mapController.move(target, z);
    } catch (_) {
      // Handle map controller not ready
    }
  }

  // Get current GPS location
  Future<void> getCurrentLocation() async {
    try {
      isGettingLocation.value = true;
      
      final locationDetails = await _locationService.getCurrentLocationWithAddress();
      if (locationDetails != null) {
        selectedLatitude.value = locationDetails.latitude;
        selectedLongitude.value = locationDetails.longitude;
        hasLocationSelected.value = true;
        currentGeoLocation.value = locationDetails.geoLocationString;
        
        // Update address fields
        addressController.text = locationDetails.formattedAddress;
        areaController.text = locationDetails.area;
        cityController.text = locationDetails.city;
        stateController.text = locationDetails.state;
        pincodeController.text = locationDetails.pincode;
        
        _moveMap();
        
        Get.snackbar(
          'Location Updated',
          'Current location set successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isGettingLocation.value = false;
    }
  }

  // Get formatted location display
  String get currentLocationDisplay {
    if (currentGeoLocation.value.isEmpty) return 'No location set';
    
    final coords = _locationService.parseGeoLocation(currentGeoLocation.value);
    if (coords != null) {
      return '${coords['latitude']!.toStringAsFixed(6)}, ${coords['longitude']!.toStringAsFixed(6)}';
    }
    
    return 'No location set';
  }

  // Check if location is set
  bool get hasLocationSet => currentGeoLocation.value.isNotEmpty;

  // Search functionality
  List<Map<String, dynamic>> get searchResults => _searchResults;

  Future<void> searchLocation(String query, {bool showToast = false}) async {
    if (query.trim().isEmpty) return;
    
    isLoading.value = true;
    try {
      final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5&countrycodes=IN&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SouqApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _searchResults.assignAll(data.cast<Map<String, dynamic>>());
        
        if (showToast && _searchResults.isNotEmpty) {
          Get.snackbar(
            'Search Results',
            'Found ${_searchResults.length} locations',
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        if (showToast) {
          Get.snackbar(
            'Search Error',
            'Failed to search locations',
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            colorText: Colors.red,
          );
        }
      }
    } catch (e) {
      if (showToast) {
        Get.snackbar(
          'Search Error',
          'Error searching locations: ${e.toString()}',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchTextController.clear();
    locationSearchQuery.value = '';
    _searchResults.clear();
  }

  void selectSearchResult(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return;

    selectedLatitude.value = lat;
    selectedLongitude.value = lon;
    hasLocationSelected.value = true;
    currentGeoLocation.value = '$lat,$lon';
    
    // Update address from search result
    final address = item['address'] as Map<String, dynamic>?;
    if (address != null) {
      addressController.text = item['display_name'] ?? '';
      areaController.text = address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? '';
      cityController.text = address['city'] ?? address['town'] ?? address['village'] ?? '';
      stateController.text = address['state'] ?? '';
      pincodeController.text = address['postcode'] ?? '';
    }
    
    _searchResults.clear();
    searchTextController.clear();
    locationSearchQuery.value = '';
    _moveMap();
    
    Get.snackbar(
      'Location Selected',
      'Location set from search results',
      duration: const Duration(seconds: 2),
    );
  }

  // Get the current location data as a StallLocation object
  StallLocation? get currentStallLocation {
    if (!hasLocationSelected.value) return null;
    
    return StallLocation(
      latitude: selectedLatitude.value,
      longitude: selectedLongitude.value,
      address: addressController.text.trim(),
      area: areaController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      pincode: pincodeController.text.trim(),
      geolocation: currentGeoLocation.value,
    );
  }

  // Validation
  bool get isValid {
    return hasLocationSelected.value && 
           addressController.text.trim().isNotEmpty &&
           cityController.text.trim().isNotEmpty;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (!hasLocationSelected.value) {
      errors.add('Please select a location on the map');
    }
    
    if (addressController.text.trim().isEmpty) {
      errors.add('Address is required');
    }
    
    if (cityController.text.trim().isEmpty) {
      errors.add('City is required');
    }
    
    return errors;
  }
}

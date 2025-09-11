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
    print('DEBUG: onMapTap called with coordinates: $latitude, $longitude');
    
    selectedLatitude.value = latitude;
    selectedLongitude.value = longitude;
    hasLocationSelected.value = true;
    
    print('DEBUG: Updated reactive values:');
    print('  - selectedLatitude: ${selectedLatitude.value}');
    print('  - selectedLongitude: ${selectedLongitude.value}');
    print('  - hasLocationSelected: ${hasLocationSelected.value}');
    
    // Update geolocation coordinates
    currentGeoLocation.value = '$latitude,$longitude';
    print('DEBUG: Updated currentGeoLocation: ${currentGeoLocation.value}');
    
    print('DEBUG: About to call _updateAddressFromCoordinates');
    
    // Reverse geocoding to get address details
    _updateAddressFromCoordinates(latitude, longitude);
    
    // Move map to tapped location
    _moveMap();
    
    Get.snackbar(
      'Location Selected',
      'Fetching address details...',
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      colorText: Colors.blue,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    print('DEBUG: _updateAddressFromCoordinates called with lat: $lat, lng: $lng');
    
    try {
      isLoading.value = true;
      print('DEBUG: Set isLoading to true');
      
      Get.snackbar(
        'Getting Address',
        'Fetching location details...',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 1),
      );
      
      print('DEBUG: About to call LocationService.getAddressFromCoordinates');
      final locationDetails = await _locationService.getAddressFromCoordinates(lat, lng);
      print('DEBUG: LocationService returned: $locationDetails');
      
      if (locationDetails != null) {
        print('DEBUG: LocationDetails found:');
        print('  - formattedAddress: ${locationDetails.formattedAddress}');
        print('  - area: ${locationDetails.area}');
        print('  - city: ${locationDetails.city}');
        print('  - state: ${locationDetails.state}');
        print('  - pincode: ${locationDetails.pincode}');
        
        // Update all address fields
        print('DEBUG: Updating text controllers...');
        addressController.text = locationDetails.formattedAddress;
        areaController.text = locationDetails.area;
        cityController.text = locationDetails.city;
        stateController.text = locationDetails.state;
        pincodeController.text = locationDetails.pincode;
        
        // Force UI update by triggering reactive value
        update();
        
        print('DEBUG: Text controllers updated:');
        print('  - addressController.text: ${addressController.text}');
        print('  - areaController.text: ${areaController.text}');
        print('  - cityController.text: ${cityController.text}');
        print('  - stateController.text: ${stateController.text}');
        print('  - pincodeController.text: ${pincodeController.text}');
        
        Get.snackbar(
          'Address Updated',
          'Location details fetched successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 2),
        );
      } else {
        print('DEBUG: LocationDetails is null, using fallback');
        // Fallback: Set coordinates as address if reverse geocoding fails
        addressController.text = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
        // Clear other fields to let user fill manually
        areaController.text = '';
        cityController.text = '';
        stateController.text = '';
        pincodeController.text = '';
        
        print('DEBUG: Fallback values set');
        
        Get.snackbar(
          'Address Not Found',
          'Please fill address details manually',
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('DEBUG: Exception in _updateAddressFromCoordinates: $e');
      print('DEBUG: Exception stack trace: ${StackTrace.current}');
      
      // Fallback: Set coordinates as address
      addressController.text = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
      areaController.text = '';
      cityController.text = '';
      stateController.text = '';
      pincodeController.text = '';
      
      Get.snackbar(
        'Address Error',
        'Could not fetch address details. Please fill manually.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
      print('DEBUG: Set isLoading to false');
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
    
    // Update address from search result with comprehensive field mapping
    final address = item['address'] as Map<String, dynamic>?;
    
    if (address != null) {
      // Set main address
      addressController.text = item['display_name'] ?? '';
      
      // Extract area (try multiple possible field names)
      final area = address['suburb'] ?? 
                   address['neighbourhood'] ?? 
                   address['quarter'] ?? 
                   address['residential'] ??
                   address['commercial'] ??
                   address['hamlet'] ?? '';
      areaController.text = area;
      
      // Extract city (try multiple possible field names)
      final city = address['city'] ?? 
                   address['town'] ?? 
                   address['village'] ?? 
                   address['municipality'] ??
                   address['county'] ?? '';
      cityController.text = city;
      
      // Extract state (try multiple possible field names)
      final state = address['state'] ?? 
                    address['province'] ?? 
                    address['region'] ?? '';
      stateController.text = state;
      
      // Extract pincode (try multiple possible field names)
      final pincode = address['postcode'] ?? 
                      address['postal_code'] ?? '';
      pincodeController.text = pincode;
      
      print('DEBUG: Search result address fields updated:');
      print('  Address: ${addressController.text}');
      print('  Area: ${areaController.text}');
      print('  City: ${cityController.text}');
      print('  State: ${stateController.text}');
      print('  Pincode: ${pincodeController.text}');
    } else {
      // If no address details in search result, try reverse geocoding
      print('DEBUG: No address details in search result, trying reverse geocoding...');
      _updateAddressFromCoordinates(lat, lon);
    }
    
    _searchResults.clear();
    searchTextController.clear();
    locationSearchQuery.value = '';
    _moveMap();
    
    Get.snackbar(
      'Location Selected',
      'Location and address updated from search',
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  // Manual refresh of address details from current coordinates
  Future<void> refreshAddressFromCurrentLocation() async {
    if (!hasLocationSelected.value) {
      Get.snackbar(
        'No Location Selected',
        'Please select a location first',
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        colorText: Colors.orange,
      );
      return;
    }
    
    await _updateAddressFromCoordinates(selectedLatitude.value, selectedLongitude.value);
  }

  // DEBUG: Test method to check if location service is working
  Future<void> testLocationService() async {
    print('DEBUG: Testing LocationService with known coordinates...');
    
    // Test with coordinates for Surat, Gujarat
    const testLat = 21.1702;
    const testLng = 72.8311;
    
    print('DEBUG: Testing with Surat coordinates: $testLat, $testLng');
    
    try {
      final result = await _locationService.getAddressFromCoordinates(testLat, testLng);
      print('DEBUG: Test result: $result');
      
      if (result != null) {
        print('DEBUG: Test SUCCESS - LocationService is working');
        print('  - Address: ${result.formattedAddress}');
        print('  - Area: ${result.area}');
        print('  - City: ${result.city}');
        print('  - State: ${result.state}');
        print('  - Pincode: ${result.pincode}');
        
        // Test updating the text controllers directly
        print('DEBUG: Testing text controller updates...');
        addressController.text = "TEST: ${result.formattedAddress}";
        areaController.text = "TEST: ${result.area}";
        cityController.text = "TEST: ${result.city}";
        stateController.text = "TEST: ${result.state}";
        pincodeController.text = "TEST: ${result.pincode}";
        
        // Force update
        update();
        
        print('DEBUG: Text controllers set to test values');
        
        Get.snackbar(
          'Test Complete',
          'Check console logs and address fields',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
      } else {
        print('DEBUG: Test FAILED - LocationService returned null');
        
        // Test with dummy data
        addressController.text = "TEST: Dummy Address";
        areaController.text = "TEST: Dummy Area";
        cityController.text = "TEST: Dummy City";
        stateController.text = "TEST: Dummy State";
        pincodeController.text = "123456";
        
        update();
        
        Get.snackbar(
          'Test with Dummy Data',
          'Check if text fields update with dummy data',
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
        );
      }
    } catch (e) {
      print('DEBUG: Test EXCEPTION - LocationService threw error: $e');
      
      // Test with error data
      addressController.text = "ERROR: $e";
      areaController.text = "ERROR";
      cityController.text = "ERROR";
      stateController.text = "ERROR";
      pincodeController.text = "000000";
      
      update();
      
      Get.snackbar(
        'Test Error',
        'Error occurred: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
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

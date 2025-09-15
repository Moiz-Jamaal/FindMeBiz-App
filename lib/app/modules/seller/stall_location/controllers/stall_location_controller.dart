import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../services/analytics_service.dart';
import '../../../../services/location_service.dart';
import '../../../../data/models/seller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class StallLocationController extends GetxController {
  // Services
  final LocationService _locationService = Get.find<LocationService>();
  
  // Map controller (flutter_map)
  final MapController mapController = MapController();
  // Map related
  final RxDouble selectedLatitude = AppConstants.defaultLatitude.obs;
  final RxDouble selectedLongitude = AppConstants.defaultLongitude.obs;
  final RxDouble currentZoom = AppConstants.defaultZoom.obs;
  
  // Form controllers - matching onboarding and edit profile structure
  final addressController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final searchTextController = TextEditingController();
  
  // Geolocation - matching onboarding and edit profile naming
  final RxString currentGeoLocation = ''.obs; // Format: "latitude,longitude"
  final RxBool isGettingLocation = false.obs;
  
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
    // Debounce live search
    _searchDebounce = debounce<String>(
      locationSearchQuery,
      (q) {
        final query = q.trim();
        if (query.length >= 2) {
          searchLocation(query);
        } else {
          _searchResults.clear();
        }
      },
      time: const Duration(milliseconds: 400),
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
    
  // Reverse geocoding via Google Geocoding API
  _updateAddressFromCoordinates(latitude, longitude);

  // Move map to tapped location
  _moveMap();
    
    Get.snackbar(
      'Location Selected',
      'Tap "Save Location" to confirm your stall position',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
    // Analytics
    AnalyticsService.to.logEvent('seller_select_location', parameters: {
      'lat': latitude,
      'lng': longitude,
    });
  }

  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      final apiKey = AppConstants.googlePlacesApiKey;
      if (apiKey.isEmpty) return;

      final uri = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? const [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final display = (first['formatted_address'] ?? '').toString();
          if (display.isNotEmpty) {
            addressController.text = display;
          }

          final comps = (first['address_components'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          String _getByTypes(List<String> wanted) {
            for (final c in comps) {
              final types = (c['types'] as List?)?.map((e) => e.toString()).toList() ?? const [];
              if (types.any((t) => wanted.contains(t))) {
                return (c['long_name'] ?? c['short_name'] ?? '').toString();
              }
            }
            return '';
          }

          final area = _getByTypes(['sublocality_level_1', 'sublocality', 'neighborhood']);
          if (area.isNotEmpty && areaController.text.isEmpty) areaController.text = area;

          final city = _getByTypes(['locality', 'administrative_area_level_2']);
          if (city.isNotEmpty && cityController.text.isEmpty) cityController.text = city;

          final state = _getByTypes(['administrative_area_level_1']);
          if (state.isNotEmpty && stateController.text.isEmpty) stateController.text = state;

          final pincode = _getByTypes(['postal_code']);
          if (pincode.isNotEmpty && pincodeController.text.isEmpty) pincodeController.text = pincode;
        }

        // Update geolocation coordinates
        currentGeoLocation.value = '$lat,$lng';
      }
    } catch (_) {
      // Keep silent on reverse geocode errors
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

  void resetToDefault() {
    _setDefaultLocation();
    addressController.clear();
    areaController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
    currentGeoLocation.value = '';
    _moveMap();
  }

  Future<void> useCurrentLocation() async {
    try {
      isGettingLocation.value = true;
      
      Get.snackbar(
        'Getting Location',
        'Please wait while we get your current location...',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 3),
      );

      final locationDetails = await _locationService.getCurrentLocationWithAddress();
      
      if (locationDetails != null) {
        // Set coordinates
        selectedLatitude.value = locationDetails.latitude;
        selectedLongitude.value = locationDetails.longitude;
        hasLocationSelected.value = true;
        
        // Auto-fill address fields from location
        if (locationDetails.area.isNotEmpty) {
          areaController.text = locationDetails.area;
        }
        if (locationDetails.city.isNotEmpty) {
          cityController.text = locationDetails.city;
        }
        if (locationDetails.state.isNotEmpty) {
          stateController.text = locationDetails.state;
        }
        if (locationDetails.pincode.isNotEmpty) {
          pincodeController.text = locationDetails.pincode;
        }
        if (addressController.text.isEmpty && locationDetails.formattedAddress.isNotEmpty) {
          // Only set address if it's empty, don't overwrite existing address
          addressController.text = locationDetails.formattedAddress;
        }
        
        // Save geolocation coordinates
        currentGeoLocation.value = locationDetails.geoLocationString;
        
        _moveMap();

        Get.snackbar(
          'Location Updated',
          'Address fields have been filled with your current location.',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location. Please try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isGettingLocation.value = false;
    }
  }

  // Add convenience method that matches onboarding and edit profile naming
  Future<void> getCurrentLocation() async {
    await useCurrentLocation();
  }

  // Get formatted location display - matching onboarding and edit profile
  String get currentLocationDisplay {
    if (currentGeoLocation.value.isEmpty) return 'No location set';
    
    final coords = _locationService.parseGeoLocation(currentGeoLocation.value);
    if (coords != null) {
      return 'Lat: ${coords['latitude']!.toStringAsFixed(6)}, Lng: ${coords['longitude']!.toStringAsFixed(6)}';
    }
    
    return 'No location set';
  }

  // Check if location is set - matching onboarding and edit profile
  bool get hasLocationSet => currentGeoLocation.value.isNotEmpty;

  Future<void> searchLocation(String query, {bool showToast = false}) async {
    if (query.trim().isEmpty) return;
    locationSearchQuery.value = query;
    isLoading.value = true;
    try {
      final apiKey = AppConstants.googlePlacesApiKey;
      if (apiKey.isEmpty) {
        _searchResults.clear();
        if (showToast) {
          Get.snackbar('Google Places disabled', 'API key missing', snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }

      final biasLat = hasLocationSelected.value ? selectedLatitude.value : AppConstants.googlePlacesBiasLatitude;
      final biasLng = hasLocationSelected.value ? selectedLongitude.value : AppConstants.googlePlacesBiasLongitude;
      final body = <String, dynamic>{
        'textQuery': query,
        'pageSize': 8,
        'languageCode': 'en',
        if (AppConstants.googlePlacesCountryBias.isNotEmpty) 'regionCode': AppConstants.googlePlacesCountryBias.toUpperCase(),
        'locationBias': {
          'circle': {
            'center': { 'latitude': biasLat, 'longitude': biasLng },
            'radius': AppConstants.googlePlacesBiasRadiusMeters
          }
        }
      };
      final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.name,places.displayName,places.formattedAddress,places.location,places.addressComponents',
      };

      final res = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final List places = (data['places'] as List?) ?? const [];
        _searchResults.assignAll(places.map<Map<String, dynamic>>((p) {
          final name = p['name']?.toString() ?? '';
          final displayName = (p['displayName']?['text']?.toString() ?? '').trim();
          final formatted = p['formattedAddress']?.toString() ?? '';
          final loc = p['location'] as Map<String, dynamic>?;
          final lat = loc != null ? (loc['latitude'] as num?)?.toDouble() : null;
          final lng = loc != null ? (loc['longitude'] as num?)?.toDouble() : null;
          return {
            'place_id': name,
            'display_name': displayName.isNotEmpty ? displayName : formatted,
            'formatted_address': formatted,
            if (lat != null) 'lat': lat,
            if (lng != null) 'lng': lng,
            'address_components': p['addressComponents'],
          };
        }).toList());
        if (_searchResults.isEmpty && showToast) {
          Get.snackbar('No results', 'Could not find any location for "$query"', snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        if (showToast) {
          Get.snackbar('Google Places HTTP Error', 'Status code: ${res.statusCode}', snackPosition: SnackPosition.BOTTOM);
        }
        _searchResults.clear();
      }
    } catch (e) {
      if (showToast) {
        Get.snackbar('Google Places Network/Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      }
      _searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Hold search results
  final RxList<Map<String, dynamic>> _searchResults = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  late Worker _searchDebounce;

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
    addressController.text = (item['display_name'] ?? '').toString();
    _searchResults.clear();
    _moveMap();
  }

  // Helper to move the map camera to current selection
  void _moveMap({double? zoom}) {
    final target = ll.LatLng(selectedLatitude.value, selectedLongitude.value);
    final z = zoom ?? currentZoom.value;
    try {
      mapController.move(target, z);
    } catch (_) {
      // Map may not be ready yet; ignore
    }
  }

  void saveLocation() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!hasLocationSelected.value) {
      Get.snackbar(
        'Location Required',
        'Please select your location on the map or use current location',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Create location object that matches onboarding/edit profile structure (no stallNumber)
    final stallLocation = StallLocation(
      latitude: selectedLatitude.value,
      longitude: selectedLongitude.value,
      address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
      area: areaController.text.trim().isNotEmpty ? areaController.text.trim() : null,
      city: cityController.text.trim().isNotEmpty ? cityController.text.trim() : null,
      state: stateController.text.trim().isNotEmpty ? stateController.text.trim() : null,
      pincode: pincodeController.text.trim().isNotEmpty ? pincodeController.text.trim() : null,
      geolocation: currentGeoLocation.value.isNotEmpty ? currentGeoLocation.value : null,
      // Note: stallNumber is intentionally excluded from location selection process
    );

    // Simulate API call to save location

      isLoading.value = false;
      
      Get.snackbar(
        'Success',
        'Location saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      AnalyticsService.to.logEvent('seller_save_location', parameters: {
        'lat': selectedLatitude.value,
        'lng': selectedLongitude.value,
      });
      
      // Return location data to previous screen
      Get.back(result: stallLocation);
    
  }

  bool get canSave {
    return hasLocationSelected.value && 
           addressController.text.trim().isNotEmpty &&
           cityController.text.trim().isNotEmpty;
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
        'name': 'Market Main Entrance',
        'lat': 21.1702,
        'lng': 72.8311,
        'area': 'Main Gate Area',
      },
      {
        'name': 'Food Court Area',
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
    
    // Update geolocation coordinates
    currentGeoLocation.value = '${location['lat']},${location['lng']}';
    
    _updateAddressFromCoordinates(
      location['lat'], 
      location['lng'],
    );
    _moveMap();
  }
}

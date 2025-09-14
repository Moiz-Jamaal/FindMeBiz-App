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
try {
      isLoading.value = true;
Get.snackbar(
        'Getting Address',
        'Fetching location details...',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 1),
      );
final locationDetails = await _locationService.getAddressFromCoordinates(lat, lng);
if (locationDetails != null) {
// Update all address fields
addressController.text = locationDetails.formattedAddress;
        areaController.text = locationDetails.area;
        cityController.text = locationDetails.city;
        stateController.text = locationDetails.state;
        pincodeController.text = locationDetails.pincode;
        
        // Force UI update by triggering reactive value
        update();
Get.snackbar(
          'Address Updated',
          'Location details fetched successfully',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 2),
        );
      } else {
// Fallback: Set coordinates as address if reverse geocoding fails
        addressController.text = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
        // Clear other fields to let user fill manually
        areaController.text = '';
        cityController.text = '';
        stateController.text = '';
        pincodeController.text = '';
Get.snackbar(
          'Address Not Found',
          'Please fill address details manually',
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
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
      final apiKey = AppConstants.googlePlacesApiKey;
      if (apiKey.isEmpty) {
        if (showToast) {
          Get.snackbar(
            'Google Places disabled',
            'API key missing. Set --dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        _searchResults.clear();
        return;
      }

      // Bias around current selection or Surat
      final biasLat = hasLocationSelected.value
          ? selectedLatitude.value
          : AppConstants.googlePlacesBiasLatitude;
      final biasLng = hasLocationSelected.value
          ? selectedLongitude.value
          : AppConstants.googlePlacesBiasLongitude;

      final body = <String, dynamic>{
        'textQuery': query,
        'pageSize': 8,
        'languageCode': 'en',
        if (AppConstants.googlePlacesCountryBias.isNotEmpty)
          'regionCode': AppConstants.googlePlacesCountryBias.toUpperCase(),
        'locationBias': {
          'circle': {
            'center': {
              'latitude': biasLat,
              'longitude': biasLng,
            },
            'radius': AppConstants.googlePlacesBiasRadiusMeters,
          }
        }
      };

      final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');
      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.name,places.displayName,places.formattedAddress,places.location,places.addressComponents',
      };
      debugPrint('[LocationSelector][Places v1 TextSearch] body=${jsonEncode(body)}');

      final res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));

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
            'Google Places HTTP Error',
            'Status code: ${res.statusCode}',
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            colorText: Colors.red,
          );
        }
        debugPrint('[LocationSelector][Places v1] HTTP ${res.statusCode} body=${res.body}');
        _searchResults.clear();
      }
    } catch (e) {
      if (showToast) {
        Get.snackbar(
          'Search Error',
          'Google Places: ${e.toString()}',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
      debugPrint('[LocationSelector][Places v1] EXCEPTION $e');
      _searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void clearSearch() {
    searchTextController.clear();
    locationSearchQuery.value = '';
    _searchResults.clear();
  }

  Future<void> selectSearchResult(Map<String, dynamic> item) async {
    // Prefer ready coordinates from v1 search
    final lat = (item['lat'] as num?)?.toDouble();
    final lng = (item['lng'] as num?)?.toDouble();

    if (lat != null && lng != null) {
      selectedLatitude.value = lat;
      selectedLongitude.value = lng;
      hasLocationSelected.value = true;
      currentGeoLocation.value = '$lat,$lng';

      final formatted = item['formatted_address']?.toString() ?? item['display_name']?.toString() ?? '';
      if (formatted.isNotEmpty) {
        addressController.text = formatted;
      }

      // Parse v1 addressComponents
      final List comps = (item['address_components'] as List?) ?? const [];
      String city = '';
      String state = '';
      String postal = '';
      String area = '';
      for (final c in comps) {
        final Map comp = c as Map;
        final List types = (comp['types'] as List?) ?? const [];
        final longText = comp['longText']?.toString() ?? comp['shortText']?.toString() ?? '';
        if (types.contains('sublocality') || types.contains('neighborhood')) area = longText;
        if (types.contains('locality') || types.contains('postal_town')) city = longText;
        if (types.contains('administrative_area_level_1')) state = longText;
        if (types.contains('postal_code')) postal = longText;
      }
      if (area.isNotEmpty) areaController.text = area;
      if (city.isNotEmpty) cityController.text = city;
      if (state.isNotEmpty) stateController.text = state;
      if (postal.isNotEmpty) pincodeController.text = postal;

      _searchResults.clear();
      searchTextController.clear();
      locationSearchQuery.value = '';
      _moveMap();
      
      Get.snackbar(
        'Location Selected',
        'Address updated from Google Places',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Fallback: fetch details to get coordinates
    final placeId = item['place_id']?.toString();
    if (placeId == null || placeId.isEmpty) {
      Get.snackbar('Selection Error', 'Missing place id for details', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      final detailsUri = Uri.parse('https://places.googleapis.com/v1/$placeId');
      final headers = {
        'X-Goog-Api-Key': AppConstants.googlePlacesApiKey,
        'X-Goog-FieldMask': 'displayName,formattedAddress,location,addressComponents',
      };
      debugPrint('[LocationSelector][Place Details v1] ${detailsUri.toString()}');
      final res = await http.get(detailsUri, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final p = json.decode(res.body) as Map<String, dynamic>;
        final loc = p['location'] as Map<String, dynamic>?;
        final dLat = (loc?['latitude'] as num?)?.toDouble();
        final dLng = (loc?['longitude'] as num?)?.toDouble();
        if (dLat != null && dLng != null) {
          selectedLatitude.value = dLat;
          selectedLongitude.value = dLng;
          hasLocationSelected.value = true;
          currentGeoLocation.value = '$dLat,$dLng';
        }
        final formatted = p['formattedAddress']?.toString() ?? '';
        if (formatted.isNotEmpty) addressController.text = formatted;
        final comps = (p['addressComponents'] as List?) ?? const [];
        String city = '', state = '', postal = '', area = '';
        for (final c in comps) {
          final Map comp = c as Map;
          final List types = (comp['types'] as List?) ?? const [];
          final longText = comp['longText']?.toString() ?? comp['shortText']?.toString() ?? '';
          if (types.contains('sublocality') || types.contains('neighborhood')) area = longText;
          if (types.contains('locality') || types.contains('postal_town')) city = longText;
          if (types.contains('administrative_area_level_1')) state = longText;
          if (types.contains('postal_code')) postal = longText;
        }
        if (area.isNotEmpty) areaController.text = area;
        if (city.isNotEmpty) cityController.text = city;
        if (state.isNotEmpty) stateController.text = state;
        if (postal.isNotEmpty) pincodeController.text = postal;
        _searchResults.clear();
        searchTextController.clear();
        locationSearchQuery.value = '';
        _moveMap();
        Get.snackbar('Location Selected', 'Address updated from Google Places', backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green, duration: const Duration(seconds: 2));
      } else {
        Get.snackbar('Google Place Details HTTP Error', 'Status code: ${res.statusCode}', snackPosition: SnackPosition.BOTTOM);
        debugPrint('[LocationSelector][Place Details v1] HTTP ${res.statusCode} body=${res.body}');
      }
    } catch (e) {
      Get.snackbar('Google Place Details Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      debugPrint('[LocationSelector][Place Details v1] EXCEPTION $e');
    }
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
// Test with coordinates for Surat, Gujarat
    const testLat = 21.1702;
    const testLng = 72.8311;
try {
      final result = await _locationService.getAddressFromCoordinates(testLat, testLng);
if (result != null) {
// Test updating the text controllers directly
addressController.text = "TEST: ${result.formattedAddress}";
        areaController.text = "TEST: ${result.area}";
        cityController.text = "TEST: ${result.city}";
        stateController.text = "TEST: ${result.state}";
        pincodeController.text = "TEST: ${result.pincode}";
        
        // Force update
        update();
Get.snackbar(
          'Test Complete',
          'Check console logs and address fields',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
      } else {
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

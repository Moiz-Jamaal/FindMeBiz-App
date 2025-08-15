import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../data/models/seller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class StallLocationController extends GetxController {
  // Map controller (flutter_map)
  final MapController mapController = MapController();
  // Map related
  final RxDouble selectedLatitude = AppConstants.defaultLatitude.obs;
  final RxDouble selectedLongitude = AppConstants.defaultLongitude.obs;
  final RxDouble currentZoom = AppConstants.defaultZoom.obs;
  
  // Form controllers
  final stallNumberController = TextEditingController();
  final areaController = TextEditingController();
  final addressController = TextEditingController();
  final searchTextController = TextEditingController();
  
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
    stallNumberController.dispose();
    areaController.dispose();
    addressController.dispose();
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
    
  // Reverse geocoding via OSM Nominatim
  _updateAddressFromCoordinates(latitude, longitude);

  // Move map to tapped location
  _moveMap();
    
    Get.snackbar(
      'Location Selected',
      'Tap "Save Location" to confirm your stall position',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng',
      );
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'FindMeBiz/1.0 (support@findmebiz.com)'
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final display = (data['display_name'] ?? '').toString();
        if (display.isNotEmpty) {
          addressController.text = display;
        }
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
    stallNumberController.clear();
    areaController.clear();
    addressController.clear();
  _moveMap();
  }

  Future<void> useCurrentLocation() async {
    isLoading.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLoading.value = false;
        Get.snackbar(
          'Location disabled',
          'Please enable Location (GPS) to use current location.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        isLoading.value = false;
        Get.snackbar(
          'Permission required',
          'Location permission is needed to use your current location.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      selectedLatitude.value = pos.latitude;
      selectedLongitude.value = pos.longitude;
      hasLocationSelected.value = true;

      await _updateAddressFromCoordinates(pos.latitude, pos.longitude);

  _moveMap();

      Get.snackbar(
        'Location Found',
        'Using your current location',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to get current location',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchLocation(String query, {bool showToast = false}) async {
    if (query.trim().isEmpty) return;
    locationSearchQuery.value = query;
    isLoading.value = true;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeQueryComponent(query)}&limit=5',
      );
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'FindMeBiz/1.0 (support@findmebiz.com)'
        },
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _searchResults.assignAll(data.map((e) => e as Map<String, dynamic>));
        if (_searchResults.isEmpty && showToast) {
          Get.snackbar(
            'No results',
            'Could not find any location for "$query"',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Unable to search address',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to search address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
  _moveMap();
  }
}

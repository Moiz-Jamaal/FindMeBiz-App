import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService extends GetxService {
  final RxBool isLocationEnabled = false.obs;
  final RxBool isLocationPermissionGranted = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString currentAddress = ''.obs;
  final RxBool isLoadingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkLocationService();
  }

  /// Check if location service is enabled
  Future<void> _checkLocationService() async {
    isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied', 
            'Location permissions are denied',
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
          );
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied Forever', 
          'Location permissions are permanently denied. Please enable them in settings.',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return false;
      }

      isLocationPermissionGranted.value = true;
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to request location permission');
      return false;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      // Check if location service is enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        Get.snackbar(
          'Location Disabled',
          'Please enable location services',
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
        );
        return null;
      }

      // Request permission if not granted
      if (!isLocationPermissionGranted.value) {
        final hasPermission = await requestLocationPermission();
        if (!hasPermission) return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      currentPosition.value = position;
      return position;

    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: ${e.toString()}');
      return null;
    } finally {
      isLoadingLocation.value = false;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // For now, return formatted coordinates
      // In a real app, you would use a geocoding service like Google Maps API
      final address = 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      currentAddress.value = address;
      return address;
    } catch (e) {
      Get.snackbar('Error', 'Failed to get address');
      return null;
    }
  }

  /// Get current location and address
  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    final address = await getAddressFromCoordinates(
      position.latitude, 
      position.longitude,
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
      'timestamp': position.timestamp,
    };
  }

  /// Format location for database storage
  String formatLocationForStorage(double latitude, double longitude) {
    return '$latitude,$longitude';
  }

  /// Parse location from database storage
  Map<String, double>? parseLocationFromStorage(String? locationString) {
    if (locationString == null || locationString.isEmpty) return null;
    
    try {
      final parts = locationString.split(',');
      if (parts.length == 2) {
        return {
          'latitude': double.parse(parts[0]),
          'longitude': double.parse(parts[1]),
        };
      }
    } catch (e) {
      print('Error parsing location: $e');
    }
    return null;
  }

  /// Show location permission dialog
  Future<bool> showLocationPermissionDialog() async {
    bool granted = false;
    
    await Get.dialog(
      AlertDialog(
        title: const Text('Location Permission'),
        content: const Text(
          'This app needs location access to automatically fill your address and help customers find you nearby.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              granted = await requestLocationPermission();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
    
    return granted;
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      Get.snackbar('Error', 'Could not open location settings');
    }
  }

  /// Check if location is available and accurate
  bool get hasAccurateLocation {
    return currentPosition.value != null && 
           currentPosition.value!.accuracy <= 100; // Within 100 meters
  }

  /// Get distance between two coordinates
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}

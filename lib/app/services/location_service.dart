import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:souq/app/core/constants/app_constants.dart';

class LocationService extends GetxService {
  
  /// Check if location services are enabled and request permissions
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // On web, don't explicitly request permissions; let the browser prompt during the API call
    if (kIsWeb) {
      return true;
    }

    // Test if location services are enabled (mobile)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Services Disabled',
        'Please enable location services in your device settings.',
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        colorText: Colors.orange,
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Location Permission Needed',
          kIsWeb
              ? 'Please allow location in your browser when prompted (or via the site permissions icon near the address bar).'
              : 'Location permissions are required to get your current location.',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
        return false;
      }
    }

    // On web "deniedForever" means the browser has blocked the site. Provide actionable guidance instead of hard error.
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        kIsWeb ? 'Location Blocked in Browser' : 'Permission Permanently Denied',
        kIsWeb
            ? 'Location access is blocked for this site. Click the lock icon in the address bar, allow Location, then refresh the page.'
            : 'Location permissions are permanently denied. Please enable them in app settings.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // On web, call directly to trigger browser prompt automatically
      if (kIsWeb) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        return position;
      }

      if (!await checkAndRequestPermissions()) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      Get.snackbar(
        'Location Error',
        kIsWeb
            ? 'Failed to get location. Allow Location in your browser (lock icon near address bar) and try again.'
            : 'Failed to get current location: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return null;
    }
  }

  /// Reverse geocoding to get address from coordinates
  Future<LocationDetails?> getAddressFromCoordinates(double latitude, double longitude) async {
try {
      // Use Google Geocoding
      final result = await _tryGoogleGeocoding(latitude, longitude);
      if (result != null) return result;

      // Last resort: return basic location details
      return LocationDetails(
        latitude: latitude,
        longitude: longitude,
        formattedAddress: 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
        area: '',
        city: '',
        state: '',
        pincode: '',
        country: '',
      );
    } catch (e) {
      return LocationDetails(
        latitude: latitude,
        longitude: longitude,
        formattedAddress: 'Error: ${e.toString()}',
        area: '',
        city: '',
        state: '',
        pincode: '',
        country: '',
      );
    }
  }

  /// Primary geocoding service (Google Geocoding)
  Future<LocationDetails?> _tryGoogleGeocoding(double latitude, double longitude) async {
    try {
      final apiKey = AppConstants.googlePlacesApiKey;
      if (apiKey.isEmpty) return null;
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? const [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
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

          return LocationDetails(
            latitude: latitude,
            longitude: longitude,
            formattedAddress: (first['formatted_address'] ?? '').toString(),
            area: _getByTypes(['sublocality_level_1', 'sublocality', 'neighborhood']),
            city: _getByTypes(['locality', 'administrative_area_level_2']),
            state: _getByTypes(['administrative_area_level_1']),
            pincode: _getByTypes(['postal_code']),
            country: _getByTypes(['country']),
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  /// Get current location with address details
  Future<LocationDetails?> getCurrentLocationWithAddress() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      Get.snackbar(
        'Getting Location Details',
        'Fetching address information...',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 2),
      );

      final locationDetails = await getAddressFromCoordinates(position.latitude, position.longitude);

      return locationDetails;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get location details: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return null;
    }
  }

  /// Format coordinates for database storage
  String formatGeoLocation(double latitude, double longitude) {
    return '$latitude,$longitude';
  }

  /// Parse coordinates from database string
  Map<String, double>? parseGeoLocation(String? geoLocationString) {
    if (geoLocationString == null || geoLocationString.isEmpty) return null;
    
  
      final parts = geoLocationString.split(',');
      if (parts.length == 2) {
        return {
          'latitude': double.parse(parts[0]),
          'longitude': double.parse(parts[1]),
        };
      }
  
    
    return null;
  }
}

/// Model class for location details
class LocationDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String country;

  LocationDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
  });

  /// Get formatted geolocation string for database
  String get geoLocationString => '$latitude,$longitude';

  @override
  String toString() {
    return 'LocationDetails(lat: $latitude, lng: $longitude, address: $formattedAddress)';
  }
}

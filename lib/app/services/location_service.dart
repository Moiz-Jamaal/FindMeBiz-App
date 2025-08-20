import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService extends GetxService {
  
  /// Check if location services are enabled and request permissions
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Services Disabled',
        'Please enable location services in your device settings.',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permission Denied',
          'Location permissions are required to get your current location.',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission Permanently Denied',
        'Location permissions are permanently denied. Please enable them in app settings.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      if (!await checkAndRequestPermissions()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return null;
    }
  }

  /// Reverse geocoding to get address from coordinates
  Future<LocationDetails?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Using a free geocoding service (OpenStreetMap Nominatim)
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SouqApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data != null && data['address'] != null) {
          final address = data['address'];
          
          return LocationDetails(
            latitude: latitude,
            longitude: longitude,
            formattedAddress: data['display_name'] ?? '',
            area: address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? '',
            city: address['city'] ?? address['town'] ?? address['village'] ?? '',
            state: address['state'] ?? '',
            pincode: address['postcode'] ?? '',
            country: address['country'] ?? '',
          );
        }
      }
      
      // Fallback: return basic location details
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
      
      // Return basic location details as fallback
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
        backgroundColor: Colors.blue.withOpacity(0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 2),
      );

      final locationDetails = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return locationDetails;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get location details: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
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
    
    try {
      final parts = geoLocationString.split(',');
      if (parts.length == 2) {
        return {
          'latitude': double.parse(parts[0]),
          'longitude': double.parse(parts[1]),
        };
      }
    } catch (e) {
      
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

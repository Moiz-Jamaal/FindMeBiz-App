import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:souq/app/core/constants/app_constants.dart';
import 'package:souq/app/services/location_service.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../core/theme/app_theme.dart';
// Removed unused import

class SellerProfileEditController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  final ImageUploadService _imageUploadService = Get.find<ImageUploadService>();
  final LocationService _locationService = Get.find<LocationService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  
  // Disposal flag to prevent using disposed controllers
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;
  
  // Current seller data
  final Rx<SellerDetailsExtended?> currentSeller = Rx<SellerDetailsExtended?>(null);
  
  // Form controllers
  final businessNameController = TextEditingController();
  final profileNameController = TextEditingController();
  final bioController = TextEditingController();
  final contactController = TextEditingController();
  final mobileController = TextEditingController();
  final whatsappController = TextEditingController();
  final addressController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final establishedYearController = TextEditingController();
  
  // Social media controllers
  final RxList<SellerUrl> socialUrls = <SellerUrl>[].obs;
  final RxList<SocialMediaPlatform> socialMediaPlatforms = <SocialMediaPlatform>[].obs;
  final Map<String, TextEditingController> socialControllers = {};
  final RxBool isLoadingSocialMedia = false.obs;
  
  // Profile images - only business logo
  final RxString businessLogoUrl = ''.obs;
  final RxString tempLogoPath = ''.obs; // For immediate local preview
  
  // Geolocation
  final RxString currentGeoLocation = ''.obs; // Format: "latitude,longitude"
  final RxBool isGettingLocation = false.obs;
  
  // Map functionality (enhanced location selection)
  final MapController mapController = MapController();
  final RxDouble selectedLatitude = AppConstants.defaultLatitude.obs;
  final RxDouble selectedLongitude = AppConstants.defaultLongitude.obs;
  final RxDouble currentZoom = AppConstants.defaultZoom.obs;
  final RxBool hasLocationSelected = false.obs;
  final RxBool showMapSelection = false.obs;
  final searchTextController = TextEditingController();
  final RxString locationSearchQuery = ''.obs;
  final RxList<Map<String, dynamic>> _searchResults = <Map<String, dynamic>>[].obs;
  // Session token for Places Autocomplete/Details pairing
  String? _placesSessionToken;
  late Worker _searchDebounce;
  
  // Validation state - reactive
  final RxBool _validationUpdateTrigger = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingLogo = false.obs;
  final RxBool hasChanges = false.obs;
  
  // Profile name availability state
  final RxString profileName = ''.obs;
  final RxBool isCheckingProfileName = false.obs;
  final RxBool isProfileNameAvailable = false.obs;
  final RxString profileNameError = ''.obs;
  Worker? _profileDebounce;
  
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    
    // Reset upload states
    isUploadingLogo.value = false;
    tempLogoPath.value = '';
    
    _loadCurrentProfile();
    // Social media platforms will be loaded after URLs are loaded
    _setupListeners();
    
    // Initialize map location selection
    _setDefaultLocation();
    
    // Setup search debounce for location search
    _searchDebounce = debounce<String>(
      locationSearchQuery,
      (q) {
        if (_isDisposed) return; // Safety check
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
    _isDisposed = true;
    _searchDebounce.dispose();
  try { _profileDebounce?.dispose(); } catch (_) {}
    searchTextController.dispose();
    _disposeControllers();
    super.onClose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      isLoading.value = true;
      
      final currentUser = _authService.currentUser;
      if (currentUser?.userid == null) {
        Get.snackbar('Error', 'No user found. Please login again.');
        return;
      }

      // Load seller profile
      final response = await _sellerService.getSellerByUserId(currentUser!.userid!);
      
      if (response.success && response.data != null) {
        currentSeller.value = response.data;
        _populateFields(response.data!);
        // Initialize reactive profileName and run initial availability check excluding current seller
        final initialName = profileNameController.text.trim();
        if (initialName.isNotEmpty) {
          profileName.value = initialName;
          await _checkProfileNameAvailability();
        }
        await _loadSocialUrls(response.data!.sellerid!);
        
        // Load social media platforms after loading URLs
        await _loadSocialMediaPlatforms();
      } else {
        Get.snackbar('Info', 'No seller profile found. Please complete onboarding first.');
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile data');
      
    } finally {
      isLoading.value = false;
    }
  }

  void _populateFields(SellerDetailsExtended seller) {
    businessNameController.text = seller.businessname ?? '';
    profileNameController.text = seller.profilename ?? '';
    bioController.text = seller.bio ?? '';
    contactController.text = seller.contactno ?? '';
    mobileController.text = seller.mobileno ?? '';
    whatsappController.text = seller.whatsappno ?? '';
    addressController.text = seller.address ?? '';
    areaController.text = seller.area ?? '';
    cityController.text = seller.city ?? '';
    stateController.text = seller.state ?? '';
    pincodeController.text = seller.pincode ?? '';
    establishedYearController.text = seller.establishedyear?.toString() ?? '';
    
    // Handle business logo - get presigned URL if it's a file key
    final logoValue = seller.logo ?? '';
    if (logoValue.isNotEmpty) {
      _loadExistingBusinessLogo(logoValue);
    } else {
      businessLogoUrl.value = '';
    }
    
    currentGeoLocation.value = seller.geolocation ?? '';
    
    // Initialize map coordinates if geolocation exists
    if (currentGeoLocation.value.isNotEmpty) {
      final coords = _locationService.parseGeoLocation(currentGeoLocation.value);
      if (coords != null) {
        selectedLatitude.value = coords['latitude']!;
        selectedLongitude.value = coords['longitude']!;
        hasLocationSelected.value = true;
      }
    }

    // If profilename exists, reflect it in observables so Obx UI shows correct state
    final pn = profileNameController.text.trim();
    if (pn.isNotEmpty) {
      profileName.value = pn;
      // Treat own name as available until remote check completes
      isProfileNameAvailable.value = true;
      profileNameError.value = '';
    }
  }

  Future<void> _loadSocialUrls(int sellerId) async {
  
      final response = await _sellerService.getSellerUrls(sellerId);
      if (response.success && response.data != null) {
        socialUrls.value = response.data!;
        
        
        // Re-initialize controllers if platforms are already loaded
        if (socialMediaPlatforms.isNotEmpty) {
          
          _initializeSocialControllers();
        }
      }
  
  }

  Future<void> _loadSocialMediaPlatforms() async {
    try {
      isLoadingSocialMedia.value = true;
      
      // Ensure defaults exist first
      await _categoryService.ensureSocialMediaDefaults();
      
      // Load social media platforms
      final response = await _categoryService.getSocialMediaList();
      
      if (response.success && response.data != null) {
        // Remove duplicates by platform name and ensure unique IDs
        final uniquePlatforms = <String, SocialMediaPlatform>{};
        var currentId = 1;
        
        for (var platform in response.data!) {
          final name = platform.sname.toLowerCase();
          if (!uniquePlatforms.containsKey(name)) {
            // Create platform with unique ID if needed
            uniquePlatforms[name] = SocialMediaPlatform(
              smid: platform.smid == 1 ? currentId++ : platform.smid,
              sname: platform.sname,
            );
          }
        }
        
        socialMediaPlatforms.value = uniquePlatforms.values.toList();
        
        
        // Initialize controllers for all platforms if URLs are already loaded
        if (socialUrls.isNotEmpty || socialMediaPlatforms.isNotEmpty) {
          
          _initializeSocialControllers();
        }
      } else {
        Get.snackbar('Error', 'Failed to load social media platforms');
      }
      
    } finally {
      isLoadingSocialMedia.value = false;
    }
  }

  void _initializeSocialControllers() {
    
    
    
    
    // Clear existing controllers
    for (var controller in socialControllers.values) {
      controller.dispose();
    }
    socialControllers.clear();
    
    // Create controllers for each platform
    for (var platform in socialMediaPlatforms) {
      if (platform.smid != null) {
        final key = platform.smid.toString();
        
        // Find existing URL for this platform
        final existingUrl = socialUrls.firstWhereOrNull(
          (url) => url.smid == platform.smid,
        );
        
        
        
        final controller = TextEditingController(text: existingUrl?.urllink ?? '');
        controller.addListener(_onFieldChanged);
        socialControllers[key] = controller;
      }
    }
    
    
  }

  void _setupListeners() {
    // Add listeners to detect changes
    businessNameController.addListener(_onFieldChanged);
    profileNameController.addListener(_onFieldChanged);
    // Enforce lowercase + no spaces and debounce availability check
    profileNameController.addListener(() {
      if (_isDisposed) return;
      final raw = profileNameController.text;
      final transformed = raw.replaceAll(' ', '').toLowerCase();
      if (raw != transformed) {
        final selectionIndex = profileNameController.selection.baseOffset;
        profileNameController.value = TextEditingValue(
          text: transformed,
          selection: TextSelection.collapsed(
            offset: selectionIndex.clamp(0, transformed.length),
          ),
        );
      }
      profileName.value = profileNameController.text;
      _profileDebounce?.dispose();
      _profileDebounce = debounce(profileName, (_) => _checkProfileNameAvailability(), time: const Duration(milliseconds: 400));
    });
    bioController.addListener(_onFieldChanged);
    contactController.addListener(_onFieldChanged);
    mobileController.addListener(_onFieldChanged);
    whatsappController.addListener(_onFieldChanged);
    addressController.addListener(_onFieldChanged);
    areaController.addListener(_onFieldChanged);
    cityController.addListener(_onFieldChanged);
    stateController.addListener(_onFieldChanged);
    pincodeController.addListener(_onFieldChanged);
    establishedYearController.addListener(_onFieldChanged);
    // Connect the search text field to the debounced query stream
    searchTextController.addListener(() {
      if (_isDisposed) return;
      locationSearchQuery.value = searchTextController.text;
    });
  }

  // Profile name availability check
  Future<void> _checkProfileNameAvailability() async {
    if (_isDisposed) return;
    final name = profileName.value.trim();
    profileNameError.value = '';
    isProfileNameAvailable.value = false;
    if (name.isEmpty) return;
    if (name.length < 2) {
      profileNameError.value = 'Must be at least 2 characters';
      return;
    }
    // If name equals current seller's profilename, it's implicitly available
    final ownName = currentSeller.value?.profilename?.trim().toLowerCase();
    if (ownName != null && ownName.isNotEmpty && ownName == name.toLowerCase()) {
      isProfileNameAvailable.value = true;
      return;
    }
    isCheckingProfileName.value = true;
    try {
      final current = currentSeller.value;
      final res = await _authService.isProfileNameAvailable(
        name,
        sellerId: current?.sellerid,
      );
      if (res.success) {
        isProfileNameAvailable.value = res.data ?? false;
        if (!isProfileNameAvailable.value) {
          profileNameError.value = 'This profile name is already taken';
        }
      } else {
        profileNameError.value = res.message ?? 'Could not verify availability';
      }
    } catch (e) {
      profileNameError.value = 'Could not verify availability';
    } finally {
      isCheckingProfileName.value = false;
    }
  }

  String? profileNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Profile name is required';
    final v = value.trim();
    if (v.length < 2) return 'Profile name must be at least 2 characters';
    if (v.contains(' ')) return 'No spaces allowed';
    if (v.toLowerCase() != v) return 'Must be lowercase';
    if (!isProfileNameAvailable.value) {
      if (profileNameError.value.isNotEmpty) return profileNameError.value;
    }
    return null;
  }

  void _disposeControllers() {
    // Remove listeners before disposing to prevent errors
    businessNameController.removeListener(_onFieldChanged);
    profileNameController.removeListener(_onFieldChanged);
    bioController.removeListener(_onFieldChanged);
    contactController.removeListener(_onFieldChanged);
    mobileController.removeListener(_onFieldChanged);
    whatsappController.removeListener(_onFieldChanged);
    addressController.removeListener(_onFieldChanged);
    areaController.removeListener(_onFieldChanged);
    cityController.removeListener(_onFieldChanged);
    stateController.removeListener(_onFieldChanged);
    pincodeController.removeListener(_onFieldChanged);
    establishedYearController.removeListener(_onFieldChanged);
    
    // Remove listeners from social media controllers
    for (var controller in socialControllers.values) {
      controller.removeListener(_onFieldChanged);
    }
    
    // Now dispose all controllers
    businessNameController.dispose();
    profileNameController.dispose();
    bioController.dispose();
    contactController.dispose();
    mobileController.dispose();
    whatsappController.dispose();
    addressController.dispose();
    areaController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    establishedYearController.dispose();
    
    // Dispose social media controllers
    for (var controller in socialControllers.values) {
      controller.dispose();
    }
    socialControllers.clear();
  }

  // Image handling methods - only business logo
  Future<void> _loadExistingBusinessLogo(String logoValue) async {
    try {
      
      
      // Check if it's already a full URL (presigned URL or direct URL)
      if (logoValue.startsWith('http://') || logoValue.startsWith('https://')) {
        // It's already a full URL, use it directly
        businessLogoUrl.value = logoValue;
        
        return;
      }
      
      // It might be a file key, try to get presigned URL
      final presignedUrl = await _imageUploadService.getPresignedUrl(logoValue);
      if (presignedUrl != null) {
        businessLogoUrl.value = presignedUrl;
        
      } else {
        // Fallback: construct direct S3 URL (might give 403 but better than nothing)
        if (logoValue.contains('/')) {
          // Assume it's a file key like "logos/filename.jpg"
          businessLogoUrl.value = 'https://findmebiz.s3.amazonaws.com/$logoValue';
          
        } else {
          // It's something else, use as is
          businessLogoUrl.value = logoValue;
          
        }
      }
      
    } catch (e) {
      
      // Still set the original value as fallback
      businessLogoUrl.value = logoValue;
    }
  }

  Future<void> updateBusinessLogo() async {
    
    
    try {
      isUploadingLogo.value = true;
      
      // Get image selection directly using the service's built-in dialog
      
      final XFile? selectedImage = await _showImagePickerBottomSheet();
      
      
      
      if (selectedImage == null) {
        
        isUploadingLogo.value = false;
        return;
      }
      
      // IMMEDIATE UI UPDATE - Set temporary path for immediate preview
      
      tempLogoPath.value = selectedImage.path;
      hasChanges.value = true;
      
      // Force UI update
      update();
      
      
      
      
      // Show immediate feedback that image is selected
      Get.snackbar(
        'Image Selected', 
        'Uploading business logo...',
        backgroundColor: AppTheme.sellerPrimary.withValues(alpha: 0.1),
        colorText: AppTheme.sellerPrimary,
        duration: const Duration(seconds: 2),
      );
      
      // Validate image before upload
      
      if (!await _imageUploadService.validateImageForUpload(selectedImage)) {
        
        tempLogoPath.value = ''; // Clear temp path on validation failure
        isUploadingLogo.value = false;
        return;
      }
      
      
      final String? uploadedUrl = await _imageUploadService.uploadBusinessLogo(selectedImage);
      
      
      if (uploadedUrl != null) {
        businessLogoUrl.value = uploadedUrl;
        tempLogoPath.value = ''; // Clear temp path once uploaded
        hasChanges.value = true;
        
        Get.snackbar(
          'Success', 
          'Business logo updated successfully!',
          backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
          colorText: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        );
      } else {
        tempLogoPath.value = ''; // Clear temp path on upload failure
        
        Get.snackbar(
          'Upload Failed', 
          'Failed to upload business logo. Please try again.',
          backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
          colorText: AppTheme.errorColor,
        );
      }
    } catch (e) {
      tempLogoPath.value = ''; // Clear temp path on error
      
      Get.snackbar(
        'Error', 
        'Failed to upload business logo: ${e.toString()}',
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
        colorText: AppTheme.errorColor,
      );
    } finally {
      isUploadingLogo.value = false;
      
    }
  }
  
  Future<XFile?> _showImagePickerBottomSheet() async {
    final Completer<XFile?> completer = Completer<XFile?>();
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Business Logo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Get.back();
                
                final XFile? image = await _imageUploadService.pickImageFromGallery();
                
                completer.complete(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Get.back();
                
                final XFile? image = await _imageUploadService.pickImageFromCamera();
                
                completer.complete(image);
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Get.back();
                completer.complete(null);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    
    return completer.future;
  }

  void removeBusinessLogo() {
    businessLogoUrl.value = '';
    tempLogoPath.value = '';
    hasChanges.value = true;
  }

  // Geolocation methods
  Future<void> getCurrentLocation() async {
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
        hasChanges.value = true;
        
        // Update map coordinates for consistency
        selectedLatitude.value = locationDetails.latitude;
        selectedLongitude.value = locationDetails.longitude;
        hasLocationSelected.value = true;
        
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

  // Get formatted location display
  String get currentLocationDisplay {
    if (currentGeoLocation.value.isEmpty) return 'No location set';
    
    final coords = _locationService.parseGeoLocation(currentGeoLocation.value);
    if (coords != null) {
      return 'Lat: ${coords['latitude']!.toStringAsFixed(6)}, Lng: ${coords['longitude']!.toStringAsFixed(6)}';
    }
    
    return 'No location set';
  }

  // Check if location is set
  bool get hasLocationSet => currentGeoLocation.value.isNotEmpty;

  // Map functionality methods
  void _setDefaultLocation() {
    selectedLatitude.value = AppConstants.defaultLatitude;
    selectedLongitude.value = AppConstants.defaultLongitude;
    hasLocationSelected.value = false;
  }

  void toggleMapSelection() {
    if (_isDisposed) return;
    showMapSelection.value = !showMapSelection.value;
  }

  void onMapTap(double latitude, double longitude) {
    if (_isDisposed) return;
selectedLatitude.value = latitude;
    selectedLongitude.value = longitude;
    hasLocationSelected.value = true;
    
    // Update location coordinates in same format as getCurrentLocation
    currentGeoLocation.value = '$latitude,$longitude';
    hasChanges.value = true;
// Reverse geocoding and auto-fill
    _updateAddressFromCoordinates(latitude, longitude);
    _moveMap();
    
    Get.snackbar(
      'Location Selected',
      'Fetching address details...',
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      colorText: Colors.blue,
      duration: const Duration(seconds: 2),
    );
    
    AnalyticsService.to.logEvent('seller_profile_select_location', parameters: {
      'lat': latitude,
      'lng': longitude,
    });
  }

  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      // Show loading feedback
      Get.snackbar(
        'Getting Address',
        'Fetching location details...',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        colorText: Colors.blue,
        duration: const Duration(seconds: 1),
      );

      // Use Google Geocoding API instead of Nominatim
      final apiKey = AppConstants.googlePlacesApiKey;
      if (apiKey.isEmpty) {
        // Fallback: set coordinates as address
        addressController.text = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
        Get.snackbar(
          'Google Geocoding disabled',
          'API key missing. Set --dart-define=GOOGLE_PLACES_API_KEY=YOUR_KEY',
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
      );
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

          // Extract structured address components
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
          if (area.isNotEmpty) areaController.text = area;

          final city = _getByTypes(['locality', 'administrative_area_level_2']);
          if (city.isNotEmpty) cityController.text = city;

          final state = _getByTypes(['administrative_area_level_1']);
          if (state.isNotEmpty) stateController.text = state;

          final pincode = _getByTypes(['postal_code']);
          if (pincode.isNotEmpty) pincodeController.text = pincode;

          // Force UI update
          update();

          Get.snackbar(
            'Address Updated',
            'Location details fetched successfully',
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 2),
          );
        } else {
          // Fallback when no results
          addressController.text = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
          Get.snackbar(
            'Address Not Found',
            'Could not get detailed address information',
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            colorText: Colors.orange,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Fallback: set coordinates as address
        addressController.text = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
        Get.snackbar(
          'Address Error',
          'Could not fetch address details (Status: ${res.statusCode})',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Fallback: set coordinates as address
      addressController.text = 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
      Get.snackbar(
        'Address Error',
        'Network error: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void zoomIn() {
    if (_isDisposed) return;
    if (currentZoom.value < AppConstants.maxZoom) {
      currentZoom.value = currentZoom.value + 1;
      _moveMap();
    }
  }

  void zoomOut() {
    if (_isDisposed) return;
    if (currentZoom.value > AppConstants.minZoom) {
      currentZoom.value = currentZoom.value - 1;
      _moveMap();
    }
  }

  void _moveMap({double? zoom}) {
    if (_isDisposed) return;
    
    final target = ll.LatLng(selectedLatitude.value, selectedLongitude.value);
    final z = zoom ?? currentZoom.value;
    try {
      mapController.move(target, z);
    } catch (_) {
      // Map may not be ready yet; ignore
    }
  }

  // Search functionality
  List<Map<String, dynamic>> get searchResults => _searchResults;

  Future<void> searchLocation(String query, {bool showToast = false}) async {
    if (_isDisposed || query.trim().isEmpty) return;
    locationSearchQuery.value = query;
    
  // Use Google Places (v1) Text Search
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

    // Build Text Search request (v1)
    // Session token kept for parity, though v1 doesn't require it the same way
    _placesSessionToken ??= const Uuid().v4();
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
      // Return only what we need to avoid payload bloat
      'X-Goog-FieldMask': 'places.name,places.displayName,places.formattedAddress,places.location,places.addressComponents',
    };
try {
      final res = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final List places = (data['places'] as List?) ?? const [];
        _searchResults.assignAll(places.map<Map<String, dynamic>>((p) {
          final name = p['name']?.toString() ?? '';// e.g., places/ChIJ...
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
          Get.snackbar('No results', 'No places found for "$query"', snackPosition: SnackPosition.BOTTOM);
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
    }
    
  }

  // Note: OSM fallback removed to ensure only Google Places powers search

  
  void clearSearch() {
    if (_isDisposed) return;
    searchTextController.clear();
    locationSearchQuery.value = '';
    _searchResults.clear();
  }

  // DEBUG: Test method to check location functionality
  Future<void> testLocationService() async {
    if (_isDisposed) return;
// Test with coordinates for Mumbai, India
    const testLat = 19.0760;
    const testLng = 72.8777;
try {
      // Test reverse geocoding
      await _updateAddressFromCoordinates(testLat, testLng);
      
      // Test coordinate update
      selectedLatitude.value = testLat;
      selectedLongitude.value = testLng;
      hasLocationSelected.value = true;
      currentGeoLocation.value = '$testLat,$testLng';
      
      _moveMap();
      
      Get.snackbar(
        'Test Complete',
        'Check console logs and address fields',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
      );
} catch (e) {
Get.snackbar(
        'Test Error',
        'Test failed: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> selectSearchResult(Map<String, dynamic> item) async {
    if (_isDisposed) return;
    // Prefer using data already present from v1 search
    final lat = (item['lat'] as num?)?.toDouble();
    final lon = (item['lng'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      selectedLatitude.value = lat;
      selectedLongitude.value = lon;
      hasLocationSelected.value = true;
      currentGeoLocation.value = '$lat,$lon';
      hasChanges.value = true;

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

      update();
      Get.snackbar(
        'Location Selected',
        'Address updated from Google Places',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } else {
      // As a fallback, attempt v1 details to get coordinates
      final placeId = item['place_id']?.toString();
      if (placeId == null || placeId.isEmpty) {
        Get.snackbar('Selection Error', 'Missing place id for details', snackPosition: SnackPosition.BOTTOM);
      } else {
        try {
          final detailsUri = Uri.parse('https://places.googleapis.com/v1/$placeId');
          final headers = {
            'X-Goog-Api-Key': AppConstants.googlePlacesApiKey,
            'X-Goog-FieldMask': 'displayName,formattedAddress,location,addressComponents',
          };
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
              hasChanges.value = true;
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
            update();
            Get.snackbar('Location Selected', 'Address updated from Google Places', backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green, duration: const Duration(seconds: 2));
          } else {
            Get.snackbar('Google Place Details HTTP Error', 'Status code: ${res.statusCode}', snackPosition: SnackPosition.BOTTOM);
}
        } catch (e) {
          Get.snackbar('Google Place Details Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
}
      }
    }
    _searchResults.clear();
  // Reset session token after a selection is made
  _placesSessionToken = null;
    _moveMap();
}

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Check if profile is published and business logo is being removed
    final seller = currentSeller.value;
    if (seller?.ispublished == true && businessLogoUrl.value.isEmpty) {
      Get.snackbar(
        'Business Logo Required', 
        'Business logo cannot be removed from a published profile.',
        backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
        colorText: AppTheme.errorColor,
      );
      return;
    }

    try {
      isSaving.value = true;

      if (seller?.sellerid == null) {
        Get.snackbar('Error', 'No seller profile found');
        return;
      }

      // Create updated seller details
      final updatedSeller = SellerDetails(
        sellerid: seller!.sellerid,
        userid: seller.userid,
        businessname: businessNameController.text.trim(),
        profilename: profileNameController.text.trim(),
        bio: bioController.text.trim().isNotEmpty ? bioController.text.trim() : null,
        logo: businessLogoUrl.value.isNotEmpty ? businessLogoUrl.value : null,
        contactno: contactController.text.trim().isNotEmpty ? contactController.text.trim() : null,
        mobileno: mobileController.text.trim().isNotEmpty ? mobileController.text.trim() : null,
        whatsappno: whatsappController.text.trim().isNotEmpty ? whatsappController.text.trim() : null,
        address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
        area: areaController.text.trim().isNotEmpty ? areaController.text.trim() : null,
        city: cityController.text.trim().isNotEmpty ? cityController.text.trim() : null,
        state: stateController.text.trim().isNotEmpty ? stateController.text.trim() : null,
        pincode: pincodeController.text.trim().isNotEmpty ? pincodeController.text.trim() : null,
        geolocation: currentGeoLocation.value.isNotEmpty ? currentGeoLocation.value : null, // Save geolocation
        establishedyear: establishedYearController.text.trim().isNotEmpty 
            ? int.tryParse(establishedYearController.text.trim()) : null,
        ispublished: seller.ispublished,
        publishedat: seller.publishedat,
      );

      // Update seller details
      final response = await _sellerService.updateSeller(updatedSeller);
      
      if (response.success) {
        // Update social media URLs
        await _saveSocialUrls(seller.sellerid!);
        
        hasChanges.value = false;
        Get.snackbar(
          'Success',
          'Profile updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error', response.message ?? 'Failed to update profile');
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to save profile changes');
      
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _saveSocialUrls(int sellerId) async {
   
      for (var entry in socialControllers.entries) {
        final smId = int.tryParse(entry.key);
        final url = entry.value.text.trim();
        
        if (smId != null) {
          // Check if URL already exists
          final existingUrl = socialUrls.firstWhereOrNull(
            (u) => u.smid == smId,
          );
          
          if (url.isNotEmpty) {
            // URL has content - create or update
            final sellerUrl = SellerUrl(
              sellerid: sellerId,
              smid: smId,
              urllink: url,
            );
            
            if (existingUrl != null) {
              // Update existing URL
              await _sellerService.updateSellerUrl(sellerUrl);
            } else {
              // Create new URL
              await _sellerService.addSellerUrl(sellerUrl);
            }
          } else if (existingUrl != null) {
            // URL was cleared - delete existing URL
            await _sellerService.deleteSellerUrl(existingUrl);
          }
        }
      }
      
      // Reload social URLs to refresh the list
      await _loadSocialUrls(sellerId);
      
  
  }

  void _onFieldChanged() {
    // Safety check to prevent errors after disposal
    if (_isDisposed) return;
    hasChanges.value = true;
    // Trigger validation update
    _validationUpdateTrigger.toggle();
  }

  void discardChanges() {
    Get.dialog(
      AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool get canSave {
    return hasChanges.value && 
           isProfileValid &&
           !isSaving.value;
  }

  // Validation Methods
  bool get isProfileValid {
    if (_isDisposed) return false;
    _validationUpdateTrigger.value; // Make reactive
  return isBusinessNameValid && isProfileNameValid && isBusinessLocationValid && isContactInfoValid;
  }
  
  bool get isBusinessNameValid {
    if (_isDisposed) return false;
    _validationUpdateTrigger.value; // Make reactive
    return businessNameController.text.trim().isNotEmpty;
  }
  
  bool get isBusinessLocationValid {
    if (_isDisposed) return false;
    _validationUpdateTrigger.value; // Make reactive
    return addressController.text.trim().isNotEmpty &&
           cityController.text.trim().isNotEmpty &&
           currentGeoLocation.value.trim().isNotEmpty;
  }
  
  bool get isContactInfoValid {
    if (_isDisposed) return false;
    _validationUpdateTrigger.value; // Make reactive
    return contactController.text.trim().isNotEmpty &&
           mobileController.text.trim().isNotEmpty &&
           whatsappController.text.trim().isNotEmpty;
  }
  
  bool get isProfileNameValid {
    if (_isDisposed) return false;
    _validationUpdateTrigger.value; // Make reactive
    final v = profileNameController.text.trim();
    if (v.isEmpty) return false;
    if (v.contains(' ')) return false;
    if (v.toLowerCase() != v) return false;
    if (!isProfileNameAvailable.value) return false;
    return true;
  }
  
  List<String> get validationErrors {
    if (_isDisposed) return [];
    _validationUpdateTrigger.value; // Make reactive
    List<String> errors = [];
    if (!isProfileNameValid) {
      errors.add(profileNameError.value.isNotEmpty ? profileNameError.value : 'Profile Name must be lowercase, no spaces, and unique');
    }
    if (!isBusinessNameValid) errors.add('Business Name is required');
    if (!isBusinessLocationValid) {
      if (addressController.text.trim().isEmpty) errors.add('Business Address is required');
      if (cityController.text.trim().isEmpty) errors.add('Business City is required');
      if (currentGeoLocation.value.trim().isEmpty) errors.add('Business Location coordinates are required');
    }
    if (!isContactInfoValid) {
      if (contactController.text.trim().isEmpty) errors.add('Contact Number is required');
      if (mobileController.text.trim().isEmpty) errors.add('Mobile Number is required');
      if (whatsappController.text.trim().isEmpty) errors.add('WhatsApp Number is required');
    }
    return errors;
  }

  double get profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 13; // Total important fields (added geolocation)

    if (businessNameController.text.trim().isNotEmpty) completedFields++;
    if (profileNameController.text.trim().isNotEmpty) completedFields++;
    if (bioController.text.trim().isNotEmpty) completedFields++;
    if (contactController.text.trim().isNotEmpty) completedFields++;
    if (mobileController.text.trim().isNotEmpty) completedFields++;
    if (whatsappController.text.trim().isNotEmpty) completedFields++;
    if (addressController.text.trim().isNotEmpty) completedFields++;
    if (cityController.text.trim().isNotEmpty) completedFields++;
    if (stateController.text.trim().isNotEmpty) completedFields++;
    if (businessLogoUrl.value.isNotEmpty) completedFields++;
    if (socialControllers.values.any((c) => c.text.trim().isNotEmpty)) completedFields++;
    if (establishedYearController.text.trim().isNotEmpty) completedFields++;
    if (currentGeoLocation.value.isNotEmpty) completedFields++; // Added geolocation check

    return completedFields / totalFields;
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../services/location_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../core/theme/app_theme.dart';

class SellerProfileEditController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  final ImageUploadService _imageUploadService = Get.find<ImageUploadService>();
  final LocationService _locationService = Get.find<LocationService>();
  
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
  final Map<String, TextEditingController> socialControllers = {};
  
  // Profile images - only business logo
  final RxString businessLogoUrl = ''.obs;
  final RxString tempLogoPath = ''.obs; // For immediate local preview
  
  // Geolocation
  final RxString currentGeoLocation = ''.obs; // Format: "latitude,longitude"
  final RxBool isGettingLocation = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isUploadingLogo = false.obs;
  final RxBool hasChanges = false.obs;
  
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _loadCurrentProfile();
    _setupListeners();
  }

  @override
  void onClose() {
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
        await _loadSocialUrls(response.data!.sellerid!);
      } else {
        Get.snackbar('Info', 'No seller profile found. Please complete onboarding first.');
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile data');
      print('Profile loading error: $e');
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
  }

  Future<void> _loadSocialUrls(int sellerId) async {
    try {
      final response = await _sellerService.getSellerUrls(sellerId);
      if (response.success && response.data != null) {
        socialUrls.value = response.data!;
        
        // Setup controllers for each social media
        for (var url in socialUrls) {
          if (url.smid != null) {
            final key = url.smid.toString();
            socialControllers[key] = TextEditingController(text: url.urllink);
            socialControllers[key]!.addListener(_onFieldChanged);
          }
        }
      }
    } catch (e) {
      print('Error loading social URLs: $e');
    }
  }

  void _setupListeners() {
    // Add listeners to detect changes
    businessNameController.addListener(_onFieldChanged);
    profileNameController.addListener(_onFieldChanged);
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
  }

  void _disposeControllers() {
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
  }

  // Image handling methods - only business logo
  Future<void> _loadExistingBusinessLogo(String logoValue) async {
    try {
      print('🖼️ Loading existing business logo: $logoValue');
      
      // Check if it's already a full URL (presigned URL or direct URL)
      if (logoValue.startsWith('http://') || logoValue.startsWith('https://')) {
        // It's already a full URL, use it directly
        businessLogoUrl.value = logoValue;
        print('✅ Using existing full URL: $logoValue');
        return;
      }
      
      // It might be a file key, try to get presigned URL
      final presignedUrl = await _imageUploadService.getPresignedUrl(logoValue);
      if (presignedUrl != null) {
        businessLogoUrl.value = presignedUrl;
        print('✅ Got presigned URL for existing logo: $presignedUrl');
      } else {
        // Fallback: construct direct S3 URL (might give 403 but better than nothing)
        if (logoValue.contains('/')) {
          // Assume it's a file key like "logos/filename.jpg"
          businessLogoUrl.value = 'https://findmebiz.s3.amazonaws.com/$logoValue';
          print('⚠️ Using fallback S3 URL: ${businessLogoUrl.value}');
        } else {
          // It's something else, use as is
          businessLogoUrl.value = logoValue;
          print('⚠️ Using logo value as is: $logoValue');
        }
      }
      
    } catch (e) {
      print('❌ Error loading existing business logo: $e');
      // Still set the original value as fallback
      businessLogoUrl.value = logoValue;
    }
  }

  Future<void> updateBusinessLogo() async {
    print('🖼️ Starting business logo update...');
    
    try {
      isUploadingLogo.value = true;
      
      // Get image selection directly using the service's built-in dialog
      print('📱 Opening image picker...');
      final XFile? selectedImage = await _showImagePickerBottomSheet();
      
      print('📷 Final image picker result: ${selectedImage?.path ?? 'null'}');
      
      if (selectedImage == null) {
        print('❌ No image selected');
        isUploadingLogo.value = false;
        return;
      }
      
      // IMMEDIATE UI UPDATE - Set temporary path for immediate preview
      print('✅ Setting temp path: ${selectedImage.path}');
      tempLogoPath.value = selectedImage.path;
      hasChanges.value = true;
      
      // Force UI update
      update();
      
      print('🔄 UI should now show selected image');
      print('🔄 tempLogoPath is now: ${tempLogoPath.value}');
      
      // Show immediate feedback that image is selected
      Get.snackbar(
        'Image Selected', 
        'Uploading business logo...',
        backgroundColor: AppTheme.sellerPrimary.withOpacity(0.1),
        colorText: AppTheme.sellerPrimary,
        duration: const Duration(seconds: 2),
      );
      
      // Validate image before upload
      print('🔍 Validating image...');
      if (!await _imageUploadService.validateImageForUpload(selectedImage)) {
        print('❌ Image validation failed');
        tempLogoPath.value = ''; // Clear temp path on validation failure
        isUploadingLogo.value = false;
        return;
      }
      
      print('🚀 Starting upload...');
      final String? uploadedUrl = await _imageUploadService.uploadBusinessLogo(selectedImage);
      print('📤 Upload result: ${uploadedUrl ?? 'null'}');
      
      if (uploadedUrl != null) {
        businessLogoUrl.value = uploadedUrl;
        tempLogoPath.value = ''; // Clear temp path once uploaded
        hasChanges.value = true;
        print('✅ Upload successful: $uploadedUrl');
        Get.snackbar(
          'Success', 
          'Business logo updated successfully!',
          backgroundColor: AppTheme.successColor.withOpacity(0.1),
          colorText: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        );
      } else {
        tempLogoPath.value = ''; // Clear temp path on upload failure
        print('❌ Upload failed');
        Get.snackbar(
          'Upload Failed', 
          'Failed to upload business logo. Please try again.',
          backgroundColor: AppTheme.errorColor.withOpacity(0.1),
          colorText: AppTheme.errorColor,
        );
      }
    } catch (e) {
      tempLogoPath.value = ''; // Clear temp path on error
      print('💥 Upload error: $e');
      Get.snackbar(
        'Error', 
        'Failed to upload business logo: ${e.toString()}',
        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
        colorText: AppTheme.errorColor,
      );
    } finally {
      isUploadingLogo.value = false;
      print('🏁 Upload process finished');
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
                print('📱 Opening gallery...');
                final XFile? image = await _imageUploadService.pickImageFromGallery();
                print('📷 Gallery result: ${image?.path ?? 'null'}');
                completer.complete(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Get.back();
                print('📸 Opening camera...');
                final XFile? image = await _imageUploadService.pickImageFromCamera();
                print('📷 Camera result: ${image?.path ?? 'null'}');
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
        backgroundColor: Colors.blue.withOpacity(0.1),
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
        
        Get.snackbar(
          'Location Updated',
          'Address fields have been filled with your current location.',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      print('Location error: $e');
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

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isSaving.value = true;

      final seller = currentSeller.value;
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
      print('Save profile error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _saveSocialUrls(int sellerId) async {
    try {
      for (var entry in socialControllers.entries) {
        final smId = int.tryParse(entry.key);
        final url = entry.value.text.trim();
        
        if (smId != null && url.isNotEmpty) {
          final sellerUrl = SellerUrl(
            sellerid: sellerId,
            smid: smId,
            urllink: url,
          );
          
          // Check if URL already exists
          final existingUrl = socialUrls.firstWhereOrNull(
            (u) => u.smid == smId,
          );
          
          if (existingUrl != null) {
            // Update existing URL
            await _sellerService.updateSellerUrl(sellerUrl);
          } else {
            // Create new URL
            await _sellerService.addSellerUrl(sellerUrl);
          }
        }
      }
    } catch (e) {
      print('Error saving social URLs: $e');
    }
  }

  void _onFieldChanged() {
    hasChanges.value = true;
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
           businessNameController.text.trim().isNotEmpty &&
           profileNameController.text.trim().isNotEmpty &&
           !isSaving.value;
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

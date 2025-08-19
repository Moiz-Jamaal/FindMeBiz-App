import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/role_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/location_service.dart';
import '../../../../data/models/api/index.dart';

class SellerOnboardingController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final LocationService _locationService = Get.find<LocationService>();
  final RoleService _roleService = Get.find<RoleService>();
  
  // Current step in onboarding process
  final RxInt currentStep = 0.obs;
  
  // Form controllers
  final businessNameController = TextEditingController();
  final profileNameController = TextEditingController();
  final bioController = TextEditingController();
  final contactController = TextEditingController();
  final addressController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final establishedYearController = TextEditingController();
  
  // Reactive mirrors of text fields for UI enable/disable states
  final RxString businessName = ''.obs;
  final RxString profileName = ''.obs;
  
  // Form keys
  final basicInfoFormKey = GlobalKey<FormState>();
  final contactInfoFormKey = GlobalKey<FormState>();
  final businessInfoFormKey = GlobalKey<FormState>();
  
  // Observable data
  final RxList<CategoryMaster> availableCategories = <CategoryMaster>[].obs;
  final RxList<CategoryMaster> selectedCategories = <CategoryMaster>[].obs;
  final RxString logoPath = ''.obs;
  
  // Location data
  final RxString currentLocation = ''.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool hasLocationPermission = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
    _prefillUserData();

    // Keep reactive values in sync with text inputs
    businessNameController.addListener(() {
      businessName.value = businessNameController.text;
    });
    profileNameController.addListener(() {
      profileName.value = profileNameController.text;
    });
    // Initialize with current text (if any)
    businessName.value = businessNameController.text;
    profileName.value = profileNameController.text;
  }

  @override
  void onClose() {
    businessNameController.dispose();
    profileNameController.dispose();
    bioController.dispose();
    contactController.dispose();
    addressController.dispose();
    areaController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    establishedYearController.dispose();
    super.onClose();
  }

  // Load categories from API
  Future<void> _loadCategories() async {
    try {
      isLoading.value = true;
      final response = await _categoryService.getCategories();
      
      if (response.success && response.data != null) {
        availableCategories.value = response.data!;
      } else {
        Get.snackbar(
          'Error',
          'Failed to load categories',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to connect to server',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Prefill data from current user
  void _prefillUserData() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      contactController.text = currentUser.mobileno ?? '';
    }
  }

  void nextStep() {
    if (_validateCurrentStep() && currentStep.value < 3) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        return basicInfoFormKey.currentState?.validate() ?? false;
      case 1:
        return contactInfoFormKey.currentState?.validate() ?? false;
      case 2:
        return businessInfoFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  // Category management
  void toggleCategory(CategoryMaster category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }

  bool isCategorySelected(CategoryMaster category) {
    return selectedCategories.contains(category);
  }

  // Logo management
  void setLogo(String path) {
    logoPath.value = path;
  }

  void removeLogo() {
    logoPath.value = '';
  }

  // Location management
  Future<void> getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      
      final locationData = await _locationService.getCurrentLocationWithAddress();
      if (locationData != null) {
        addressController.text = locationData.formattedAddress;
        currentLocation.value = locationData.geoLocationString;
        
        Get.snackbar(
          'Location Found',
          'Address updated with your current location',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Failed to get current location',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  Future<void> requestLocationPermission() async {
    hasLocationPermission.value = await _locationService.checkAndRequestPermissions();
    if (hasLocationPermission.value) {
      await getCurrentLocation();
    }
  }

  // Complete onboarding process
  Future<void> completeOnboarding() async {
    if (!_validateCurrentStep()) return;
    
    isSubmitting.value = true;
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Error',
          'No user found. Please login again.',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      // Create seller details
      final sellerDetails = SellerDetails(
        userid: currentUser.userid,
        businessname: businessNameController.text.trim(),
        profilename: profileNameController.text.trim(),
        bio: bioController.text.trim().isNotEmpty ? bioController.text.trim() : null,
        logo: logoPath.value.isNotEmpty ? logoPath.value : null,
        contactno: contactController.text.trim().isNotEmpty ? contactController.text.trim() : null,
        mobileno: currentUser.mobileno,
        whatsappno: currentUser.whatsappno,
        address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
        area: areaController.text.trim().isNotEmpty ? areaController.text.trim() : null,
        city: cityController.text.trim().isNotEmpty ? cityController.text.trim() : null,
        state: stateController.text.trim().isNotEmpty ? stateController.text.trim() : null,
        pincode: pincodeController.text.trim().isNotEmpty ? pincodeController.text.trim() : null,
        geolocation: currentLocation.value.isNotEmpty ? currentLocation.value : null,
        establishedyear: establishedYearController.text.trim().isNotEmpty ? int.tryParse(establishedYearController.text.trim()) : null,
        ispublished: false,
      );

      // Create seller profile
      final sellerResponse = await _sellerService.createSeller(sellerDetails);
      
      if (!sellerResponse.success || sellerResponse.data == null) {
        Get.snackbar(
          'Error',
          sellerResponse.message ?? 'Failed to create seller profile',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      final sellerId = sellerResponse.data!.sellerid;
      if (sellerId == null) {
        Get.snackbar(
          'Error',
          'Invalid seller ID received',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      // Add selected categories
      for (final category in selectedCategories) {
        if (category.catid != null) {
          final sellerCategory = SellerCategory(
            sellerid: sellerId,
            catid: category.catid,
            active: true,
          );
          
          await _sellerService.addSellerCategory(sellerCategory);
        }
      }

      // Create default seller settings
      final sellerSettings = SellerSettings(
        sellerid: sellerId,
        isopen: true,
        subscriptionPlan: 'basic',
      );
      
      await _sellerService.createSellerSettings(sellerSettings);

      // Mark seller as onboarded
      _roleService.markSellerOnboarded();
      
      Get.snackbar(
        'Success',
        'Seller profile created successfully!',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
      
      // Navigate to seller dashboard
      Get.offAllNamed('/seller-dashboard');
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete onboarding. Please try again.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      print('Onboarding error: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  // Form validators
  String? businessNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }
    if (value.trim().length < 2) {
      return 'Business name must be at least 2 characters';
    }
    return null;
  }

  String? profileNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Profile name is required';
    }
    if (value.trim().length < 3) {
      return 'Profile name must be at least 3 characters';
    }
    if (value.trim().contains(' ')) {
      return 'Profile name cannot contain spaces';
    }
    return null;
  }

  String? contactValidator(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (!GetUtils.isPhoneNumber(value.trim())) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  String? pincodeValidator(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length != 6 || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
        return 'Pincode must be 6 digits';
      }
    }
    return null;
  }

  String? yearValidator(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final year = int.tryParse(value.trim());
      if (year == null || year < 1900 || year > DateTime.now().year) {
        return 'Please enter a valid year';
      }
    }
    return null;
  }

  bool get canProceed {
    switch (currentStep.value) {
      case 0:
  return businessName.value.trim().isNotEmpty && 
         profileName.value.trim().isNotEmpty;
      case 1:
        return true; // Contact info is optional
      case 2:
        return selectedCategories.isNotEmpty;
      case 3:
        return true; // Final step - review
      default:
        return false;
    }
  }

  bool get isLastStep => currentStep.value == 3;
}

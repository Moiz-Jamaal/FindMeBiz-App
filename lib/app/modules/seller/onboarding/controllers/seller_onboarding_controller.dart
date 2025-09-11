import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../shared/widgets/location_selector/index.dart';

class SellerOnboardingController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  
  // Location selector controller
  late final LocationSelectorController locationSelector;
  
  // Current step in onboarding process
  final RxInt currentStep = 0.obs;
  
  // Form controllers
  final businessNameController = TextEditingController();
  final profileNameController = TextEditingController();
  final bioController = TextEditingController();
  final contactController = TextEditingController();
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
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Initialize location selector
    locationSelector = LocationSelectorController();
    Get.put(locationSelector, tag: 'onboarding_location');
    
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
    establishedYearController.dispose();
    
    // Dispose location selector
    if (Get.isRegistered<LocationSelectorController>(tag: 'onboarding_location')) {
      Get.delete<LocationSelectorController>(tag: 'onboarding_location');
    }
    
    super.onClose();
  }

  // Load categories from API
  Future<void> _loadCategories() async {
    try {
      isLoading.value = true;
      final response = await _categoryService.getCategories();
      if (response.success && response.data != null) {
        availableCategories.assignAll(response.data!);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load categories: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
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
      profileNameController.text = currentUser.fullname ?? '';
      profileName.value = currentUser.fullname ?? '';
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
      case 0: // Basic info
        return basicInfoFormKey.currentState?.validate() ?? false;
      case 1: // Contact info
        return contactInfoFormKey.currentState?.validate() ?? false;
      case 2: // Business info
        return businessInfoFormKey.currentState?.validate() ?? false;
      case 3: // Location (handled by location selector)
        return locationSelector.isValid;
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

  // Location management - delegated to location selector
  bool get hasLocationSet => locationSelector.hasLocationSet;
  String get currentLocationDisplay => locationSelector.currentLocationDisplay;

  // Complete onboarding process
  Future<void> completeOnboarding() async {
    if (!_validateCurrentStep()) {
      Get.snackbar(
        'Validation Error',
        'Please complete all required fields',
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        colorText: Colors.orange,
      );
      return;
    }

    try {
      isSubmitting.value = true;

      final stallLocation = locationSelector.currentStallLocation;
      
      // Create SellerDetails object
      final sellerDetails = SellerDetails(
        businessname: businessNameController.text.trim(),
        profilename: profileNameController.text.trim(),
        bio: bioController.text.trim(),
        contactno: contactController.text.trim(),
        logo: logoPath.value,
        establishedyear: establishedYearController.text.trim().isNotEmpty 
            ? int.tryParse(establishedYearController.text.trim()) 
            : null,
        address: stallLocation?.address,
        area: stallLocation?.area,
        city: stallLocation?.city,
        state: stallLocation?.state,
        pincode: stallLocation?.pincode,
        geolocation: stallLocation?.geolocation,
        ispublished: false,
      );

      final response = await _sellerService.createSeller(sellerDetails);
      
      if (response.success) {
        // Track analytics
        AnalyticsService.to.logEvent('seller_onboarding_complete', parameters: {
          'business_name': businessNameController.text.trim(),
          'categories_count': selectedCategories.length,
          'has_location': stallLocation != null,
          'established_year': establishedYearController.text.trim(),
        });

        Get.snackbar(
          'Success',
          'Your seller profile has been created successfully!',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 3),
        );

        // Navigate to seller home
        Get.offAllNamed('/seller-home');
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to create seller profile',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create seller profile: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
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
    if (value.trim().length < 2) {
      return 'Profile name must be at least 2 characters';
    }
    return null;
  }

  String? contactValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    if (!RegExp(r'^\+?[\d\s\-\(\)]{10,15}$').hasMatch(value.trim())) {
      return 'Please enter a valid contact number';
    }
    return null;
  }

  String? yearValidator(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final year = int.tryParse(value.trim());
      if (year == null) {
        return 'Please enter a valid year';
      }
      final currentYear = DateTime.now().year;
      if (year < 1900 || year > currentYear) {
        return 'Please enter a year between 1900 and $currentYear';
      }
    }
    return null;
  }

  bool get canProceed {
    return businessName.value.trim().isNotEmpty && 
           profileName.value.trim().isNotEmpty;
  }

  bool get isLastStep => currentStep.value == 3;
}

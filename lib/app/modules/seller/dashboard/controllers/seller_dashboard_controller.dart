import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../data/models/api/index.dart';

class SellerDashboardController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  
  // Current navigation index
  final RxInt currentIndex = 0.obs;
  
  // Dashboard statistics (keeping as dummy for now as requested)
  final RxInt totalProducts = 0.obs;
  final RxInt totalViews = 0.obs;
  final RxInt totalReviews = 0.obs;
  final RxDouble profileCompletion = 0.75.obs;
  
  // Profile data
  final Rx<SellerDetailsExtended?> sellerProfile = Rx<SellerDetailsExtended?>(null);
  final RxString businessName = 'My Business'.obs;
  final RxBool isProfilePublished = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      isLoading.value = true;
      
      final currentUser = _authService.currentUser;
      if (currentUser?.userid == null) {
        Get.snackbar(
          'Error',
          'No user found. Please login again.',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      // Load seller profile data
      final response = await _sellerService.getSellerByUserId(currentUser!.userid!);
      
      if (response.success && response.data != null) {
        sellerProfile.value = response.data;
        businessName.value = response.data!.businessname ?? 'My Business';
        isProfilePublished.value = response.data!.ispublished ?? false;
        
        // Calculate profile completion based on filled fields
        profileCompletion.value = _calculateProfileCompletion(response.data!);
      } else {
        // If no seller profile exists yet, user needs to complete onboarding
        businessName.value = currentUser.fullname ?? 'My Business';
        isProfilePublished.value = false;
        profileCompletion.value = 0.0;
      }
      
      // Load dummy statistics (as requested)
      _loadDummyStatistics();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load dashboard data',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      
    } finally {
      isLoading.value = false;
    }
  }

  void _loadDummyStatistics() {
    // Mock data as requested
    totalProducts.value = 5;
    totalViews.value = 120;
    totalReviews.value = 8;
  }

  double _calculateProfileCompletion(SellerDetailsExtended seller) {
    int completedFields = 0;
    int totalFields = 13; // Matching edit controller fields

    if (seller.businessname?.isNotEmpty == true) completedFields++;
    if (seller.profilename?.isNotEmpty == true) completedFields++;
    if (seller.bio?.isNotEmpty == true) completedFields++;
    if (seller.logo?.isNotEmpty == true) completedFields++;
    if (seller.contactno?.isNotEmpty == true) completedFields++;
    if (seller.mobileno?.isNotEmpty == true) completedFields++;
    if (seller.whatsappno?.isNotEmpty == true) completedFields++;
    if (seller.address?.isNotEmpty == true) completedFields++;
    if (seller.city?.isNotEmpty == true) completedFields++;
    if (seller.state?.isNotEmpty == true) completedFields++;
    if (seller.establishedyear != null) completedFields++;
    if (seller.geolocation?.isNotEmpty == true) completedFields++;
    if (seller.urls?.isNotEmpty == true) completedFields++;

    return completedFields / totalFields;
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void addProduct() {
    Get.toNamed('/seller-add-product');
  }

  void editProfile() {
    Get.toNamed('/seller-profile-edit');
  }

  void viewAnalytics() {
    Get.toNamed('/seller-analytics');
  }

  void manageAdvertising() {
    Get.toNamed('/seller-advertising');
  }

  void publishProfile() {
    Get.toNamed('/seller-publish');
  }

  void setStallLocation() {
    Get.toNamed('/seller-stall-location');
  }

  void viewProducts() {
    // Navigate to products tab (index 1 in the dashboard)
    changeTab(1);
  }

  void previewProfile() {
    Get.toNamed('/seller-profile-edit');
  }

  


  void refreshData() {
    _loadDashboardData();
  }
}

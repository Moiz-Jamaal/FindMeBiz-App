import 'package:get/get.dart';

class SellerDashboardController extends GetxController {
  // Current navigation index
  final RxInt currentIndex = 0.obs;
  
  // Dashboard statistics
  final RxInt totalProducts = 0.obs;
  final RxInt totalViews = 0.obs;
  final RxInt totalContacts = 0.obs;
  final RxDouble profileCompletion = 0.75.obs;
  
  // Profile data
  final RxString businessName = 'My Business'.obs;
  final RxBool isProfilePublished = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    isLoading.value = true;
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      // Mock data
      totalProducts.value = 5;
      totalViews.value = 120;
      totalContacts.value = 8;
      businessName.value = 'Surat Silk Emporium';
      
      isLoading.value = false;
    });
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

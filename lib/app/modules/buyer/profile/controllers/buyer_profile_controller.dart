import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/buyer.dart';
import '../../../../core/theme/app_theme.dart';

class BuyerProfileController extends GetxController {
  // User profile data
  final Rx<Buyer?> buyer = Rx<Buyer?>(null);
  
  // Profile sections
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  
  // Statistics
  final RxInt favoriteCount = 0.obs;
  final RxInt reviewsCount = 0.obs;
  final RxInt orderHistory = 0.obs;
  
  // Settings
  final RxBool notificationsEnabled = true.obs;
  final RxBool locationEnabled = true.obs;
  final RxString preferredLanguage = 'English'.obs;
  final RxString theme = 'System'.obs;
  
  // Profile image
  final RxString profileImagePath = ''.obs;
  
  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
  }
  
  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }
  
  void _loadProfileData() {
    isLoading.value = true;
    
    // Simulate loading profile data
    Future.delayed(const Duration(milliseconds: 800), () {
      // Mock buyer data
      buyer.value = Buyer(
        id: 'buyer_001',
        email: 'buyer@example.com',
        fullName: 'Ahmed Al-Mansoori',
        phoneNumber: '+971 50 123 4567',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        preferredLanguage: 'English',
        address: 'Dubai, UAE',
      );
      
      // Update form controllers
      nameController.text = buyer.value?.fullName ?? '';
      emailController.text = buyer.value?.email ?? '';
      phoneController.text = buyer.value?.phoneNumber ?? '';
      addressController.text = buyer.value?.address ?? '';
      
      // Load statistics
      favoriteCount.value = 12;
      reviewsCount.value = 8;
      orderHistory.value = 25;
      
      isLoading.value = false;
    });
  }
  
  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    
    if (!isEditing.value) {
      // Save changes
      _saveProfile();
    }
  }
  
  void _saveProfile() {
    if (buyer.value == null) return;
    
    isLoading.value = true;
    
    // Simulate saving profile
    Future.delayed(const Duration(milliseconds: 1000), () {
      buyer.value = buyer.value!.copyWith(
        fullName: nameController.text,
        phoneNumber: phoneController.text,
        address: addressController.text,
        updatedAt: DateTime.now(),
      );
      
      isLoading.value = false;
      
      Get.snackbar(
        'Profile Updated',
        'Your profile has been updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.buyerPrimary.withOpacity(0.9),
        colorText: Colors.white,
      );
    });
  }
  
  void selectProfileImage() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Profile Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                _pickImageFromGallery();
              },
            ),
            if (profileImagePath.value.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Photo'),
                onTap: () {
                  Get.back();
                  _removeProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }
  
  void _pickImageFromCamera() {
    // Simulate camera image selection
    profileImagePath.value = 'camera_image_path';
    Get.snackbar(
      'Photo Captured',
      'Profile photo updated from camera',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void _pickImageFromGallery() {
    // Simulate gallery image selection
    profileImagePath.value = 'gallery_image_path';
    Get.snackbar(
      'Photo Selected',
      'Profile photo updated from gallery',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void _removeProfileImage() {
    profileImagePath.value = '';
    Get.snackbar(
      'Photo Removed',
      'Profile photo removed successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void viewFavorites() {
    Get.toNamed('/buyer-favorites');
  }
  
  void viewReviews() {
    Get.toNamed('/buyer-reviews');
  }
  
  void viewOrderHistory() {
    Get.toNamed('/buyer-orders');
  }
  
  void updateNotificationSettings(bool enabled) {
    notificationsEnabled.value = enabled;
    // Save to local storage or API
  }
  
  void updateLocationSettings(bool enabled) {
    locationEnabled.value = enabled;
    // Save to local storage or API
  }
  
  void changeLanguage() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('Arabic'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: preferredLanguage.value == language
          ? const Icon(Icons.check, color: AppTheme.buyerPrimary)
          : null,
      onTap: () {
        preferredLanguage.value = language;
        Get.back();
        Get.snackbar(
          'Language Changed',
          'Language changed to $language',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }
  
  void changeTheme() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('System'),
            _buildThemeOption('Light'),
            _buildThemeOption('Dark'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(String themeOption) {
    return ListTile(
      title: Text(themeOption),
      trailing: theme.value == themeOption
          ? const Icon(Icons.check, color: AppTheme.buyerPrimary)
          : null,
      onTap: () {
        theme.value = themeOption;
        Get.back();
        Get.snackbar(
          'Theme Changed',
          'Theme changed to $themeOption',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }
  
  void showPrivacyPolicy() {
    Get.dialog(
      AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content here...\n\n'
            'This app collects and processes personal information to provide marketplace services. '
            'We are committed to protecting your privacy and ensuring your data is secure.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void showTermsOfService() {
    Get.dialog(
      AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service content here...\n\n'
            'By using this app, you agree to our terms and conditions. '
            'Please read carefully before using our services.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void contactSupport() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@souqistefada.com'),
              onTap: () {
                Get.back();
                // Launch email
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone Support'),
              subtitle: const Text('+971 4 123 4567'),
              onTap: () {
                Get.back();
                // Launch phone dialer
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp Support'),
              subtitle: const Text('+971 50 123 4567'),
              onTap: () {
                Get.back();
                // Launch WhatsApp
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  void _performLogout() {
    // Clear user data
    buyer.value = null;
    
    // Navigate to welcome screen
    Get.offAllNamed('/welcome');
    
    Get.snackbar(
      'Logged Out',
      'You have been logged out successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

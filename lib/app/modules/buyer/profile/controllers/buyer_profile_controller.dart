import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/favorites_service.dart';
import '../../../../services/viewed_history_service.dart';
import '../../../../services/user_settings_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../core/theme/app_theme.dart';

class BuyerProfileController extends GetxController {
  // Services
  final AuthService _authService = Get.find<AuthService>();
  final FavoritesService _favoritesService = Get.find<FavoritesService>();
  final ViewedHistoryService _viewedHistoryService = Get.find<ViewedHistoryService>();
  final UserSettingsService _userSettingsService = Get.find<UserSettingsService>();
  
  // User profile data
  final Rx<UsersProfile?> userProfile = Rx<UsersProfile?>(null);
  final Rx<UserSettings?> userSettings = Rx<UserSettings?>(null);
  final Rx<FavoritesCount?> favoritesCount = Rx<FavoritesCount?>(null);
  final Rx<ViewedHistoryStats?> viewedStats = Rx<ViewedHistoryStats?>(null);
  
  // Profile sections
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Settings from user preferences
  final RxBool notificationsEnabled = true.obs;
  final RxBool emailNotificationsEnabled = true.obs;
  final RxBool smsNotificationsEnabled = false.obs;
  final RxBool locationEnabled = true.obs;
  final RxString preferredLanguage = 'English'.obs;
  final RxString theme = 'System'.obs;
  
  // Profile image
  final RxString profileImagePath = ''.obs;
  
  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();
  final usernameController = TextEditingController();
  
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
    whatsappController.dispose();
    usernameController.dispose();
    addressController.dispose();
    super.onClose();
  }
  
  Future<void> _loadProfileData() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Load user profile from AuthService
      userProfile.value = _authService.currentUser;
      
      if (userProfile.value != null) {
        // Update form controllers
        _updateFormControllers();
        
        // Load additional data
        await _loadUserSettings();
        await _loadFavoritesCount();
        await _loadViewedHistory();
      } else {
        errorMessage.value = 'No user logged in';
      }
    } catch (e) {
      errorMessage.value = 'Failed to load profile: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void _updateFormControllers() {
    if (userProfile.value != null) {
      nameController.text = userProfile.value!.fullname ?? '';
      emailController.text = userProfile.value!.emailid ;
      phoneController.text = userProfile.value!.mobileno ?? '';
      whatsappController.text = userProfile.value!.whatsappno ?? '';
      usernameController.text = userProfile.value!.username ;
    }
  }

  Future<void> _loadUserSettings() async {

      final response = await _userSettingsService.getUserSettings();
      if (response.isSuccess && response.data != null) {
        userSettings.value = response.data!;
        _updateSettingsFromData();
      } else {
        // Initialize default settings if none exist
        await _userSettingsService.initializeUserSettings();
      }
   
  }

  void _updateSettingsFromData() {
    if (userSettings.value != null) {
      final notifications = userSettings.value!.notifications;
      notificationsEnabled.value = notifications.pushNotifications;
      emailNotificationsEnabled.value = notifications.emailNotifications;
      smsNotificationsEnabled.value = notifications.smsNotifications;
    }
  }

  Future<void> _loadFavoritesCount() async {

      final response = await _favoritesService.getFavoritesCount();
      if (response.isSuccess && response.data != null) {
        favoritesCount.value = response.data!;
      }
  
  }

  Future<void> _loadViewedHistory() async {

      final response = await _viewedHistoryService.getViewedHistoryStats();
      if (response.isSuccess && response.data != null) {
        viewedStats.value = response.data!;
      }

  }
  
  void toggleEditMode() {
    if (isEditing.value) {
      // Save changes
      _saveProfile();
    }
    isEditing.value = !isEditing.value;
  }
  
  void _saveProfile() async {
    if (userProfile.value == null) return;
    
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Create updated user profile
      final updatedProfile = userProfile.value!.copyWith(
        fullname: nameController.text.trim(),
        mobileno: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        whatsappno: whatsappController.text.trim().isNotEmpty ? whatsappController.text.trim() : null,
        updateddt: DateTime.now(),
      );
      
      // Update profile via AuthService
      final response = await _authService.updateProfile(updatedProfile);
      
      if (response.isSuccess) {
        userProfile.value = updatedProfile;
        
        Get.snackbar(
          'Profile Updated',
          'Your profile has been updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.buyerPrimary.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      } else {
        errorMessage.value = response.errorMessage ?? 'Failed to update profile';
        Get.snackbar(
          'Update Failed',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to update profile: ${e.toString()}';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
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
    // TODO: Implement camera image selection with image_picker
    profileImagePath.value = 'camera_image_path';
    Get.snackbar(
      'Photo Captured',
      'Profile photo updated from camera',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void _pickImageFromGallery() {
    // TODO: Implement gallery image selection with image_picker
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
  
  void viewOrderHistory() {
    Get.toNamed('/buyer-orders');
  }

  void viewRecentlyViewed() {
    // Navigate to a recently viewed screen or show in dialog
    Get.toNamed('/buyer-recently-viewed');
  }
  
  void updateNotificationSettings(bool enabled) async {
    notificationsEnabled.value = enabled;
    await _saveNotificationSettings();
  }

  void updateEmailNotificationSettings(bool enabled) async {
    emailNotificationsEnabled.value = enabled;
    await _saveNotificationSettings();
  }

  void updateSmsNotificationSettings(bool enabled) async {
    smsNotificationsEnabled.value = enabled;
    await _saveNotificationSettings();
  }

  Future<void> _saveNotificationSettings() async {

      if (userSettings.value != null) {
        final updatedNotifications = userSettings.value!.notifications.copyWith(
          pushNotifications: notificationsEnabled.value,
          emailNotifications: emailNotificationsEnabled.value,
          smsNotifications: smsNotificationsEnabled.value,
        );

        final updatedSettings = userSettings.value!.copyWith(
          notifications: updatedNotifications,
        );

        final response = await _userSettingsService.saveUserSettings(updatedSettings);
        if (response.isSuccess) {
          userSettings.value = updatedSettings;
        }
      }
   
  }
  
  void updateLocationSettings(bool enabled) {
    locationEnabled.value = enabled;
    // TODO: Save location settings
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
        // TODO: Implement actual language change
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
        // TODO: Implement actual theme change
      },
    );
  }

  void manageInterestCategories() {
    // Navigate to interest categories management screen
    Get.toNamed('/buyer-interest-categories');
  }

  void clearViewedHistory() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Viewing History'),
        content: const Text('Are you sure you want to clear your entire viewing history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              try {
                final response = await _viewedHistoryService.clearViewedHistory();
                if (response.isSuccess) {
                  viewedStats.value = ViewedHistoryStats(
                    totalViewedSellers: 0,
                    totalViewedProducts: 0,
                    totalViews: 0,
                  );
                  
                  Get.snackbar(
                    'History Cleared',
                    'Your viewing history has been cleared',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppTheme.buyerPrimary.withValues(alpha: 0.9),
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Failed to clear history',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withValues(alpha: 0.9),
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to clear history: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.9),
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear History'),
          ),
        ],
      ),
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
                // TODO: Launch email
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone Support'),
              subtitle: const Text('+91 98765 43210'),
              onTap: () {
                Get.back();
                // TODO: Launch phone dialer
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp Support'),
              subtitle: const Text('+91 98765 43210'),
              onTap: () {
                Get.back();
                // TODO: Launch WhatsApp
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
  
  void _performLogout() async {
    // Use AuthService logout which properly clears all data including role
    await _authService.logout();
    
    Get.snackbar(
      'Logged Out',
      'You have been logged out successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> refreshProfile() async {
    await _loadProfileData();
  }

  // Helper getters for UI
  String get displayName => userProfile.value?.fullname ?? userProfile.value?.username ?? 'User';
  String get displayEmail => userProfile.value?.emailid ?? '';
  String get displayPhone => userProfile.value?.mobileno ?? '';
  String get memberSince => userProfile.value?.createddt != null 
      ? 'Member since ${userProfile.value!.createddt!.year}' 
      : '';
  
  int get favoriteSellerCount => favoritesCount.value?.sellersCount ?? 0;
  int get favoriteProductCount => favoritesCount.value?.productsCount ?? 0;
  int get totalFavoritesCount => favoritesCount.value?.totalCount ?? 0;
  
  int get totalViewsCount => viewedStats.value?.totalViews ?? 0;
  int get viewedSellersCount => viewedStats.value?.totalViewedSellers ?? 0;
  int get viewedProductsCount => viewedStats.value?.totalViewedProducts ?? 0;

  // Legacy compatibility getters for old UI
  Rx<UsersProfile?> get buyer => userProfile; // For backward compatibility
  int get favoriteCount => totalFavoritesCount;
  int get reviewsCount => 0; // TODO: Implement reviews functionality
  int get orderHistory => 0; // TODO: Implement order history

  // Missing controller for address (not used in new implementation but referenced in old view)
  final addressController = TextEditingController();

  // Missing method for old UI compatibility
  void viewReviews() {
    // TODO: Navigate to reviews screen when implemented
    Get.snackbar(
      'Coming Soon',
      'Reviews feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

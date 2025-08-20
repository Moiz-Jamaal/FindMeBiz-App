import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../core/theme/app_theme.dart';

class SellerSettingsController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  
  // Current seller settings
  final Rx<SellerSettings?> currentSettings = Rx<SellerSettings?>(null);
  final RxInt sellerId = 0.obs;
  
  // Business Settings
  final RxBool isBusinessOpen = true.obs;
  final RxString businessStatus = 'Open'.obs;
  final RxBool acceptingOrders = true.obs;
  
  // Notification Settings
  final RxBool notificationsEnabled = true.obs;
  final RxBool emailNotifications = true.obs;
  final RxBool smsNotifications = false.obs;
  final RxBool pushNotifications = true.obs;
  final RxBool whatsappNotifications = true.obs;
  
  // Privacy Settings
  final RxBool showPhoneNumber = true.obs;
  final RxBool showWhatsApp = true.obs;
  final RxBool showEmail = false.obs;
  final RxBool allowMessaging = true.obs;
  
  // Business Hours
  final RxMap<String, Map<String, dynamic>> businessHours = <String, Map<String, dynamic>>{}.obs;
  
  // Account Settings
  final RxBool accountVerified = false.obs;
  final RxString subscriptionPlan = 'Free'.obs;
  final RxMap<String, dynamic> subscriptionDetails = <String, dynamic>{}.obs;
  
  // UI State
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeBusinessHours();
    _loadSettings();
  }

  void _initializeBusinessHours() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    for (String day in days) {
      businessHours[day] = {
        'isOpen': day != 'Sunday', // Closed on Sunday by default
        'openTime': '09:00',
        'closeTime': '18:00',
      };
    }
  }

  Future<void> _loadSettings() async {
    try {
      isLoading.value = true;
      
      // Get current user and seller profile
      final currentUser = _authService.currentUser;
      if (currentUser?.userid == null) {
        Get.snackbar('Error', 'No user found. Please login again.');
        return;
      }

      // Get seller profile first to get seller ID
      final sellerResponse = await _sellerService.getSellerByUserId(currentUser!.userid!);
      if (!sellerResponse.success || sellerResponse.data?.sellerid == null) {
        Get.snackbar('Error', 'No seller profile found. Please complete onboarding first.');
        return;
      }

      sellerId.value = sellerResponse.data!.sellerid!;

      // Load seller settings
      final settingsResponse = await _sellerService.getSellerSettings(sellerId.value);
      
      if (settingsResponse.success && settingsResponse.data != null) {
        currentSettings.value = settingsResponse.data;
        _populateSettingsFromData(settingsResponse.data!);
      } else {
        // No settings found, create default settings
        await _createDefaultSettings();
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load settings');
      
    } finally {
      isLoading.value = false;
    }
  }

  void _populateSettingsFromData(SellerSettings settings) {
    // Basic settings
    isBusinessOpen.value = settings.isopen ?? true;
    businessStatus.value = isBusinessOpen.value ? 'Open' : 'Closed';
    subscriptionPlan.value = settings.subscriptionPlan ?? 'Free';
    
    // Parse notification settings from JSON strings
    if (settings.notificationModes != null) {
      try {
        final modes = jsonDecode(settings.notificationModes!);
        notificationsEnabled.value = modes['enabled'] ?? true;
      } catch (e) {
        notificationsEnabled.value = true;
      }
    }
    
    if (settings.pushNotifications != null) {
      try {
        final push = jsonDecode(settings.pushNotifications!);
        pushNotifications.value = push['enabled'] ?? true;
      } catch (e) {
        pushNotifications.value = true;
      }
    }
    
    if (settings.emailNotifications != null) {
      try {
        final email = jsonDecode(settings.emailNotifications!);
        emailNotifications.value = email['enabled'] ?? true;
      } catch (e) {
        emailNotifications.value = true;
      }
    }
    
    if (settings.smsNotifications != null) {
      try {
        final sms = jsonDecode(settings.smsNotifications!);
        smsNotifications.value = sms['enabled'] ?? false;
      } catch (e) {
        smsNotifications.value = false;
      }
    }
    
    if (settings.whatsappNotifications != null) {
      try {
        final whatsapp = jsonDecode(settings.whatsappNotifications!);
        whatsappNotifications.value = whatsapp['enabled'] ?? true;
      } catch (e) {
        whatsappNotifications.value = true;
      }
    }
    
    // Parse business hours
    if (settings.businessHours != null) {
      try {
        final hours = jsonDecode(settings.businessHours!);
        if (hours is Map<String, dynamic>) {
          for (var entry in hours.entries) {
            businessHours[entry.key] = Map<String, dynamic>.from(entry.value);
          }
        }
      } catch (e) {
        // Keep default business hours
      }
    }
    
    // Parse privacy settings
    if (settings.privacySettings != null) {
      try {
        final privacy = jsonDecode(settings.privacySettings!);
        showPhoneNumber.value = privacy['showPhoneNumber'] ?? true;
        showWhatsApp.value = privacy['showWhatsApp'] ?? true;
        showEmail.value = privacy['showEmail'] ?? false;
        allowMessaging.value = privacy['allowMessaging'] ?? true;
      } catch (e) {
        // Keep default privacy settings
      }
    }
    
    // Parse subscription details
    if (settings.subscriptionDetails != null) {
      try {
        subscriptionDetails.value = jsonDecode(settings.subscriptionDetails!);
      } catch (e) {
        subscriptionDetails.value = {};
      }
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      final defaultSettings = SellerSettings(
        sellerid: sellerId.value,
        isopen: true,
        notificationModes: jsonEncode({'enabled': true}),
        pushNotifications: jsonEncode({'enabled': true}),
        emailNotifications: jsonEncode({'enabled': true}),
        smsNotifications: jsonEncode({'enabled': false}),
        whatsappNotifications: jsonEncode({'enabled': true}),
        businessHours: jsonEncode(businessHours),
        privacySettings: jsonEncode({
          'showPhoneNumber': true,
          'showWhatsApp': true,
          'showEmail': false,
          'allowMessaging': true,
        }),
        subscriptionPlan: 'basic',
      );
      
      final response = await _sellerService.createSellerSettings(defaultSettings);
      if (response.success) {
        currentSettings.value = defaultSettings;
      }
    } catch (e) {
      
    }
  }

  void toggleBusinessStatus() {
    isBusinessOpen.value = !isBusinessOpen.value;
    businessStatus.value = isBusinessOpen.value ? 'Open' : 'Closed';
    
    Get.snackbar(
      'Business Status Updated',
      'Your business is now ${businessStatus.value.toLowerCase()}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
    );
  }

  void toggleAcceptingOrders(bool value) {
    acceptingOrders.value = value;
    
    Get.snackbar(
      'Order Settings Updated',
      value ? 'Now accepting new orders' : 'Not accepting new orders',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
    );
  }

  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    
    if (!value) {
      emailNotifications.value = false;
      smsNotifications.value = false;
      pushNotifications.value = false;
      whatsappNotifications.value = false;
    }
  }

  void updateBusinessHours(String day, String type, String value) {
    if (businessHours.containsKey(day)) {
      businessHours[day]![type] = value;
      businessHours.refresh();
    }
  }

  void toggleDayOpen(String day, bool isOpen) {
    if (businessHours.containsKey(day)) {
      businessHours[day]!['isOpen'] = isOpen;
      businessHours.refresh();
    }
  }

  Future<void> saveAllSettings() async {
    try {
      isSaving.value = true;
      
      if (sellerId.value == 0) {
        Get.snackbar('Error', 'Seller ID not found');
        return;
      }

      // Prepare settings data
      final updatedSettings = SellerSettings(
        sellerid: sellerId.value,
        isopen: isBusinessOpen.value,
        notificationModes: jsonEncode({'enabled': notificationsEnabled.value}),
        pushNotifications: jsonEncode({'enabled': pushNotifications.value}),
        emailNotifications: jsonEncode({'enabled': emailNotifications.value}),
        smsNotifications: jsonEncode({'enabled': smsNotifications.value}),
        whatsappNotifications: jsonEncode({'enabled': whatsappNotifications.value}),
        businessHours: jsonEncode(businessHours),
        privacySettings: jsonEncode({
          'showPhoneNumber': showPhoneNumber.value,
          'showWhatsApp': showWhatsApp.value,
          'showEmail': showEmail.value,
          'allowMessaging': allowMessaging.value,
        }),
        otherSettings: jsonEncode({
          'acceptingOrders': acceptingOrders.value,
        }),
        subscriptionPlan: subscriptionPlan.value,
        subscriptionDetails: jsonEncode(subscriptionDetails),
      );

      // Save to backend
      final response = await _sellerService.updateSellerSettings(updatedSettings);
      
      if (response.success) {
        currentSettings.value = updatedSettings;
        Get.snackbar(
          'Settings Saved',
          'All settings have been saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error', response.message ?? 'Failed to save settings');
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to save settings');
      
    } finally {
      isSaving.value = false;
    }
  }

  void exportData() {
    Get.snackbar(
      'Export Started',
      'Your data export has been initiated. You\'ll receive a download link via email.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
    );
  }

  void deleteAccount() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Account Deletion',
                'Account deletion request submitted. You\'ll receive a confirmation email.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            onPressed: () async {
              Get.back();
              // Use AuthService logout which properly clears all data including role
              await _authService.logout();
              
              Get.snackbar(
                'Logged Out',
                'You have been logged out successfully',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void refreshSettings() {
    _loadSettings();
  }

  void showBusinessHoursDialog() {
    Get.dialog(
      Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Business Hours',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: businessHours.keys.length,
                  itemBuilder: (context, index) {
                    final day = businessHours.keys.elementAt(index);
                    final hours = businessHours[day]!;
                    
                    return Obx(() => ListTile(
                      title: Text(day),
                      subtitle: hours['isOpen']
                          ? Text('${hours['openTime']} - ${hours['closeTime']}')
                          : const Text('Closed'),
                      trailing: Switch(
                        value: hours['isOpen'],
                        onChanged: (value) => toggleDayOpen(day, value),
                      ),
                    ));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        saveAllSettings();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

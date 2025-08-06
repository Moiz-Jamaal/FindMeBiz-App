import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SellerSettingsController extends GetxController {
  // Business Settings
  final RxBool isBusinessOpen = true.obs;
  final RxString businessStatus = 'Open'.obs;
  final RxBool acceptingOrders = true.obs;
  
  // Notification Settings
  final RxBool notificationsEnabled = true.obs;
  final RxBool emailNotifications = true.obs;
  final RxBool smsNotifications = false.obs;
  final RxBool pushNotifications = true.obs;
  
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

  void _loadSettings() {
    // In real app, load from shared preferences or API
    // Mock some settings
    businessStatus.value = isBusinessOpen.value ? 'Open' : 'Closed';
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

  void saveAllSettings() {
    // In real app, save to backend/shared preferences
    Get.snackbar(
      'Settings Saved',
      'All settings have been saved successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
    );
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
            onPressed: () {
              Get.back();
              // In real app, clear session and navigate to login
              Get.offAllNamed('/welcome');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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

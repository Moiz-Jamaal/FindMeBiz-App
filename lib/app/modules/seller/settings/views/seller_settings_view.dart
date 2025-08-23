import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/seller_settings_controller.dart';

class SellerSettingsView extends GetView<SellerSettingsController> {
  const SellerSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: controller.saveAllSettings,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusinessStatusCard(),
            const SizedBox(height: 16),
            _buildBusinessSettingsCard(),
            const SizedBox(height: 16),
            _buildNotificationSettingsCard(),
            const SizedBox(height: 16),
            _buildPrivacySettingsCard(),
            const SizedBox(height: 16),
            _buildAccountSettingsCard(),
            const SizedBox(height: 32),
            _buildDangerZone(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Business Status',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller.isBusinessOpen.value 
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: controller.isBusinessOpen.value
                      ? AppTheme.successColor
                      : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.isBusinessOpen.value
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: controller.isBusinessOpen.value
                        ? AppTheme.successColor
                        : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your business is ${controller.businessStatus.value}',
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.isBusinessOpen.value
                            ? 'Customers can view and contact you'
                            : 'Your profile is hidden from customers',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Switch(
                    value: controller.isBusinessOpen.value,
                    onChanged: (_) => controller.toggleBusinessStatus(),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Obx(() => SwitchListTile(
              title: const Text('Accepting Orders'),
              subtitle: Text(
                controller.acceptingOrders.value
                    ? 'You will receive new orders'
                    : 'No new orders will be received',
              ),
              value: controller.acceptingOrders.value,
              onChanged: controller.toggleAcceptingOrders,
              secondary: Icon(
                controller.acceptingOrders.value
                    ? Icons.shopping_cart
                    : Icons.shopping_cart_outlined,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Business Settings',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Business Hours'),
              subtitle: const Text('Set your operating hours'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.showBusinessHoursDialog,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Stall Location'),
              subtitle: const Text('Update your business location'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/seller/stall-location'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Business Profile'),
              subtitle: const Text('Edit business information'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/seller/profile-edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Settings',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive notifications for orders and messages'),
              value: controller.notificationsEnabled.value,
              onChanged: controller.toggleNotifications,
              secondary: const Icon(Icons.notifications_active),
            )),
            if (controller.notificationsEnabled.value) ...[
              const Divider(),
              Obx(() => SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Instant notifications on your device'),
                value: controller.pushNotifications.value,
                onChanged: (value) => controller.pushNotifications.value = value,
                secondary: const Icon(Icons.phone_android),
              )),
              Obx(() => SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive notifications via email'),
                value: controller.emailNotifications.value,
                onChanged: (value) => controller.emailNotifications.value = value,
                secondary: const Icon(Icons.email),
              )),
              Obx(() => SwitchListTile(
                title: const Text('SMS Notifications'),
                subtitle: const Text('Receive notifications via SMS'),
                value: controller.smsNotifications.value,
                onChanged: (value) => controller.smsNotifications.value = value,
                secondary: const Icon(Icons.sms),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy Settings',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => SwitchListTile(
              title: const Text('Show Phone Number'),
              subtitle: const Text('Display your phone number on your profile'),
              value: controller.showPhoneNumber.value,
              onChanged: (value) => controller.showPhoneNumber.value = value,
              secondary: const Icon(Icons.phone),
            )),
            Obx(() => SwitchListTile(
              title: const Text('Show WhatsApp Contact'),
              subtitle: const Text('Allow customers to contact via WhatsApp'),
              value: controller.showWhatsApp.value,
              onChanged: (value) => controller.showWhatsApp.value = value,
              secondary: const Icon(Icons.chat),
            )),
            Obx(() => SwitchListTile(
              title: const Text('Show Email Address'),
              subtitle: const Text('Display your email address on your profile'),
              value: controller.showEmail.value,
              onChanged: (value) => controller.showEmail.value = value,
              secondary: const Icon(Icons.email),
            )),
            Obx(() => SwitchListTile(
              title: const Text('Allow Direct Messaging'),
              subtitle: const Text('Allow customers to send direct messages'),
              value: controller.allowMessaging.value,
              onChanged: (value) => controller.allowMessaging.value = value,
              secondary: const Icon(Icons.message),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Settings',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Obx(() => Icon(
                controller.accountVerified.value
                    ? Icons.verified
                    : Icons.verified_outlined,
                color: controller.accountVerified.value
                    ? AppTheme.successColor
                    : Colors.grey,
              )),
              title: const Text('Account Verification'),
              subtitle: Obx(() => Text(
                controller.accountVerified.value
                    ? 'Your account is verified'
                    : 'Verify your account for better visibility',
              )),
              trailing: controller.accountVerified.value
                  ? null
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.accountVerified.value
                  ? null
                  : () {
                      Get.snackbar(
                        'Verification',
                        'Account verification process will be available soon',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('Subscription Plan'),
              subtitle: Obx(() => Text('Current plan: ${controller.subscriptionPlan.value}')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Get.snackbar(
                  'Subscription',
                  'Subscription management will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download all your business data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.exportData,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help with your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Get.snackbar(
                  'Support',
                  'Help & Support will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.logout,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account and all data'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: controller.deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}

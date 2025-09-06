import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';

class AppInfoSettingsView extends StatelessWidget {
  const AppInfoSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final auth = Get.find<AuthService>();
  final isSeller = auth.isSeller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Information & Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Us - With phone and email
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.phone, color: Colors.blueGrey),
              title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Phone: +91 99786 55352'),
                  SizedBox(height: 4),
                  Text('Email: admin@findmebiz.com'),
                ],
              ),
              onTap: () {},
            ),
          ),

          // Terms and Conditions
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.blueGrey),
              title: const Text('Terms and Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('By using Souq, you agree to our terms of service. All transactions are subject to our platform rules and local regulations. Please review our full terms for details.'),
            ),
          ),

          // Privacy Policy
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blueGrey),
              title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Your privacy is important to us. We protect your data and do not share personal information without consent. See our privacy policy for more.'),
            ),
          ),

          // Logout Option
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: const Text('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
              onTap: _showLogoutDialog,
            ),
          ),

          // Delete Account Option (with optional delete seller)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              subtitle: Text(isSeller
                  ? 'Permanently delete your user account${isSeller ? ' and seller profile (optional)' : ''}'
                  : 'Permanently delete your user account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
              onTap: () => _showDeleteAccountDialog(isSeller: isSeller),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
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
    final authService = Get.find<AuthService>();
    await authService.logout();

    Get.snackbar(
      'Logged Out',
      'You have been logged out successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showDeleteAccountDialog({required bool isSeller}) {
    bool deleteSellerToo = isSeller; // default to true if user is a seller
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This action is permanent and cannot be undone.'),
              const SizedBox(height: 12),
              if (isSeller)
                Row(
                  children: [
                    Checkbox(
                      value: deleteSellerToo,
                      onChanged: (v) => setState(() => deleteSellerToo = v ?? false),
                    ),
                    const Expanded(
                      child: Text('Also delete my seller account and data'),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Get.back();
                await _performDeleteAccount(deleteSellerToo: deleteSellerToo);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDeleteAccount({required bool deleteSellerToo}) async {
    final auth = Get.find<AuthService>();
    try {
      // Optionally delete seller account first (to avoid orphaned data restrictions)
      if (deleteSellerToo && auth.currentSeller?.sellerid != null) {
        final sellerId = auth.currentSeller!.sellerid!;
        final sellerService = Get.isRegistered<SellerService>() ? Get.find<SellerService>() : Get.put(SellerService());
        final res = await sellerService.deleteSeller(sellerId);
        if (!res.success) {
          Get.snackbar('Delete seller failed', res.message ?? 'Unable to delete seller account', snackPosition: SnackPosition.BOTTOM);
          // Continue with user deletion anyway
        }
      }

      final resp = await auth.deleteAccount();
      if (resp.success) {
        Get.snackbar('Account deleted', 'Your account has been deleted', snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Delete failed', resp.message ?? 'Unable to delete account', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
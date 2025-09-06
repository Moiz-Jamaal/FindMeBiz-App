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

          // Delete Account/Seller Option - Updated logic
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: Text(
                isSeller ? 'Delete Seller' : 'Delete User Account',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)
              ),
              subtitle: Text(
                isSeller 
                  ? 'Permanently delete your seller profile and data'
                  : 'Permanently delete your user account'
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
              onTap: () => _showDeleteDialog(isSeller: isSeller),
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

  void _showDeleteDialog({required bool isSeller}) {
    bool deleteUserToo = false; // For sellers, option to also delete user account
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isSeller ? 'Delete Seller' : 'Delete User Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSeller 
                  ? 'This will permanently delete your seller profile and all associated data (products, reviews, etc.).'
                  : 'This action is permanent and cannot be undone.'
              ),
              const SizedBox(height: 12),
              if (isSeller)
                Row(
                  children: [
                    Checkbox(
                      value: deleteUserToo,
                      onChanged: (v) => setState(() => deleteUserToo = v ?? false),
                    ),
                    const Expanded(
                      child: Text('Also delete my user account'),
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
                await _performDelete(isSeller: isSeller, deleteUserToo: deleteUserToo);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDelete({required bool isSeller, required bool deleteUserToo}) async {
    final auth = Get.find<AuthService>();
    
    try {
      if (isSeller) {
        // Delete seller first
        if (auth.currentSeller?.sellerid != null) {
          final sellerId = auth.currentSeller!.sellerid!;
          final sellerService = Get.isRegistered<SellerService>() ? Get.find<SellerService>() : Get.put(SellerService());
          final res = await sellerService.deleteSeller(sellerId);
          if (!res.success) {
            Get.snackbar('Delete seller failed', res.message ?? 'Unable to delete seller account', snackPosition: SnackPosition.BOTTOM);
            if (!deleteUserToo) return; // If only deleting seller and it failed, stop here
          }
        }
        
        // If also deleting user account
        if (deleteUserToo) {
          final resp = await auth.deleteAccount();
          if (resp.success) {
            Get.snackbar('Accounts deleted', 'Your seller and user accounts have been deleted', snackPosition: SnackPosition.BOTTOM);
          } else {
            Get.snackbar('User delete failed', resp.message ?? 'Seller deleted but unable to delete user account', snackPosition: SnackPosition.BOTTOM);
          }
        } else {
          Get.snackbar('Seller deleted', 'Your seller account has been deleted', snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        // Delete user account only (for non-sellers)
        final resp = await auth.deleteAccount();
        if (resp.success) {
          Get.snackbar('Account deleted', 'Your account has been deleted', snackPosition: SnackPosition.BOTTOM);
        } else {
          Get.snackbar('Delete failed', resp.message ?? 'Unable to delete account', snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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
              onTap: () => _openUrl('https://merchant.razorpay.com/policy/RAbtoU7UlbasYr/contact_us'),
            ),
          ),

          // Terms and Conditions
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.blueGrey),
              title: const Text('Terms and Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'By using FindMeBiz, you agree to our Terms of Service and platform policies. '
                    'For complete details on our terms, privacy, refunds, and shipping, please refer to the documents below (hosted with our payment partner Razorpay).',
                  ),
                  const SizedBox(height: 8),
                  _PolicyLink(label: 'Terms of Service', url: 'https://merchant.razorpay.com/policy/RAbtoU7UlbasYr/terms'),
                  _PolicyLink(label: 'Privacy Policy', url: 'https://merchant.razorpay.com/policy/RAbtoU7UlbasYr/privacy'),
                  _PolicyLink(label: 'Refund Policy', url: 'https://merchant.razorpay.com/policy/RAbtoU7UlbasYr/refund'),
                  _PolicyLink(label: 'Shipping Policy', url: 'https://merchant.razorpay.com/policy/RAbtoU7UlbasYr/shipping'),
                  _PolicyLink(label: 'Contact Us', url: 'https://merchant.razorpay.com/policy/RAbtoU7UlbasYr/contact_us'),
                ],
              ),
            ),
          ),

          // Privacy Policy
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blueGrey),
              title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Your privacy is important to us. Read our full privacy policy for details on data collection, use, and retention.'),
              trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.blueGrey),
              onTap: () => _openUrl('https://merchant.razorpay.com/policy/RAbtoU7UlbasYr/privacy'),
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
      bool shouldLogout = false;
      
      if (isSeller) {
        // Delete seller first
        if (auth.currentSeller?.sellerid != null) {
          final sellerId = auth.currentSeller!.sellerid!;
          final sellerService = Get.isRegistered<SellerService>() ? Get.find<SellerService>() : Get.put(SellerService());
          final res = await sellerService.deleteSeller(sellerId);
          if (!res.success) {
            Get.snackbar('Delete seller failed', res.message ?? 'Unable to delete seller account', snackPosition: SnackPosition.BOTTOM);
            if (!deleteUserToo) return; // If only deleting seller and it failed, stop here
          } else {
            shouldLogout = !deleteUserToo; // Logout if only deleting seller
          }
        }
        
        // If also deleting user account
        if (deleteUserToo) {
          final resp = await auth.deleteAccount(); // This already handles logout internally
          if (resp.success) {
            Get.snackbar('Accounts deleted', 'Your seller and user accounts have been deleted', snackPosition: SnackPosition.BOTTOM);
          } else {
            Get.snackbar('User delete failed', resp.message ?? 'Seller deleted but unable to delete user account', snackPosition: SnackPosition.BOTTOM);
            shouldLogout = true; // Still logout since seller was deleted
          }
        } else {
          Get.snackbar('Seller deleted', 'Your seller account has been deleted', snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        // Delete user account only (for non-sellers) - this already handles logout internally
        final resp = await auth.deleteAccount();
        if (resp.success) {
          Get.snackbar('Account deleted', 'Your account has been deleted', snackPosition: SnackPosition.BOTTOM);
        } else {
          Get.snackbar('Delete failed', resp.message ?? 'Unable to delete account', snackPosition: SnackPosition.BOTTOM);
        }
      }
      
      // Logout if needed (seller deletion without user deletion)
      if (shouldLogout) {
        await auth.logout();
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        Get.snackbar('Could not open link', url, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _PolicyLink extends StatelessWidget {
  final String label;
  final String url;

  const _PolicyLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
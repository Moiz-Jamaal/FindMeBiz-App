import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/auth_service.dart';

class AppInfoSettingsView extends StatelessWidget {
  const AppInfoSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
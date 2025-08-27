import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String status,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text(status, style: const TextStyle(color: Colors.orange)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

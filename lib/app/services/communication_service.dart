import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import '../core/constants/app_constants.dart';

class CommunicationService extends GetxService {
  static CommunicationService get to => Get.find();

  /// Launch WhatsApp chat with seller
  Future<bool> launchWhatsAppChat({
    required String phoneNumber,
    String? businessName,
    String? buyerName,
    String? customMessage,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create message
      final message = customMessage ?? _generateDefaultMessage(
        businessName: businessName,
        buyerName: buyerName,
      );
      
      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';
      
      // Try to launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        // Show success feedback
        Get.snackbar(
          'WhatsApp',
          'Opening WhatsApp chat with ${businessName ?? 'seller'}...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      } else {
        throw 'WhatsApp not installed';
      }
    } catch (e) {
      // Fallback to SMS if WhatsApp fails
      return await _fallbackToSMS(
        phoneNumber: phoneNumber,
        message: customMessage ?? _generateDefaultMessage(
          businessName: businessName,
          buyerName: buyerName,
        ),
        businessName: businessName,
      );
    }
  }

  /// Launch phone call to seller
  Future<bool> launchPhoneCall({
    required String phoneNumber,
    String? businessName,
  }) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final phoneUrl = 'tel:$cleanNumber';
      final uri = Uri.parse(phoneUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        Get.snackbar(
          'Calling',
          'Calling ${businessName ?? 'seller'}...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      } else {
        throw 'Phone app not available';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to make phone call: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Launch SMS to seller
  Future<bool> launchSMS({
    required String phoneNumber,
    String? message,
    String? businessName,
  }) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final encodedMessage = Uri.encodeComponent(
  message ?? 'Hi! I found your business on FindMeBiz app.',
      );
      
      final smsUrl = 'sms:$cleanNumber?body=$encodedMessage';
      final uri = Uri.parse(smsUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        Get.snackbar(
          'SMS',
          'Opening SMS to ${businessName ?? 'seller'}...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      } else {
        throw 'SMS not available';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to send SMS: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Launch email to seller
  Future<bool> launchEmail({
    required String email,
    String? subject,
    String? body,
    String? businessName,
  }) async {
    try {
      final emailSubject = Uri.encodeComponent(
  subject ?? 'Inquiry from FindMeBiz',
      );
      final emailBody = Uri.encodeComponent(
  body ?? 'Hi! I found your business on FindMeBiz app and would like to know more.',
      );
      
      final emailUrl = 'mailto:$email?subject=$emailSubject&body=$emailBody';
      final uri = Uri.parse(emailUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        Get.snackbar(
          'Email',
          'Opening email to ${businessName ?? 'seller'}...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      } else {
        throw 'Email app not available';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to open email: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Launch directions to seller location
  Future<bool> launchDirections({
    required double latitude,
    required double longitude,
    String? businessName,
    String? address,
  }) async {
    try {
      // Try Google Maps first
      final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
      final googleUri = Uri.parse(googleMapsUrl);
      
      if (await canLaunchUrl(googleUri)) {
        await launchUrl(
          googleUri,
          mode: LaunchMode.externalApplication,
        );
        
        Get.snackbar(
          'Directions',
          'Opening directions to ${businessName ?? 'seller location'}...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        
        return true;
      } else {
        // Fallback to Apple Maps on iOS or generic maps
        final appleMapUrl = 'http://maps.apple.com/?daddr=$latitude,$longitude';
        final appleUri = Uri.parse(appleMapUrl);
        
        if (await canLaunchUrl(appleUri)) {
          await launchUrl(appleUri, mode: LaunchMode.externalApplication);
          return true;
        } else {
          throw 'No maps app available';
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to open directions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Show contact options dialog
  void showContactOptionsDialog({
    required String businessName,
    String? phoneNumber,
    String? whatsappNumber,
    String? email,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Contact $businessName',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Contact options
            if (whatsappNumber != null)
              _buildContactOption(
                icon: Icons.chat,
                title: 'WhatsApp',
                subtitle: whatsappNumber,
                color: Colors.green,
                onTap: () {
                  Get.back();
                  launchWhatsAppChat(
                    phoneNumber: whatsappNumber,
                    businessName: businessName,
                  );
                },
              ),
            
            if (phoneNumber != null)
              _buildContactOption(
                icon: Icons.phone,
                title: 'Call',
                subtitle: phoneNumber,
                color: Colors.blue,
                onTap: () {
                  Get.back();
                  launchPhoneCall(
                    phoneNumber: phoneNumber,
                    businessName: businessName,
                  );
                },
              ),
            
            if (phoneNumber != null)
              _buildContactOption(
                icon: Icons.sms,
                title: 'SMS',
                subtitle: phoneNumber,
                color: Colors.orange,
                onTap: () {
                  Get.back();
                  launchSMS(
                    phoneNumber: phoneNumber,
                    businessName: businessName,
                  );
                },
              ),
            
            if (email != null)
              _buildContactOption(
                icon: Icons.email,
                title: 'Email',
                subtitle: email,
                color: Colors.red,
                onTap: () {
                  Get.back();
                  launchEmail(
                    email: email,
                    businessName: businessName,
                  );
                },
              ),
            
            if (latitude != null && longitude != null)
              _buildContactOption(
                icon: Icons.directions,
                title: 'Directions',
                subtitle: address ?? 'Get directions',
                color: Colors.purple,
                onTap: () {
                  Get.back();
                  launchDirections(
                    latitude: latitude,
                    longitude: longitude,
                    businessName: businessName,
                    address: address,
                  );
                },
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }

  // Fallback to SMS if WhatsApp fails
  Future<bool> _fallbackToSMS({
    required String phoneNumber,
    required String message,
    String? businessName,
  }) async {
    Get.snackbar(
      'WhatsApp Unavailable',
      'WhatsApp not found. Trying SMS instead...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    return await launchSMS(
      phoneNumber: phoneNumber,
      message: message,
      businessName: businessName,
    );
  }

  // Generate default WhatsApp message
  String _generateDefaultMessage({
    String? businessName,
    String? buyerName,
  }) {
    final business = businessName ?? 'your business';
    final buyer = buyerName ?? 'A potential customer';
    
  return '''Hi! $buyer found $business on the FindMeBiz app.

I'm interested in learning more about your products and services. Could you please share more details?

Thank you!

Sent via FindMeBiz app''';
  }
}
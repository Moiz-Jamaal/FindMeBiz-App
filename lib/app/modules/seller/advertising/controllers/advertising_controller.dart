import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/payment_service.dart';

class AdvertisingController extends GetxController {
  // Active campaign state
  final RxBool hasActiveAdCampaign = false.obs;
  final Rx<AdCampaign?> currentCampaign = Rx<AdCampaign?>(null);

  // Selection and processing
  final RxString selectedAdType = 'featured'.obs;
  final RxBool isProcessingPayment = false.obs;

  // Fixed-price options
  final List<AdType> adTypes = [
    AdType(
      id: 'featured',
      name: 'Featured Seller',
      description: 'Appear in featured sellers section',
      basePrice: 100.0,
      icon: Icons.star,
      color: Colors.orange,
    ),
    AdType(
      id: 'top3',
      name: 'Top 3 Placement',
      description: 'Be shown among top 3 spots',
      basePrice: 500.0,
      icon: Icons.emoji_events,
      color: Colors.purple,
    ),
  ];

  void updateAdType(String adTypeId) => selectedAdType.value = adTypeId;

  AdType get selectedAdTypeObject =>
      adTypes.firstWhere((t) => t.id == selectedAdType.value);

  // Purchase API
  void purchaseAd(String adTypeId) {
    if (hasActiveAdCampaign.value) {
      Get.snackbar(
        'Active Campaign',
        'You already have an active advertising campaign. Wait for it to complete or cancel it first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    selectedAdType.value = adTypeId;
    final type = selectedAdTypeObject;
  _showFixedPriceConfirmation(type, type.basePrice);
  }

  void _showFixedPriceConfirmation(AdType type, double price) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ad: ${type.name}'),
            const SizedBox(height: 8),
            Text('Price: ₹${price.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _processPaymentFixed(type, price);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sellerPrimary,
            ),
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPaymentFixed(AdType type, double price) async {
    isProcessingPayment.value = true;
    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Processing Payment...'),
              const SizedBox(height: 8),
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final payment = Get.find<PaymentService>();
      final result = await payment.payINR(
        amountInPaise: (price * 100).toInt(),
        description: type.name,
        receipt: 'adv_${DateTime.now().millisecondsSinceEpoch}',
        notes: {'ad_type': type.id},
      );
      Get.back();
      isProcessingPayment.value = false;
      if (result.success) {
        _activateFixedCampaign(type, price);
      } else {
        Get.snackbar(
          'Payment Failed',
          result.error ?? 'Unable to complete payment',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      isProcessingPayment.value = false;
      Get.snackbar(
        'Payment Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _activateFixedCampaign(AdType type, double price) {
    final newCampaign = AdCampaign(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      adType: type,
      bid: price,
      duration: 7,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      totalBudget: price,
      remainingBudget: price,
      isActive: true,
    );

    hasActiveAdCampaign.value = true;
    currentCampaign.value = newCampaign;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.sellerPrimary),
            const SizedBox(width: 8),
            const Text('Purchase Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${type.name} activated for 7 days'),
            Text('Amount Paid: ₹${price.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sellerPrimary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void cancelCampaign() {
    if (!hasActiveAdCampaign.value || currentCampaign.value == null) {
      return;
    }
    final refundAmount = currentCampaign.value!.remainingBudget;
    hasActiveAdCampaign.value = false;
    currentCampaign.value = null;
    Get.snackbar(
      'Campaign Cancelled',
      'Campaign cancelled successfully. Refund of ₹${refundAmount.toStringAsFixed(0)} will be processed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  String get campaignStatusText {
    if (!hasActiveAdCampaign.value) return 'No Active Campaign';
    final campaign = currentCampaign.value!;
    if (!campaign.isActive) return 'Campaign Paused';
    final remainingDays = campaign.endDate.difference(DateTime.now()).inDays;
    return 'Active - $remainingDays days remaining';
  }

  Color get campaignStatusColor {
    if (!hasActiveAdCampaign.value) return Colors.grey;
    final campaign = currentCampaign.value!;
    if (!campaign.isActive) return Colors.orange;
    return Colors.green;
  }
}

// Models
class AdType {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final IconData icon;
  final Color color;

  AdType({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.icon,
    required this.color,
  });
}

class AdCampaign {
  final String id;
  final AdType adType;
  final double bid;
  final int duration;
  final DateTime startDate;
  final DateTime endDate;
  final double totalBudget;
  double remainingBudget;
  bool isActive;

  AdCampaign({
    required this.id,
    required this.adType,
    required this.bid,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.totalBudget,
    required this.remainingBudget,
    required this.isActive,
  });
}
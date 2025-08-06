import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class AdvertisingController extends GetxController {
  // Current advertising campaign data
  final RxBool hasActiveAdCampaign = false.obs;
  final Rx<AdCampaign?> currentCampaign = Rx<AdCampaign?>(null);
  
  // Bidding state
  final RxDouble currentBid = 50.0.obs;
  final RxInt selectedDuration = 7.obs; // days
  final RxString selectedAdType = 'featured'.obs;
  final RxBool isProcessingPayment = false.obs;
  
  // Ad performance data
  final RxInt totalViews = 0.obs;
  final RxInt totalClicks = 0.obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxInt totalDays = 0.obs;
  
  // Ad type options
  final List<AdType> adTypes = [
    AdType(
      id: 'featured',
      name: 'Featured Listing',
      description: 'Appear in featured sellers section',
      basePrice: 50.0,
      icon: Icons.star,
      color: Colors.orange,
    ),
    AdType(
      id: 'top_search',
      name: 'Top Search Results',
      description: 'Appear at top of search results',
      basePrice: 75.0,
      icon: Icons.search,
      color: Colors.blue,
    ),
    AdType(
      id: 'map_priority',
      name: 'Map Priority',
      description: 'Highlighted pin on buyer map',
      basePrice: 40.0,
      icon: Icons.map,
      color: Colors.green,
    ),
    AdType(
      id: 'home_banner',
      name: 'Home Banner',
      description: 'Banner on buyer home screen',
      basePrice: 100.0,
      icon: Icons.campaign,
      color: Colors.purple,
    ),
  ];
  
  // Duration options
  final List<int> durationOptions = [1, 3, 7, 14, 30];
  
  @override
  void onInit() {
    super.onInit();
    _loadAdvertisingData();
  }

  void _loadAdvertisingData() {
    // Simulate loading existing campaign data
    Future.delayed(const Duration(seconds: 1), () {
      // Check if seller has active campaigns
      _checkActiveCampaigns();
      _loadPerformanceData();
    });
  }

  void _checkActiveCampaigns() {
    // Simulate checking for active campaigns
    // In real app, this would check with backend
    
    // For demo, randomly assign an active campaign
    if (DateTime.now().millisecondsSinceEpoch % 3 == 0) {
      hasActiveAdCampaign.value = true;
      currentCampaign.value = AdCampaign(
        id: 'camp_001',
        adType: adTypes.first,
        bid: 75.0,
        duration: 7,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        totalBudget: 525.0, // 75 * 7
        remainingBudget: 375.0, // 75 * 5
        isActive: true,
      );
    }
  }

  void _loadPerformanceData() {
    // Simulate performance data
    totalViews.value = 1240;
    totalClicks.value = 89;
    totalSpent.value = 150.0;
    totalDays.value = 12;
  }

  void updateBid(double bid) {
    currentBid.value = bid;
  }

  void updateDuration(int days) {
    selectedDuration.value = days;
  }

  void updateAdType(String adTypeId) {
    selectedAdType.value = adTypeId;
  }

  AdType get selectedAdTypeObject {
    return adTypes.firstWhere((type) => type.id == selectedAdType.value);
  }

  double get totalCost {
    return currentBid.value * selectedDuration.value;
  }

  double get recommendedBid {
    final adType = selectedAdTypeObject;
    // Add some variation to base price for "market rate"
    return adType.basePrice + (adType.basePrice * 0.2);
  }

  double get estimatedViews {
    // Simple estimation based on bid amount and duration
    final baseDailyViews = (currentBid.value / selectedAdTypeObject.basePrice) * 50;
    return baseDailyViews * selectedDuration.value;
  }

  double get estimatedClicks {
    // Assume 7% click rate
    return estimatedViews * 0.07;
  }

  void startBidding() {
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

    _showBiddingConfirmation();
  }

  void _showBiddingConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Advertisement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ad Type: ${selectedAdTypeObject.name}'),
            Text('Daily Bid: ₹${currentBid.value.toStringAsFixed(0)}'),
            Text('Duration: ${selectedDuration.value} days'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sellerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Cost: ₹${totalCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text('Estimated Views: ${estimatedViews.toStringAsFixed(0)}'),
                  Text('Estimated Clicks: ${estimatedClicks.toStringAsFixed(0)}'),
                ],
              ),
            ),
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
              _processPayment();
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

  void _processPayment() {
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
                '₹${totalCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 3), () {
      isProcessingPayment.value = false;
      Get.back(); // Close payment dialog
      _launchAdCampaign();
    });
  }

  void _launchAdCampaign() {
    // Create new campaign
    final newCampaign = AdCampaign(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      adType: selectedAdTypeObject,
      bid: currentBid.value,
      duration: selectedDuration.value,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: selectedDuration.value)),
      totalBudget: totalCost,
      remainingBudget: totalCost,
      isActive: true,
    );

    hasActiveAdCampaign.value = true;
    currentCampaign.value = newCampaign;

    // Show success dialog
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.sellerPrimary),
            const SizedBox(width: 8),
            const Text('Campaign Active!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your advertising campaign is now live!'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${selectedAdTypeObject.name} - Active'),
                  Text('Duration: ${selectedDuration.value} days'),
                  Text('Daily Budget: ₹${currentBid.value.toStringAsFixed(0)}'),
                  Text('Total Budget: ₹${totalCost.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can track your campaign performance in the Analytics section.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sellerPrimary,
            ),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void pauseCampaign() {
    if (currentCampaign.value != null) {
      currentCampaign.value!.isActive = false;
      currentCampaign.refresh();
      
      Get.snackbar(
        'Campaign Paused',
        'Your advertising campaign has been paused.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void resumeCampaign() {
    if (currentCampaign.value != null) {
      currentCampaign.value!.isActive = true;
      currentCampaign.refresh();
      
      Get.snackbar(
        'Campaign Resumed',
        'Your advertising campaign has been resumed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void cancelCampaign() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Campaign'),
        content: const Text(
          'Are you sure you want to cancel your active campaign? Unused budget will be refunded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Campaign'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cancelCampaignConfirmed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Campaign'),
          ),
        ],
      ),
    );
  }

  void _cancelCampaignConfirmed() {
    final refundAmount = currentCampaign.value?.remainingBudget ?? 0.0;
    
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

// Data models for advertising
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
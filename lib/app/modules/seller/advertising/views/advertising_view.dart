import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/advertising_controller.dart';

class AdvertisingView extends GetView<AdvertisingController> {
  const AdvertisingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentCampaignCard(),
            const SizedBox(height: 24),
            _buildPerformanceOverview(),
            const SizedBox(height: 24),
            _buildCreateCampaignSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: const Text(
        'Advertising',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: AppTheme.textPrimary),
          onPressed: () => _showAdvertisingHelp(),
        ),
      ],
    );
  }

  Widget _buildCurrentCampaignCard() {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: controller.campaignStatusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Campaign',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.campaignStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.campaignStatusText,
                    style: TextStyle(
                      color: controller.campaignStatusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (controller.hasActiveAdCampaign.value) ...[
              _buildActiveCampaignDetails(),
            ] else ...[
              _buildNoCampaignState(),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildActiveCampaignDetails() {
    return Obx(() {
      final campaign = controller.currentCampaign.value!;
      final remainingDays = campaign.endDate.difference(DateTime.now()).inDays;
      final progressPercentage = (campaign.totalBudget - campaign.remainingBudget) / campaign.totalBudget;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign type and details
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: campaign.adType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  campaign.adType.icon,
                  color: campaign.adType.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.adType.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      campaign.adType.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Campaign metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Daily Bid',
                  value: '₹${campaign.bid.toStringAsFixed(0)}',
                  color: AppTheme.sellerPrimary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Remaining Days',
                  value: '$remainingDays',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Remaining Budget',
                  value: '₹${campaign.remainingBudget.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Budget progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Used',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${(progressPercentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.sellerPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: campaign.isActive 
                      ? controller.pauseCampaign 
                      : controller.resumeCampaign,
                  icon: Icon(
                    campaign.isActive ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(campaign.isActive ? 'Pause' : 'Resume'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sellerPrimary,
                    side: const BorderSide(color: AppTheme.sellerPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.cancelCampaign,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildNoCampaignState() {
    return Column(
      children: [
        Icon(
          Icons.campaign_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No Active Campaign',
          style: Get.textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create an advertising campaign to boost your visibility and attract more customers.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _scrollToCreateCampaign(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Campaign'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.sellerPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: AppTheme.buyerPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Performance Overview',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Performance metrics
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildPerformanceMetric(
                  icon: Icons.visibility,
                  label: 'Total Views',
                  value: controller.totalViews.value.toString(),
                  color: Colors.blue,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildPerformanceMetric(
                  icon: Icons.touch_app,
                  label: 'Total Clicks',
                  value: controller.totalClicks.value.toString(),
                  color: Colors.green,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildPerformanceMetric(
                  icon: Icons.currency_rupee,
                  label: 'Total Spent',
                  value: '₹${controller.totalSpent.value.toStringAsFixed(0)}',
                  color: Colors.orange,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildPerformanceMetric(
                  icon: Icons.calendar_today,
                  label: 'Total Days',
                  value: controller.totalDays.value.toString(),
                  color: Colors.purple,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Performance insights
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.buyerPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.buyerPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your ads are performing well! Consider increasing your bid for better visibility.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.buyerPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCampaignSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_business,
                color: AppTheme.sellerPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Create New Campaign',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Ad type selection
          _buildAdTypeSelection(),
          const SizedBox(height: 20),
          
          // Bid amount slider
          _buildBidAmountSlider(),
          const SizedBox(height: 20),
          
          // Duration selection
          _buildDurationSelection(),
          const SizedBox(height: 20),
          
          // Campaign summary
          _buildCampaignSummary(),
          const SizedBox(height: 20),
          
          // Start campaign button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.startBidding,
              icon: const Icon(Icons.campaign, size: 20),
              label: const Text('Start Campaign'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sellerPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advertisement Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Column(
          children: controller.adTypes.map((adType) {
            final isSelected = controller.selectedAdType.value == adType.id;
            return GestureDetector(
              onTap: () => controller.updateAdType(adType.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? adType.color.withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? adType.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: adType.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(adType.icon, color: adType.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adType.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? adType.color : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            adType.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${adType.basePrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: adType.color,
                          ),
                        ),
                        const Text(
                          'per day',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildBidAmountSlider() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Bid Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.sellerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₹${controller.currentBid.value.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sellerPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(Get.context!).copyWith(
            activeTrackColor: AppTheme.sellerPrimary,
            inactiveTrackColor: AppTheme.sellerPrimary.withOpacity(0.3),
            thumbColor: AppTheme.sellerPrimary,
            overlayColor: AppTheme.sellerPrimary.withOpacity(0.2),
          ),
          child: Slider(
            value: controller.currentBid.value,
            min: 25.0,
            max: 200.0,
            divisions: 35,
            onChanged: controller.updateBid,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min: ₹25',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Recommended: ₹${controller.recommendedBid.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.sellerPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Max: ₹200',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    ));
  }

  Widget _buildDurationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Campaign Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.durationOptions.map((days) {
            final isSelected = controller.selectedDuration.value == days;
            return GestureDetector(
              onTap: () => controller.updateDuration(days),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.sellerPrimary 
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.sellerPrimary 
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  days == 1 ? '$days day' : '$days days',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildCampaignSummary() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sellerPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.sellerPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ad Type:'),
              Text(
                controller.selectedAdTypeObject.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Bid:'),
              Text(
                '₹${controller.currentBid.value.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration:'),
              Text(
                '${controller.selectedDuration.value} days',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Cost:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${controller.totalCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sellerPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated ${controller.estimatedViews.toStringAsFixed(0)} views, ${controller.estimatedClicks.toStringAsFixed(0)} clicks',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ));
  }

  void _scrollToCreateCampaign() {
    // In a real implementation, you would scroll to the create campaign section
    // For now, we'll just show a message
    Get.snackbar(
      'Create Campaign',
      'Scroll down to create your first advertising campaign!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showAdvertisingHelp() {
    Get.dialog(
      AlertDialog(
        title: const Text('Advertising Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'How Advertising Works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Choose an ad type based on where you want to appear\n'
                '• Set your daily bid amount - higher bids get better placement\n'
                '• Select campaign duration from 1 to 30 days\n'
                '• Pay upfront for the entire campaign\n'
                '• Track performance in real-time',
              ),
              SizedBox(height: 16),
              Text(
                'Ad Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Featured Listing: Appear in featured sellers section\n'
                '• Top Search: Show at top of search results\n'
                '• Map Priority: Highlighted pin on buyer map\n'
                '• Home Banner: Banner placement on home screen',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
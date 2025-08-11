import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/advertising_controller.dart';

class AdvertisingView extends GetView<AdvertisingController> {
  const AdvertisingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advertising')),
      body: Obx(() {
        final hasActive = controller.hasActiveAdCampaign.value;
        final campaign = controller.currentCampaign.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActiveCampaignCard(
                hasActive: hasActive,
                campaign: campaign,
                onCancel: controller.cancelCampaign,
              ),
              const SizedBox(height: 16),
              Text('Choose your promotion', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _AdOptionTile(
                icon: Icons.star,
                color: Colors.orange,
                title: 'Featured Seller',
                subtitle: 'Appear in featured sellers section',
                price: '₹100',
                onTap: () => controller.purchaseAd('featured'),
              ),
              const SizedBox(height: 12),
              _AdOptionTile(
                icon: Icons.emoji_events,
                color: Colors.purple,
                title: 'Top 3 Placement',
                subtitle: 'Be shown among top 3 spots',
                price: '₹500',
                onTap: () => controller.purchaseAd('top3'),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ActiveCampaignCard extends StatelessWidget {
  final bool hasActive;
  final AdCampaign? campaign;
  final VoidCallback onCancel;
  const _ActiveCampaignCard({
    required this.hasActive,
    required this.campaign,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasActive || campaign == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('No active campaign')),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(campaign!.adType.icon, color: campaign!.adType.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign!.adType.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      _statusText(campaign!),
                      style: TextStyle(color: _statusColor(campaign!)),
                    ),
                  ],
                ),
              ),
              Text('₹${campaign!.totalBudget.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel Campaign'),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _statusText(AdCampaign campaign) {
    if (!campaign.isActive) return 'Campaign Paused';
    final remainingDays = campaign.endDate.difference(DateTime.now()).inDays;
    return 'Active - $remainingDays days remaining';
  }

  Color _statusColor(AdCampaign campaign) {
    if (!campaign.isActive) return Colors.orange;
    return Colors.green;
  }
}

class _AdOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  const _AdOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.sellerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                price,
                style: TextStyle(
                  color: AppTheme.sellerPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
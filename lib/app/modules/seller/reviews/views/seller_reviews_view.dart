import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/seller_reviews_controller.dart';
import '../../../../core/theme/app_theme.dart';

class SellerReviewsView extends GetView<SellerReviewsController> {
  const SellerReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadReviews,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final stats = controller.statistics;
        return Row(
          children: [
            Expanded(child: _buildStatItem('Seller Reviews', '${stats['totalSellerReviews'] ?? 0}', '${(stats['avgSellerRating'] ?? 0.0).toStringAsFixed(1)} ★')),
            const VerticalDivider(),
            Expanded(child: _buildStatItem('Product Reviews', '${stats['totalProductReviews'] ?? 0}', '${(stats['avgProductRating'] ?? 0.0).toStringAsFixed(1)} ★')),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(String title, String count, String rating) {
    return Column(
      children: [
        Text(title, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(count, style: Get.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.sellerPrimary)),
        Text(rating, style: Get.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: Obx(() => _buildTab('Seller Reviews', 'seller', controller.sellerReviews.length))),
          Expanded(child: Obx(() => _buildTab('Product Reviews', 'product', controller.productReviews.length))),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String value, int count) {
    final isSelected = controller.selectedTab.value == value;
    return InkWell(
      onTap: () => controller.switchTab(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? AppTheme.sellerPrimary : Colors.transparent, width: 2)),
        ),
        child: Text(
          '$title ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.sellerPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final reviews = controller.selectedTab.value == 'seller' 
          ? controller.sellerReviews 
          : controller.productReviews;

      if (reviews.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 80, color: AppTheme.textHint),
              const SizedBox(height: 16),
              Text('No reviews yet', style: Get.textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
      );
    });
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final isSellerReview = controller.selectedTab.value == 'seller';
    final rating = review['rating'] ?? 0;
    final userName = review['userName'] ?? 'Anonymous';
    final reviewText = review['reviewText'] ?? '';
    final reviewTitle = review['reviewTitle'] ?? 'No title';
    final productName = review['productName'];
    final createdAt = DateTime.tryParse(review['createdAt'] ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStarRating(rating.toDouble()),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      controller.confirmDelete(isSellerReview, review['reviewid'], reviewTitle);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete Review')])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isSellerReview && productName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.sellerPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Product: $productName', style: Get.textTheme.bodySmall?.copyWith(color: AppTheme.sellerPrimary)),
              ),
              const SizedBox(height: 8),
            ],
            Text(reviewTitle, style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('By $userName', style: Get.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            if (reviewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reviewText),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(_formatDate(createdAt), style: Get.textTheme.bodySmall?.copyWith(color: AppTheme.textHint)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

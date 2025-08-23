import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/enquiry_controller.dart';
import '../../../../data/models/enquiry.dart';
import '../../../../data/models/enquiry_response.dart';

class EnquiryDetailsView extends GetView<EnquiryController> {
  const EnquiryDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final Enquiry enquiry = Get.arguments as Enquiry;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Enquiry Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Get.toNamed('/buyer-edit-enquiry', arguments: enquiry);
                  break;
                case 'share':
                  _shareEnquiry(enquiry);
                  break;
                case 'deactivate':
                  controller.markEnquiryInactive(enquiry.id);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              if (enquiry.isActive)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.pause, size: 18),
                      SizedBox(width: 8),
                      Text('Deactivate'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadEnquiryResponses(enquiry.id),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnquiryHeader(enquiry),
              const SizedBox(height: 24),
              _buildEnquiryDetails(enquiry),
              const SizedBox(height: 24),
              _buildResponsesSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnquiryHeader(Enquiry enquiry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.buyerPrimary.withValues(alpha: 0.1),
            AppTheme.buyerPrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.buyerPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.buyerPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enquiry.title,
                      style: Get.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: enquiry.urgencyColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            enquiry.urgencyDisplay,
                            style: Get.textTheme.labelSmall?.copyWith(
                              color: enquiry.urgencyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: enquiry.isActive 
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            enquiry.isActive ? 'Active' : 'Inactive',
                            style: Get.textTheme.labelSmall?.copyWith(
                              color: enquiry.isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                Icons.chat_bubble_outline,
                '${enquiry.responseCount}',
                'Response${enquiry.responseCount == 1 ? '' : 's'}',
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.category,
                '${enquiry.categories.length}',
                'Categor${enquiry.categories.length == 1 ? 'y' : 'ies'}',
                Colors.purple,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.access_time,
                enquiry.timeAgo,
                '',
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: Get.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(
              label,
              style: Get.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnquiryDetails(Enquiry enquiry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            enquiry.description,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          
          // Categories
          Text(
            'Categories',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: enquiry.categories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.buyerPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          
          // Budget if specified
          if (enquiry.budgetMin != null || enquiry.budgetMax != null) ...[
            const SizedBox(height: 20),
            Text(
              'Budget Range',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    enquiry.budgetRange,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Preferred location if specified
          if (enquiry.preferredLocation != null) ...[
            const SizedBox(height: 20),
            Text(
              'Preferred Location',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    enquiry.preferredLocation!,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Seller Responses',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Obx(() => Text(
              '${controller.enquiryResponses.length} responses',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )),
          ],
        ),
        const SizedBox(height: 16),
        
        Obx(() {
          if (controller.isLoading.value && controller.enquiryResponses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.enquiryResponses.isEmpty) {
            return _buildNoResponsesState();
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.enquiryResponses.length,
            itemBuilder: (context, index) {
              final response = controller.enquiryResponses[index];
              return _buildResponseCard(response);
            },
          );
        }),
      ],
    );
  }

  Widget _buildNoResponsesState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No responses yet',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sellers in your selected categories will be notified.\nResponses will appear here when they reply.',
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(EnquiryResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller info and response time
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.store,
                  color: AppTheme.buyerPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller #${response.sellerId}', // Replace with actual seller name
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      response.timeAgo,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (response.quotedPrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '\$${response.quotedPrice!.toStringAsFixed(0)}',
                    style: Get.textTheme.labelMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Response message
          Text(
            response.message,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          
          // Additional details
          if (response.availability != null || response.deliveryTime != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (response.availability != null)
                  _buildInfoChip(
                    Icons.inventory,
                    response.availability!,
                    Colors.blue,
                  ),
                if (response.deliveryTime != null)
                  _buildInfoChip(
                    Icons.schedule,
                    response.deliveryTime!,
                    Colors.orange,
                  ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewSellerProfile(response.sellerId),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('View Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.buyerPrimary,
                    side: BorderSide(color: AppTheme.buyerPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactSeller(response.sellerId),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buyerPrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Get.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _shareEnquiry(Enquiry enquiry) {
    Get.snackbar(
      'Share',
      'Sharing functionality will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _viewSellerProfile(String sellerId) {
    Get.toNamed('/buyer-seller-view', arguments: {'sellerId': sellerId});
  }

  void _contactSeller(String sellerId) {
    Get.snackbar(
      'Contact',
      'Opening chat with seller...',
      snackPosition: SnackPosition.BOTTOM,
    );
    // In future: Open chat/messaging interface
  }
}

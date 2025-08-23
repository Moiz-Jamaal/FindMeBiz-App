import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/enquiry_controller.dart';
import '../../../../data/models/enquiry.dart';

class EnquiryView extends GetView<EnquiryController> {
  const EnquiryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Enquiries'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Obx(() {
          if (controller.isLoading.value && controller.enquiries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.enquiries.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildStatsHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: controller.enquiries.length,
                  itemBuilder: (context, index) {
                    final enquiry = controller.enquiries[index];
                    return _buildEnquiryCard(enquiry);
                  },
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/buyer-create-enquiry'),
        backgroundColor: AppTheme.buyerPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Enquiry',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.help_outline,
                size: 60,
                color: AppTheme.buyerPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Enquiries Yet',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by creating your first enquiry.\nLet sellers know what you\'re looking for!',
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/buyer-create-enquiry'),
              icon: const Icon(Icons.add),
              label: const Text('Create Enquiry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buyerPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(16),
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
      child: Obx(() => Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Active Enquiries',
              controller.getActiveEnquiriesCount().toString(),
              Icons.help_outline,
              AppTheme.buyerPrimary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(
              'Total Responses',
              controller.getTotalResponsesCount().toString(),
              Icons.chat_bubble_outline,
              Colors.green,
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEnquiryCard(Enquiry enquiry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => controller.viewEnquiryDetails(enquiry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and urgency
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      enquiry.title,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: enquiry.urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      enquiry.urgencyDisplay,
                      style: Get.textTheme.labelSmall?.copyWith(
                        color: enquiry.urgencyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                enquiry.description,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Categories
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: enquiry.categories.take(3).map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: Get.textTheme.labelSmall?.copyWith(
                        color: AppTheme.buyerPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList()
                  ..addAll(enquiry.categories.length > 3
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${enquiry.categories.length - 3} more',
                              style: Get.textTheme.labelSmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]
                      : []),
              ),
              const SizedBox(height: 12),
              
              // Budget if specified
              if (enquiry.budgetMin != null || enquiry.budgetMax != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      enquiry.budgetRange,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Bottom row with time and responses
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    enquiry.timeAgo,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHint,
                    ),
                  ),
                  const Spacer(),
                  if (enquiry.responseCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${enquiry.responseCount} response${enquiry.responseCount == 1 ? '' : 's'}',
                            style: Get.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'No responses yet',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.textHint,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Get.toNamed('/buyer-edit-enquiry', arguments: enquiry);
                          break;
                        case 'deactivate':
                          controller.markEnquiryInactive(enquiry.id);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(enquiry);
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
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Enquiry enquiry) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Enquiry'),
        content: Text(
          'Are you sure you want to delete "${enquiry.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteEnquiry(enquiry.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

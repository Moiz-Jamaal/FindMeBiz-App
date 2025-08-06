import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/customer_inquiries_controller.dart';

class CustomerInquiriesView extends GetView<CustomerInquiriesController> {
  const CustomerInquiriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Customer Inquiries'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshInquiries,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          _buildInquiryStats(),
          Expanded(child: _buildInquiriesList()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      child: Obx(() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: controller.filterOptions.map((filter) {
            final isSelected = controller.selectedFilter.value == filter;
            final count = filter == 'all' 
                ? controller.totalInquiriesCount
                : controller.inquiries.where((i) => i.status == filter).length;
                
            return GestureDetector(
              onTap: () => controller.updateFilter(filter),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.sellerPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.sellerPrimary : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.capitalize!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.sellerPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      )),
    );
  }

  Widget _buildInquiryStats() {
    return Obx(() => Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Inquiries',
              controller.totalInquiriesCount.toString(),
              Icons.message,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'New Inquiries',
              controller.newInquiriesCount.toString(),
              Icons.new_label,
              Colors.orange,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  title,
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
    );
  }

  Widget _buildInquiriesList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading inquiries...'),
            ],
          ),
        );
      }

      final filteredInquiries = controller.filteredInquiries;
      if (filteredInquiries.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async => controller.refreshInquiries(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredInquiries.length,
          itemBuilder: (context, index) {
            final inquiry = filteredInquiries[index];
            return _buildInquiryCard(inquiry);
          },
        ),
      );
    });
  }

  Widget _buildInquiryCard(CustomerInquiry inquiry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with customer info and status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.sellerPrimary.withOpacity(0.1),
                  child: Text(
                    inquiry.customerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.sellerPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inquiry.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        inquiry.customerPhone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(inquiry.status),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Product info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      inquiry.productName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Customer message
            Text(
              inquiry.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            
            // Seller response if available
            if (inquiry.sellerResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sellerPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.sellerPrimary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sellerPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inquiry.sellerResponse!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Time and action buttons
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatTime(inquiry.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (inquiry.status == 'new') ...[
                  TextButton.icon(
                    onPressed: () => controller.showResponseDialog(inquiry),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Reply'),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: () => controller.contactCustomer(inquiry),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Contact'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.sellerPrimary,
                  ),
                ),
                if (inquiry.status != 'resolved') ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'contacted':
                          controller.markAsContacted(inquiry);
                          break;
                        case 'resolved':
                          controller.markAsResolved(inquiry);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (inquiry.status != 'contacted')
                        const PopupMenuItem(
                          value: 'contacted',
                          child: Text('Mark as Contacted'),
                        ),
                      const PopupMenuItem(
                        value: 'resolved',
                        child: Text('Mark as Resolved'),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'new':
        color = Colors.orange;
        text = 'New';
        break;
      case 'contacted':
        color = Colors.blue;
        text = 'Contacted';
        break;
      case 'resolved':
        color = Colors.green;
        text = 'Resolved';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            controller.selectedFilter.value == 'all'
                ? 'No inquiries yet'
                : 'No ${controller.selectedFilter.value} inquiries',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.selectedFilter.value == 'all'
                ? 'Customer inquiries will appear here'
                : 'Try switching to a different filter',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

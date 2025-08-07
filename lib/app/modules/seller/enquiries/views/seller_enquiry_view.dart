import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/seller_enquiry_controller.dart';
import '../../../../data/models/enquiry.dart';

class SellerEnquiryView extends GetView<SellerEnquiryController> {
  const SellerEnquiryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Customer Enquiries'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildStatsHeader(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.filteredEnquiries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.filteredEnquiries.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: controller.filteredEnquiries.length,
                  itemBuilder: (context, index) {
                    final enquiry = controller.filteredEnquiries[index];
                    return _buildEnquiryCard(enquiry);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search enquiries...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.sellerPrimary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: controller.searchEnquiries,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'New Today',
              controller.getNewEnquiriesCount().toString(),
              Icons.fiber_new,
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(
              'Unresponded',
              controller.getUnrespondedCount().toString(),
              Icons.help_outline,
              Colors.orange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(
              'My Responses',
              controller.getMyResponsesCount().toString(),
              Icons.chat_bubble,
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
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: Get.textTheme.titleLarge?.copyWith(
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
                color: AppTheme.sellerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.help_outline,
                size: 60,
                color: AppTheme.sellerPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Enquiries Found',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No customer enquiries match your current filters.\nTry adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.sellerPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryCard(Enquiry enquiry) {
    final hasResponded = controller.hasRespondedToEnquiry(enquiry.id);
    final myResponse = controller.getResponseForEnquiry(enquiry.id);

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
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enquiry.title,
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: enquiry.urgencyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                enquiry.urgencyDisplay,
                                style: Get.textTheme.labelSmall?.copyWith(
                                  color: enquiry.urgencyColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              enquiry.timeAgo,
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (hasResponded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Responded',
                        style: Get.textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'New',
                        style: Get.textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
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
                children: enquiry.categories.map((category) {
                  final isSellerCategory = controller.sellerCategories.contains(category);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSellerCategory 
                          ? AppTheme.sellerPrimary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: isSellerCategory 
                          ? Border.all(color: AppTheme.sellerPrimary.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSellerCategory) ...[
                          Icon(
                            Icons.star,
                            size: 12,
                            color: AppTheme.sellerPrimary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          category,
                          style: Get.textTheme.labelSmall?.copyWith(
                            color: isSellerCategory 
                                ? AppTheme.sellerPrimary
                                : AppTheme.textSecondary,
                            fontWeight: isSellerCategory 
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
              // Budget and location
              if (enquiry.budgetMin != null || enquiry.budgetMax != null || enquiry.preferredLocation != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (enquiry.budgetMin != null || enquiry.budgetMax != null) ...[
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
                    if (enquiry.preferredLocation != null) ...[
                      if (enquiry.budgetMin != null || enquiry.budgetMax != null)
                        const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          enquiry.preferredLocation!,
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Response summary if responded
              if (hasResponded && myResponse != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Your Response',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            myResponse.timeAgo,
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        myResponse.message,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (myResponse.quotedPrice != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Quoted: \$${myResponse.quotedPrice!.toStringAsFixed(0)}',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Action buttons
              Row(
                children: [
                  Text(
                    '${enquiry.responseCount} response${enquiry.responseCount == 1 ? '' : 's'}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHint,
                    ),
                  ),
                  const Spacer(),
                  if (!hasResponded) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showResponseDialog(enquiry),
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('Respond'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sellerPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => controller.viewEnquiryDetails(enquiry),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.sellerPrimary,
                        side: BorderSide(color: AppTheme.sellerPrimary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilters() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Enquiries',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Category filters
              Text(
                'Categories',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.sellerCategories.map((category) {
                  final isSelected = controller.selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) => controller.toggleCategoryFilter(category),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.sellerPrimary.withOpacity(0.2),
                    checkmarkColor: AppTheme.sellerPrimary,
                  );
                }).toList(),
              )),
              
              const SizedBox(height: 20),
              
              // Urgency filters
              Text(
                'Urgency',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['low', 'medium', 'high', 'urgent'].map((urgency) {
                  final isSelected = controller.selectedUrgency.contains(urgency);
                  return FilterChip(
                    label: Text(urgency.substring(0, 1).toUpperCase() + urgency.substring(1)),
                    selected: isSelected,
                    onSelected: (selected) => controller.toggleUrgencyFilter(urgency),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.sellerPrimary.withOpacity(0.2),
                    checkmarkColor: AppTheme.sellerPrimary,
                  );
                }).toList(),
              )),
              
              const SizedBox(height: 20),
              
              // Unresponded filter
              Obx(() => CheckboxListTile(
                title: const Text('Show only unresponded'),
                value: controller.showOnlyUnresponded.value,
                onChanged: (value) => controller.setUnrespondedFilter(value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppTheme.sellerPrimary,
              )),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.clearFilters();
                        Get.back();
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sellerPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResponseDialog(Enquiry enquiry) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Form(
            key: controller.responseFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respond to Enquiry',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    enquiry.title,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Message field
                  TextFormField(
                    controller: controller.responseMessageController,
                    decoration: InputDecoration(
                      labelText: 'Your Message *',
                      hintText: 'Describe your products/services that match this enquiry...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.sellerPrimary),
                      ),
                    ),
                    maxLines: 4,
                    validator: controller.validateMessage,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  
                  // Price and delivery time
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.quotedPriceController,
                          decoration: InputDecoration(
                            labelText: 'Quoted Price',
                            hintText: '0',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.sellerPrimary),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: controller.validatePrice,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: controller.deliveryTimeController,
                          decoration: InputDecoration(
                            labelText: 'Delivery Time',
                            hintText: 'e.g., 3-5 days',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.sellerPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Availability
                  Text(
                    'Availability',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Column(
                    children: controller.availabilityOptions.map((option) {
                      return RadioListTile<String>(
                        title: Text(option['label'] as String),
                        subtitle: Text(option['description'] as String),
                        value: option['value'] as String,
                        groupValue: controller.selectedAvailability.value,
                        onChanged: (value) => controller.setAvailability(value!),
                        activeColor: AppTheme.sellerPrimary,
                        dense: true,
                      );
                    }).toList(),
                  )),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value 
                              ? null 
                              : () => controller.respondToEnquiry(enquiry.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sellerPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Send Response'),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

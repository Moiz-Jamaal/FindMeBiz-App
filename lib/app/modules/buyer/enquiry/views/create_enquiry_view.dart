import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/enquiry_controller.dart';

class CreateEnquiryView extends GetView<EnquiryController> {
  const CreateEnquiryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Enquiry'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: controller.clearForm,
            child: Text(
              'Clear',
              style: TextStyle(color: AppTheme.buyerPrimary),
            ),
          ),
        ],
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildCategoriesSection(),
              const SizedBox(height: 24),
              _buildBudgetSection(),
              const SizedBox(height: 24),
              _buildAdditionalDetailsSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.buyerPrimary.withValues(alpha: 0.1),
            AppTheme.buyerPrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.buyerPrimary,
              borderRadius: BorderRadius.circular(25),
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
                  'Tell us what you need',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sellers in your selected categories will be notified',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title field
        TextFormField(
          controller: controller.titleController,
          decoration: InputDecoration(
            labelText: 'Enquiry Title *',
            hintText: 'e.g., Looking for handmade jewelry',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.buyerPrimary),
            ),
          ),
          validator: controller.validateTitle,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        
        // Description field
        TextFormField(
          controller: controller.descriptionController,
          decoration: InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe what you\'re looking for in detail...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.buyerPrimary),
            ),
          ),
          validator: controller.validateDescription,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories *',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select categories where sellers might have what you need',
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.availableCategories.map((category) {
                  final isSelected = controller.selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) => controller.toggleCategory(category),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.buyerPrimary.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.buyerPrimary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.buyerPrimary : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              )),
              
              const SizedBox(height: 12),
              Obx(() => controller.selectedCategories.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.buyerPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${controller.selectedCategories.length} categor${controller.selectedCategories.length == 1 ? 'y' : 'ies'} selected',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppTheme.buyerPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Please select at least one category',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range (Optional)',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Help sellers understand your budget expectations',
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.budgetMinController,
                decoration: InputDecoration(
                  labelText: 'Min Budget',
                  hintText: '0',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.buyerPrimary),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: controller.validateBudget,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller.budgetMaxController,
                decoration: InputDecoration(
                  labelText: 'Max Budget',
                  hintText: '0',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.buyerPrimary),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: controller.validateBudget,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Urgency selection
        Text(
          'Urgency Level',
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Column(
          children: controller.urgencyLevels.map((urgency) {
            final isSelected = controller.selectedUrgency.value == urgency['value'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => controller.setUrgency(urgency['value'] as String),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppTheme.buyerPrimary : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? AppTheme.buyerPrimary.withValues(alpha: 0.05) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? AppTheme.buyerPrimary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              urgency['label'] as String,
                              style: Get.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.buyerPrimary : AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              urgency['description'] as String,
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        )),
        
        const SizedBox(height: 16),
        
        // Preferred location
        TextFormField(
          controller: controller.locationController,
          decoration: InputDecoration(
            labelText: 'Preferred Location (Optional)',
            hintText: 'e.g., Near Main Market, Downtown area',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.buyerPrimary),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(() => ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.createEnquiry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.buyerPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: controller.isLoading.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Post Enquiry',
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      )),
    );
  }
}

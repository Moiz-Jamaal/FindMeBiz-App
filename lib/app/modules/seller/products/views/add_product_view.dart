import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/add_product_controller.dart';

class AddProductView extends GetView<AddProductController> {
  const AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Obx(() => _buildProgressIndicator()),
          
          // Step Header
          Obx(() => _buildStepHeader()),
          
          // Content
          Expanded(
            child: Obx(() => _buildStepContent()),
          ),
          
          // Bottom Navigation
          Obx(() => _buildBottomNavigation()),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Colors.white,
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= controller.currentStep.value;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppTheme.sellerPrimary 
                    : AppTheme.sellerPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            controller.stepTitle,
            style: Get.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.stepDescription,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (controller.currentStep.value) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildImagesStep();
      default:
        return const SizedBox();
    }
  }
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Name
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'Enter product name',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
              maxLength: AppConstants.maxProductNameLength,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => controller.notifyValidationChanged(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category Dropdown
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedCategory.value.isNotEmpty 
                  ? controller.selectedCategory.value 
                  : null,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: controller.availableCategories.map((categoryOption) {
                return DropdownMenuItem<String>(
                  value: categoryOption.name,
                  child: Text(categoryOption.name),
                );
              }).toList(),
              onChanged: controller.updateCategory,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            )),
            
            const SizedBox(height: 24),
            
            // Info Card
            Card(
              color: AppTheme.sellerPrimary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.sellerPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose the right category to help buyers find your product easily.',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppTheme.sellerPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Description
          TextFormField(
            controller: controller.descriptionController,
            decoration: const InputDecoration(
              labelText: 'Product Description *',
              hintText: 'Describe your product in detail...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description_outlined),
              ),
            ),
            maxLines: 6,
            maxLength: AppConstants.maxProductDescriptionLength,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => controller.notifyValidationChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Product description is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Price Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price on Inquiry Toggle
                  Obx(() => SwitchListTile(
                    title: const Text('Price on Inquiry'),
                    subtitle: const Text('Let buyers contact you for pricing'),
                    value: controller.priceOnInquiry.value,
                    onChanged: (_) => controller.togglePriceOnInquiry(),
                    contentPadding: EdgeInsets.zero,
                  )),
                  
                  // Price Field (only shown if not price on inquiry)
                  Obx(() => controller.priceOnInquiry.value 
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: controller.priceController,
                            decoration: InputDecoration(
                              labelText: 'Price (${AppConstants.currency})',
                              hintText: 'Enter product price',
                              prefixIcon: const Icon(Icons.currency_rupee),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            onChanged: (_) => controller.notifyValidationChanged(),
                            validator: (value) {
                              if (!controller.priceOnInquiry.value && 
                                  (value == null || value.trim().isEmpty || double.tryParse(value) == null)) {
                                return 'Please enter a valid price or enable "Price on Inquiry"';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tips Card
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Writing Tips',
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Mention key features and benefits\n'
                    '• Include materials, sizes, or specifications\n'
                    '• Highlight what makes it unique\n'
                    '• Be honest and accurate',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildImagesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Images Section
          Text(
            'Product Images',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add up to ${AppConstants.maxImagesPerProduct} high-quality images',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Image Grid
          Obx(() => _buildImageGrid()),
          
          const SizedBox(height: 24),
          
          // Availability Toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => SwitchListTile(
                    title: Text(
                      controller.isAvailable.value 
                          ? 'Available for sale'
                          : 'Not available',
                    ),
                    subtitle: Text(
                      controller.isAvailable.value
                          ? 'Buyers can see and contact you about this product'
                          : 'This product will be hidden from buyers',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    value: controller.isAvailable.value,
                    onChanged: (_) => controller.toggleAvailability(),
                    activeColor: AppTheme.sellerPrimary,
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: controller.productImages.length + 1,
      itemBuilder: (context, index) {
        if (index == controller.productImages.length) {
          // Add image button
          return _buildAddImageButton();
        } else {
          // Image item
          return _buildImageItem(index);
        }
      },
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: controller.productImages.length < AppConstants.maxImagesPerProduct
          ? controller.addImage
          : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.sellerPrimary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.sellerPrimary.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: controller.productImages.length < AppConstants.maxImagesPerProduct
                  ? AppTheme.sellerPrimary
                  : AppTheme.textHint,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Image',
              style: Get.textTheme.bodySmall?.copyWith(
                color: controller.productImages.length < AppConstants.maxImagesPerProduct
                    ? AppTheme.sellerPrimary
                    : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    final img = controller.productImages[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.memory(
              base64Decode(img.base64Content),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 32,
                  color: AppTheme.textHint,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.2,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back Button
            if (controller.currentStep.value > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: const Text('Back'),
                ),
              ),
            
            if (controller.currentStep.value > 0)
              const SizedBox(width: 16),
            
            // Next/Save Button
            Expanded(
              flex: 2,
        child: ElevatedButton(
        onPressed: controller.canProceed && !controller.isSaving.value
          ? (controller.currentStep.value == 2
            ? controller.saveProduct
            : controller.nextStep)
          : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sellerPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
        child: (controller.currentStep.value == 2
            ? controller.isSaving.value
            : controller.isLoading.value)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        controller.currentStep.value == 2 
                            ? 'Save Product' 
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../shared/widgets/image_picker_widget.dart';
import '../controllers/edit_product_controller.dart';

class EditProductView extends GetView<EditProductController> {
  const EditProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (controller.hasChanges.value) {
              controller.showDiscardDialog();
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.canSave ? controller.updateProduct : null,
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Update',
                    style: TextStyle(
                      color: controller.canSave
                          ? AppTheme.sellerPrimary
                          : AppTheme.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          )),
        ],
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : _buildForm()),
    );
  }

  Widget _buildForm() {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            _buildImageSection(),
            const SizedBox(height: 24),
            
            // Basic Information
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            
            // Details Section
            _buildDetailsSection(),
            const SizedBox(height: 24),
            
            // Availability Section
            _buildAvailabilitySection(),
            const SizedBox(height: 32),
            
            // Delete Product Button
            _buildDeleteButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Images',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GetBuilder<EditProductController>(
              builder: (_) => ImagePickerWidget(
                images: controller.productImages,
                onImageAdded: controller.addImage,
                onImageRemoved: controller.removeImage,
                maxImages: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Product Name
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'Enter product name',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Product name is required';
                }
                return null;
              },
              onChanged: (value) => controller.onFieldChanged(),
            ),
            const SizedBox(height: 16),
            
            // Category
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedCategory.value.isNotEmpty 
                  ? controller.selectedCategory.value 
                  : null,
              decoration: const InputDecoration(
                labelText: 'Category *',
                hintText: 'Select category',
              ),
              items: controller.availableCategories.map((categoryOption) {
                return DropdownMenuItem(
                  value: categoryOption.name,
                  child: Text(categoryOption.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.updateCategory(value);
                }
              },
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please select a category';
                }
                return null;
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your product...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              onChanged: (value) => controller.onFieldChanged(),
            ),
            const SizedBox(height: 16),
            
            // Price
            TextFormField(
              controller: controller.priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                hintText: 'Enter price (optional)',
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => controller.onFieldChanged(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            Obx(() => SwitchListTile(
              title: const Text('Product Available'),
              subtitle: Text(
                controller.isAvailable.value
                    ? 'Buyers can see and contact you about this product'
                    : 'Product is hidden from buyers',
              ),
              value: controller.isAvailable.value,
              onChanged: controller.toggleAvailability,
              activeColor: AppTheme.sellerPrimary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.showDeleteDialog,
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text('Delete Product'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

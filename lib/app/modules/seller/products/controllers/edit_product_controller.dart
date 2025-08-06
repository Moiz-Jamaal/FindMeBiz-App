import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../core/theme/app_theme.dart';

class EditProductController extends GetxController {
  // Form controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // Product data
  late Product originalProduct;
  final RxString selectedCategory = ''.obs;
  final RxList<String> productImages = <String>[].obs;
  final RxBool isAvailable = true.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool hasChanges = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProductData();
    _setupListeners();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.onClose();
  }

  void _loadProductData() {
    // Get product from arguments
    final product = Get.arguments as Product?;
    if (product != null) {
      originalProduct = product;
      _populateFields(product);
    } else {
      Get.back();
      Get.snackbar('Error', 'Product not found');
    }
  }

  void _populateFields(Product product) {
    nameController.text = product.name;
    descriptionController.text = product.description;
    priceController.text = product.price?.toString() ?? '';
    selectedCategory.value = product.category;
    productImages.addAll(product.images);
    isAvailable.value = product.isAvailable;
  }

  void _setupListeners() {
    nameController.addListener(onFieldChanged);
    descriptionController.addListener(onFieldChanged);
    priceController.addListener(onFieldChanged);
  }

  void onFieldChanged() {
    hasChanges.value = _detectChanges();
  }

  bool _detectChanges() {
    return nameController.text != originalProduct.name ||
           descriptionController.text != originalProduct.description ||
           priceController.text != (originalProduct.price?.toString() ?? '') ||
           selectedCategory.value != originalProduct.category ||
           !_listsEqual(productImages, originalProduct.images) ||
           isAvailable.value != originalProduct.isAvailable;
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void updateCategory(String category) {
    selectedCategory.value = category;
    onFieldChanged();
  }

  void updateImages(List<String> images) {
    productImages.clear();
    productImages.addAll(images);
    onFieldChanged();
  }

  void addImage(String imagePath) {
    productImages.add(imagePath);
    onFieldChanged();
  }

  void removeImage(int index) {
    if (index >= 0 && index < productImages.length) {
      productImages.removeAt(index);
      onFieldChanged();
    }
  }

  void toggleAvailability(bool available) {
    isAvailable.value = available;
    onFieldChanged();
  }

  bool get canSave {
    return hasChanges.value && 
           nameController.text.trim().isNotEmpty &&
           selectedCategory.value.isNotEmpty;
  }

  void updateProduct() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    // Create updated product
    final updatedProduct = Product(
      id: originalProduct.id,
      sellerId: originalProduct.sellerId,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      price: priceController.text.trim().isNotEmpty 
          ? double.tryParse(priceController.text.trim())
          : null,
      category: selectedCategory.value,
      images: List.from(productImages),
      isAvailable: isAvailable.value,
      createdAt: originalProduct.createdAt,
      updatedAt: DateTime.now(),
    );

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      hasChanges.value = false;

      Get.snackbar(
        'Success',
        'Product updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );

      // Return updated product to previous screen
      Get.back(result: updatedProduct);
    });
  }

  void showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${nameController.text}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              _deleteProduct();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteProduct() {
    isLoading.value = true;

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );

      // Return delete result to previous screen
      Get.back(result: {'deleted': true, 'product': originalProduct});
    });
  }

  void showDiscardDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to products
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

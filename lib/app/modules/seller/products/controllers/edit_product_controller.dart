import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/category_service.dart';
import '../../../../../services/product_service.dart';
import '../../dashboard/controllers/seller_dashboard_controller.dart';

class EditProductController extends GetxController {
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ProductService _productService = Get.find<ProductService>();
  
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
  
  // Categories
  final RxList<CategoryOption> availableCategories = <CategoryOption>[].obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool hasChanges = false.obs;
  final RxBool isFormValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      
      if (response.isSuccess && response.data != null) {
        availableCategories.assignAll(
          response.data!.map((cat) => CategoryOption(
            id: cat.catid.toString(),
            name: cat.catname,
          )).toList()
        );
        
        // Set selected category after categories are loaded
        if (availableCategories.isNotEmpty && originalProduct != null) {
          final matchingCategory = availableCategories.firstWhereOrNull(
            (cat) => originalProduct.categories.contains(cat.name),
          );
          if (matchingCategory != null) {
            selectedCategory.value = matchingCategory.name;
          } else {
            // Select first available category as fallback
            selectedCategory.value = availableCategories.first.name;
          }
          _updateFormValidation();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load categories: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
    descriptionController.text = product.description ?? '';
    priceController.text = product.price?.toString() ?? '';
    
    // Wait for categories to load before setting selection
    if (availableCategories.isNotEmpty && product.categories.isNotEmpty) {
      final matchingCategory = availableCategories.firstWhereOrNull(
        (cat) => cat.name == product.categories.first,
      );
      selectedCategory.value = matchingCategory?.name ?? '';
    } else {
      selectedCategory.value = '';
    }
    
    productImages.addAll(product.images);
    isAvailable.value = product.isAvailable;
    _updateFormValidation();
  }

  void _setupListeners() {
    nameController.addListener(onFieldChanged);
    descriptionController.addListener(onFieldChanged);
    priceController.addListener(onFieldChanged);
  }

  void onFieldChanged() {
    hasChanges.value = _detectChanges();
    _updateFormValidation();
  }

  void _updateFormValidation() {
    isFormValid.value = nameController.text.trim().isNotEmpty &&
                        selectedCategory.value.isNotEmpty;
  }

  bool _detectChanges() {
    return nameController.text != originalProduct.name ||
           descriptionController.text != originalProduct.description ||
           priceController.text != (originalProduct.price?.toString() ?? '') ||
           selectedCategory.value != (originalProduct.categories.isNotEmpty ? originalProduct.categories.first : '') ||
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
    update(); // Trigger GetBuilder rebuild
  }

  void removeImage(int index) {
    if (index >= 0 && index < productImages.length) {
      productImages.removeAt(index);
      onFieldChanged();
      update(); // Trigger GetBuilder rebuild
    }
  }

  void toggleAvailability(bool available) {
    isAvailable.value = available;
    onFieldChanged();
  }

  bool get canSave {
    return hasChanges.value && isFormValid.value;
  }

  Future<void> updateProduct() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      // Get selected category ID
      final selectedCategoryOption = availableCategories.firstWhereOrNull(
        (cat) => cat.name == selectedCategory.value,
      );

      if (selectedCategoryOption == null) {
        Get.snackbar(
          'Error',
          'Invalid category selected',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // Create update request
      final request = UpdateProductRequest(
        productId: int.parse(originalProduct.id),
        productName: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        price: priceController.text.trim().isNotEmpty 
            ? double.tryParse(priceController.text.trim())
            : null,
        priceOnInquiry: priceController.text.trim().isEmpty,
        isAvailable: isAvailable.value,
        categoryIds: [int.parse(selectedCategoryOption.id)],
        primaryCategoryId: int.parse(selectedCategoryOption.id),
        customAttributes: null,
      );

      // Call actual API
      final response = await _productService.updateProduct(request);

      if (response.isSuccess && response.data != null) {
        hasChanges.value = false;
        
        Get.snackbar(
          'Success',
          'Product updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
        );

        // Close edit view and refresh seller dashboard
        Get.back(); // Close edit view
        Get.back(); // Go back to seller dashboard
        
        // Refresh seller dashboard
        try {
          Get.find<SellerDashboardController>().refreshData();
        } catch (e) {
          // Dashboard controller not found, that's okay
        }
      } else {
        // Handle API errors
        String errorMessage = response.message ?? 'Update failed';
        
        // Check for specific constraint violations
        if (errorMessage.toLowerCase().contains('duplicate') || 
            errorMessage.toLowerCase().contains('unique')) {
          errorMessage = 'Product with this name already exists or category conflict occurred';
        }

        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
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

  Future<void> _deleteProduct() async {
    isLoading.value = true;

    try {
      final response = await _productService.deleteProduct(int.parse(originalProduct.id));

      if (response.isSuccess) {
        Get.snackbar(
          'Success',
          'Product deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
        );

        // Return delete result to previous screen
        Get.back(result: {'deleted': true, 'product': originalProduct});
      } else {
        Get.snackbar(
          'Error',
          response.message ?? 'Failed to delete product',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
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

class CategoryOption {
  final String id;
  final String name;

  CategoryOption({required this.id, required this.name});
}

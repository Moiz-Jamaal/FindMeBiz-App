import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProductDetailController extends GetxController {
  // Tracks the currently visible image in the gallery
  final RxInt currentImageIndex = 0.obs;

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
  final Rx<Product?> product = Rx<Product?>(null);
  final RxBool isLoading = false.obs;
  
  // Mock analytics data
  final Map<String, int> mockStats = {
    'views': 45,
    'inquiries': 8,
    'favorites': 12,
  };

  @override
  void onInit() {
    super.onInit();
    _loadProductData();
  }

  void _loadProductData() {
    // Get product from arguments
    final productData = Get.arguments as Product?;
    if (productData != null) {
      product.value = productData;
  currentImageIndex.value = 0;
      

   
    } else {
      Get.back();
      Get.snackbar('Error', 'Product not found');
    }
  }

  void onImagePageChanged(int index) {
    currentImageIndex.value = index;
  }

  void editProduct() {
    if (product.value != null) {
      Get.toNamed('/seller-edit-product', arguments: product.value)?.then((result) {
        if (result is Product) {
          product.value = result;
        } else if (result is Map && result['deleted'] == true) {
          Get.back(result: result);
        }
      });
    }
  }

  void shareProduct() {
    if (product.value != null) {
      Get.snackbar(
        'Share Product',
        'Product link copied to clipboard: ${product.value!.name}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    }
  }

  void deleteProduct() {
    if (product.value == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.value!.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              _performDelete();
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

  void _performDelete() {

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );

      // Return delete result to previous screen
      Get.back(result: {'deleted': true, 'product': product.value});
    
  }

  void duplicateProduct() {
    if (product.value == null) return;

    final originalProduct = product.value!;
    
    // Create a copy with a new ID and name
    final duplicatedProduct = Product(
      id: 'dup_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: originalProduct.sellerId,
      name: '${originalProduct.name} (Copy)',
      description: originalProduct.description,
      price: originalProduct.price,
      categories: List.from(originalProduct.categories),
      images: List.from(originalProduct.images),
      isAvailable: false, // Start as unavailable
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to edit the duplicated product
    Get.toNamed('/seller-edit-product', arguments: duplicatedProduct)?.then((result) {
      if (result is Product) {
        Get.snackbar(
          'Success',
          'Product duplicated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
        );
      }
    });
  }

  void toggleAvailability() {
    if (product.value != null) {
      final updatedProduct = product.value!.copyWith(
        isAvailable: !product.value!.isAvailable,
        updatedAt: DateTime.now(),
      );
      
      product.value = updatedProduct;
      
      Get.snackbar(
        'Updated',
        'Product ${updatedProduct.isAvailable ? 'enabled' : 'disabled'}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    }
  }
}

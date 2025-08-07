import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../core/constants/app_constants.dart';

class ProductsController extends GetxController {
  // Products list
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedCategory = 'All'.obs;
  
  // Categories filter
  final List<String> categories = ['All', ...AppConstants.productCategories];

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  void loadProducts() {
    isLoading.value = true;
    
    // Simulate API call with mock data
    Future.delayed(const Duration(seconds: 1), () {
      products.addAll(_getMockProducts());
      _updateFilteredProducts();
      isLoading.value = false;
    });
  }

  void refreshProducts() {
    isRefreshing.value = true;
    
    Future.delayed(const Duration(seconds: 1), () {
      // Simulate refresh
      isRefreshing.value = false;
    });
  }

  void addProduct() {
    Get.toNamed('/seller-add-product');
  }

  void editProduct(Product product) {
    Get.toNamed('/seller-edit-product', arguments: product)?.then((result) {
      if (result is Product) {
        // Update the product in the list
        final index = products.indexWhere((p) => p.id == result.id);
        if (index != -1) {
          products[index] = result;
          _updateFilteredProducts();
        }
      } else if (result is Map && result['deleted'] == true) {
        // Remove the product from the list
        products.removeWhere((p) => p.id == result['product']?.id);
        _updateFilteredProducts();
      }
    });
  }

  void viewProduct(Product product) {
    Get.toNamed('/seller-product-detail', arguments: product)?.then((result) {
      if (result is Product) {
        // Update the product in the list
        final index = products.indexWhere((p) => p.id == result.id);
        if (index != -1) {
          products[index] = result;
          _updateFilteredProducts();
        }
      } else if (result is Map && result['deleted'] == true) {
        // Remove the product from the list
        products.removeWhere((p) => p.id == result['product']?.id);
        _updateFilteredProducts();
      }
    });
  }

  void deleteProduct(Product product) {
    Get.dialog(
      GetxAlert(
        title: 'Delete Product',
        content: 'Are you sure you want to delete "${product.name}"?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        onConfirm: () {
          products.remove(product);
          _updateFilteredProducts();
          Get.back();
          Get.snackbar(
            'Success',
            'Product deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
    );
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    _updateFilteredProducts();
  }

  void _updateFilteredProducts() {
    if (selectedCategory.value == 'All') {
      filteredProducts.assignAll(products);
    } else {
      filteredProducts.assignAll(
        products.where((product) => product.categories.contains(selectedCategory.value)).toList()
      );
    }
    update(['products_list']);
  }

  // Mock data for development
  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        sellerId: 'seller1',
        name: 'Beautiful Silk Saree',
        description: 'Traditional Surat silk saree with intricate designs. Perfect for special occasions.',
        price: 2500.0,
        categories: ['Apparel'],
        images: [
          'https://via.placeholder.com/300x300/FF6B35/FFFFFF?text=Silk+Saree',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Product(
        id: '2',
        sellerId: 'seller1',
        name: 'Handcrafted Jewelry Set',
        description: 'Elegant gold-plated jewelry set with matching earrings and necklace.',
        price: 1800.0,
        categories: ['Jewelry'],
        images: [
          'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=Jewelry+Set',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Product(
        id: '3',
        sellerId: 'seller1',
        name: 'Gujarati Thali Special',
        description: 'Authentic Gujarati thali with 12 varieties of traditional dishes.',
        price: 350.0,
        categories: ['Food & Beverages'],
        images: [
          'https://via.placeholder.com/300x300/2196F3/FFFFFF?text=Gujarati+Thali',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '4',
        sellerId: 'seller1',
        name: 'Handwoven Wall Art',
        description: 'Beautiful handwoven wall hanging with traditional patterns.',
        price: 1200.0,
        categories: ['Art & Crafts'],
        images: [
          'https://via.placeholder.com/300x300/9C27B0/FFFFFF?text=Wall+Art',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Product(
        id: '5',
        sellerId: 'seller1',
        name: 'Decorative Brass Items',
        description: 'Set of 3 decorative brass items for home decoration.',
        price: 800.0,
        categories: ['Home Decor'],
        images: [
          'https://via.placeholder.com/300x300/FF9800/FFFFFF?text=Brass+Items',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}

// Custom alert dialog for GetX
class GetxAlert extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const GetxAlert({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

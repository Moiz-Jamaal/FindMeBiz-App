import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../services/product_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/category_service.dart';

class ProductsController extends GetxController {
  final ProductService _productService = ProductService.instance;
  final AuthService _authService = Get.find<AuthService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  
  // Products list
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString searchQuery = ''.obs;
  
  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasMorePages = false.obs;
  final int pageSize = 20;
  
  // Categories filter - dynamic categories
  final RxList<String> categories = <String>['All'].obs;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
    loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      
      if (response.isSuccess && response.data != null) {
        final categoryNames = response.data!.map((cat) => cat.catname).toList();
        categories.assignAll(['All', ...categoryNames]);
      }
    } catch (e) {
      // Fallback to static categories if API fails
      categories.assignAll(['All', 'Apparel', 'Jewelry', 'Food & Beverages', 'Art & Crafts', 'Home Decor', 'Electronics', 'Books & Stationery', 'Beauty & Personal Care', 'Others']);
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      products.clear();
      filteredProducts.clear();
    }
    
    isLoading.value = true;
    
    try {
      // Get current seller ID from auth service
      final sellerId = _authService.currentSeller?.sellerId;
       // Debug log
      
      if (sellerId == null) {
        Get.snackbar('Error', 'Seller not found. Please login again.');
         // Debug log
        return;
      }

      final response = await _productService.getProductsBySeller(
        sellerId,
        page: currentPage.value,
        pageSize: pageSize,
        sortBy: 'createdat',
        sortOrder: 'desc',
      );

       // Debug log
       // Debug log

      if (response.isSuccess && response.data != null) {
        final searchResponse = response.data!;
        
         // Debug log
         // Debug log
        
        if (refresh) {
          products.assignAll(searchResponse.products);
        } else {
          products.addAll(searchResponse.products);
        }
        
        // Fetch category names for products
        await _loadCategoryNamesForProducts();
        
        totalPages.value = searchResponse.totalPages;
        hasMorePages.value = searchResponse.hasNextPage;
        
        _updateFilteredProducts();
        
        _showSuccessMessage('${searchResponse.products.length} products loaded', showSnackbar: false);
      } else {
         // Debug log
        _showErrorMessage(response.errorMessage ?? 'Failed to load products');
      }
    } catch (e) {
       // Debug log
      _showErrorMessage('Error loading products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    isRefreshing.value = true;
    await loadProducts(refresh: true);
    isRefreshing.value = false;
  }

  Future<void> loadMoreProducts() async {
    if (!hasMorePages.value || isLoading.value) return;
    
    currentPage.value++;
    await loadProducts();
  }

  void addProduct() {
    Get.toNamed('/seller-add-product')?.then((result) async {
       // Debug log
      if (result != null) {
        // If a product was created, refresh the list from page 1
         // Debug log
        await refreshProducts();
      }
    });
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

  Future<void> deleteProduct(Product product) async {
    final confirmed = await Get.dialog<bool>(
      GetxAlert(
        title: 'Delete Product',
        content: 'Are you sure you want to delete "${product.name}"?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        onConfirm: () => Get.back(result: true),
      ),
    );

    if (confirmed == true) {
      try {
        isLoading.value = true;
        
        final productId = int.tryParse(product.id);
        if (productId == null) {
          _showErrorMessage('Invalid product ID');
          return;
        }

        final response = await _productService.deleteProduct(productId);
        
        if (response.isSuccess) {
          products.remove(product);
          _updateFilteredProducts();
          _showSuccessMessage('Product deleted successfully');
        } else {
          _showErrorMessage(response.errorMessage ?? 'Failed to delete product');
        }
      } catch (e) {
        _showErrorMessage('Error deleting product: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    _updateFilteredProducts();
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    _updateFilteredProducts();
  }

  Future<void> _loadCategoryNamesForProducts() async {
    try {
      // Get all unique category IDs from products
      final categoryIds = <int>{};
      for (final product in products) {
        if (product.productCategories != null) {
          categoryIds.addAll(product.productCategories!.map((pc) => pc.catId));
        }
      }
      
      if (categoryIds.isEmpty) return;
      
      // Fetch all categories to get names
      final response = await _categoryService.getCategories();
      if (response.isSuccess && response.data != null) {
        final categoryMap = <int, String>{};
        for (final category in response.data!) {
          categoryMap[category.catid!] = category.catname;
        }
        
        // Update products with category names
        for (int i = 0; i < products.length; i++) {
          if (products[i].productCategories != null) {
            final categoryNames = products[i].productCategories!
                .map((pc) => categoryMap[pc.catId] ?? 'Category ${pc.catId}')
                .toList();
            
            products[i] = products[i].copyWith(
              categories: categoryNames,
              categoryNames: categoryNames,
            );
          }
        }
        
         // Debug log
      }
    } catch (e) {
       // Debug log
    }
  }

  void _updateFilteredProducts() {
    var filtered = List<Product>.from(products);
    
    // Filter by category
    if (selectedCategory.value != 'All') {
      filtered = filtered.where((product) => 
        product.categories.contains(selectedCategory.value)).toList();
    }
    
    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((product) =>
        product.name.toLowerCase().contains(query) ||
        (product.description?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    filteredProducts.assignAll(filtered);
    update(['products_list']);
  }

  void _showSuccessMessage(String message, {bool showSnackbar = true}) {
    if (showSnackbar) {
      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Utility methods for UI
  String getProductImageUrl(Product product) {
    if (product.images.isNotEmpty) {
      return product.images.first;
    }
    return 'https://via.placeholder.com/300x300/E0E0E0/FFFFFF?text=No+Image';
  }

  String formatPrice(Product product) {
    if (product.customAttributes.containsKey('priceOnInquiry') && 
        product.customAttributes['priceOnInquiry'] == true) {
      return 'Price on Inquiry';
    }
    if (product.price != null) {
      return '₹${product.price!.toStringAsFixed(0)}';
    }
    return 'Price not set';
  }

  Color getAvailabilityColor(Product product) {
    return product.isAvailable ? Colors.green : Colors.red;
  }

  String getAvailabilityText(Product product) {
    return product.isAvailable ? 'Available' : 'Unavailable';
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

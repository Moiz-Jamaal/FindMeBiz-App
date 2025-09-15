import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../services/product_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/seller_service.dart';
import '../../dashboard/controllers/seller_dashboard_controller.dart';

class ProductsController extends GetxController {
  final ProductService _productService = ProductService.instance;
  final AuthService _authService = Get.find<AuthService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final SellerService _sellerService = Get.find<SellerService>();
  
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
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadCategories();
    await loadProducts();
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
      final sellerId = _authService.currentSeller?.sellerid;
      
      if (sellerId == null) {
        // Get.snackbar('Error', 'Seller not found. Please login again.');
        return;
      }

      final response = await _productService.getProducts(
        sellerId: sellerId,
        page: currentPage.value,
        pageSize: pageSize,
        sortBy: 'createdat',
        sortOrder: 'desc',
      );

      if (response.isSuccess && response.data != null) {
        final searchResponse = response.data!;
        
        if (refresh) {
          products.assignAll(searchResponse.products);
        } else {
          products.addAll(searchResponse.products);
        }
        
        totalPages.value = searchResponse.totalPages;
        hasMorePages.value = searchResponse.hasNextPage;
        
        _updateFilteredProducts();
        
        _showSuccessMessage('${searchResponse.products.length} products loaded', showSnackbar: false);
      } else {
        _showErrorMessage(response.errorMessage ?? 'Failed to load products');
      }
    } catch (e) {
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
    _checkSubscriptionBeforeAddProduct();
  }

  Future<void> _checkSubscriptionBeforeAddProduct() async {
    final hasSubscription = await _checkSellerSubscription();
    if (!hasSubscription) {
      _showSubscriptionRequiredDialog();
      return;
    }

    // Proceed to add product if subscription is valid
    Get.toNamed('/seller-add-product')?.then((result) async {
      if (result != null) {
        await refreshProducts();
      }
    });
  }

  Future<bool> _checkSellerSubscription() async {
    try {
      // 1) Prefer dashboard's cached value to keep UX consistent
      if (Get.isRegistered<SellerDashboardController>()) {
        final dash = Get.find<SellerDashboardController>();
        if (dash.hasActiveSubscription) return true;
      }

      // 2) Fallback to live check using the same endpoint as dashboard
      final sellerId = _authService.currentSeller?.sellerid 
        ?? (Get.isRegistered<SellerDashboardController>() 
            ? Get.find<SellerDashboardController>().sellerProfile.value?.sellerid 
            : null);
      if (sellerId == null) return false;

      final response = await _sellerService.checkSubscription(sellerId);
      if (response.success && response.data != null) {
        final data = response.data!;
        final active = (data['hasActiveSubscription'] == true) && (data['isExpired'] != true);

        // Update dashboard cache if available to keep both sections in sync
        if (Get.isRegistered<SellerDashboardController>()) {
          final dash = Get.find<SellerDashboardController>();
          if (active) {
            dash.currentSubscription.value = {
              'planId': data['subscriptionPlan'],
              'name': data['subscriptionPlan'] ?? 'Basic',
              'hasActiveSubscription': true,
              'startDate': data['startDate'],
              'endDate': data['endDate'],
              'isExpired': data['isExpired'] ?? false,
              'amount': data['amount'],
              'currency': data['currency'],
            };
          } else {
            dash.currentSubscription.value = null;
          }
        }

        return active;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showSubscriptionRequiredDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Subscription Required'),
        content: const Text(
          'You need an active subscription to add products. Please subscribe to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // Navigate to subscribe, then refresh both dashboard and products on return
              await Get.toNamed('/seller-publish');
              if (Get.isRegistered<SellerDashboardController>()) {
                await Get.find<SellerDashboardController>().refreshData();
              }
              await refreshProducts();
            },
            child: const Text('Subscribe Now'),
          ),
        ],
      ),
    );
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
    // Use the product's primaryImageUrl getter first
    final primaryUrl = product.primaryImageUrl;
    if (primaryUrl.isNotEmpty && !primaryUrl.contains('placeholder') && !primaryUrl.contains('No+Image')) {
      return primaryUrl;
    }
    
    // Fallback to images array
    if (product.images.isNotEmpty) {
      return product.images.first;
    }
    
    return 'https://via.placeholder.com/300x300/E0E0E0/FFFFFF?text=No+Image';
  }

  String formatPrice(Product product) {
    // Use the product's formattedPrice getter
    return product.formattedPrice;
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

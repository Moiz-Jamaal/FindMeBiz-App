import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_card.dart';

class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(child: _buildProductsGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addProduct,
        backgroundColor: AppTheme.sellerPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Products',
                        style: Get.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildProductCount(),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Toggle view mode (grid/list)
                      },
                      icon: const Icon(Icons.grid_view),
                      color: AppTheme.sellerPrimary,
                    ),
                    IconButton(
                      onPressed: controller.refreshProducts,
                      icon: const Icon(Icons.refresh),
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: controller.searchProducts,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: Icon(Icons.search, color: AppTheme.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.sellerPrimary, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildProductCount() {
    return Obx(() => Text(
      '${controller.filteredProducts.length} products',
      style: Get.textTheme.bodyMedium?.copyWith(
        color: AppTheme.textSecondary,
      ),
    ));
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1),
          SizedBox(
            height: 50,
            child: _buildCategoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
        ),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          
          return Obx(() {
            final isSelected = controller.selectedCategory.value == category;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => controller.filterByCategory(category),
                selectedColor: AppTheme.sellerPrimary.withOpacity(0.2),
                checkmarkColor: AppTheme.sellerPrimary,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? AppTheme.sellerPrimary 
                      : AppTheme.textSecondary,
                  fontWeight: isSelected 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return _buildLoadingStateWidget();
  }

  Widget _buildLoadingStateWidget() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      return _buildProductsList();
    });
  }

  Widget _buildProductsList() {
    return GetBuilder<ProductsController>(
      id: 'products_list',
      builder: (_) {
        final products = controller.filteredProducts;

        if (products.isEmpty && !controller.isLoading.value) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => controller.refreshProducts(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                // Load more products when reaching the bottom
                if (controller.hasMorePages.value && !controller.isLoading.value) {
                  controller.loadMoreProducts();
                }
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length + (controller.hasMorePages.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  // Loading indicator for pagination
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final product = products[index];
                
                return ProductCard(
                  product: product,
                  onTap: () => controller.viewProduct(product),
                  onEdit: () => controller.editProduct(product),
                  onDelete: () => controller.deleteProduct(product),
                  isGridView: true,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Yet',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building your catalog by adding your first product',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sellerPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

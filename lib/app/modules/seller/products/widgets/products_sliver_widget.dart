import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_card.dart';

class ProductsSliverWidget extends GetView<ProductsController> {
  final bool isEmbedded;
  final int? maxItems;
  final VoidCallback? onViewAllPressed;

  const ProductsSliverWidget({
    super.key,
    this.isEmbedded = false,
    this.maxItems,
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductsController>(
      id: 'products_list',
      builder: (_) {
        final allProducts = controller.filteredProducts;
        final products = maxItems != null 
            ? allProducts.take(maxItems!).toList()
            : allProducts;

        if (controller.isLoading.value) {
          return SliverToBoxAdapter(
            child: Container(
              height: 200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (products.isEmpty && !controller.isLoading.value) {
          return _buildEmptyState();
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              
              return ProductCard(
                product: product,
                onTap: () => controller.viewProduct(product),
                onEdit: () => controller.editProduct(product),
                onDelete: () => controller.deleteProduct(product),
                isGridView: true,
              );
            },
            childCount: products.length,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: isEmbedded ? 60 : 80,
                  color: AppTheme.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Products Yet',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEmbedded 
                      ? 'Add your first product to get started'
                      : 'Start building your catalog by adding your first product',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.addProduct,
                  icon: const Icon(Icons.add),
                  label: Text(isEmbedded ? 'Add Product' : 'Add Your First Product'),
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
        ),
      ),
    );
  }
}

class ProductsCategoryFilterSliver extends GetView<ProductsController> {
  const ProductsCategoryFilterSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            
            return Obx(() {
              final isSelected = controller.selectedCategory.value == category;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
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
      ),
    );
  }
}

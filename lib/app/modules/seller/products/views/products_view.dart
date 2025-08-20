import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/products_controller.dart';
import '../widgets/products_sliver_widget.dart';

class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => controller.refreshProducts(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildSearchBar(),
            const ProductsCategoryFilterSliver(),
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              sliver: ProductsSliverWidget(
                isEmbedded: false,
              ),
            ),
            _buildLoadMoreIndicator(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80), // Space for floating action button
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addProduct,
        backgroundColor: AppTheme.sellerPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: false,
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
        color: AppTheme.textPrimary,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.defaultPadding, 
            kToolbarHeight + 20, 
            AppConstants.defaultPadding, 
            16
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(
          AppConstants.defaultPadding, 
          0, 
          AppConstants.defaultPadding, 
          16
        ),
        child: TextField(
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
        ),
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

  Widget _buildLoadMoreIndicator() {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.hasMorePages.value && !controller.isLoading.value) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ElevatedButton(
                onPressed: controller.loadMoreProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sellerPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Load More Products'),
              ),
            ),
          );
        } else if (controller.isLoading.value && controller.filteredProducts.isNotEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}

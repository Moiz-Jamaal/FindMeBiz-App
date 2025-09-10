import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/api/index.dart';
import '../controllers/buyer_favorites_controller.dart';

class BuyerFavoritesView extends GetView<BuyerFavoritesController> {
  const BuyerFavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabSection(),
          _buildFiltersSection(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (controller.isEmpty.value) {
                return _buildEmptyState();
              }
              
              return _buildFavoritesList();
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: const Text(
        'Favorites',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() => controller.hasFavorites
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      controller.refreshFavorites();
                      break;
                    case 'clear_all':
                      controller.clearAllFavorites();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ],
              )
            : const SizedBox()),
      ],
    );
  }

  Widget _buildTabSection() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Obx(() => InkWell(
              onTap: () => controller.switchTab('sellers'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: controller.currentTab.value == 'sellers'
                          ? AppTheme.buyerPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.store,
                      color: controller.currentTab.value == 'sellers'
                          ? AppTheme.buyerPrimary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sellers',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: controller.currentTab.value == 'sellers'
                            ? AppTheme.buyerPrimary
                            : AppTheme.textSecondary,
                        fontWeight: controller.currentTab.value == 'sellers'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (controller.favoritesCount.value != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: controller.currentTab.value == 'sellers'
                              ? AppTheme.buyerPrimary
                              : AppTheme.textHint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${controller.favoritesCount.value!.sellersCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
          ),
          Expanded(
            child: Obx(() => InkWell(
              onTap: () => controller.switchTab('products'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: controller.currentTab.value == 'products'
                          ? AppTheme.buyerPrimary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      color: controller.currentTab.value == 'products'
                          ? AppTheme.buyerPrimary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Products',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: controller.currentTab.value == 'products'
                            ? AppTheme.buyerPrimary
                            : AppTheme.textSecondary,
                        fontWeight: controller.currentTab.value == 'products'
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (controller.favoritesCount.value != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: controller.currentTab.value == 'products'
                              ? AppTheme.buyerPrimary
                              : AppTheme.textHint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${controller.favoritesCount.value!.productsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Count and Sort Row
          Row(
            children: [
              Obx(() => Text(
                '${controller.currentTabCount} ${controller.currentTab.value}',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              )),
              const Spacer(),
              Obx(() => DropdownButton<String>(
                value: controller.sortBy.value,
                underline: const SizedBox(),
                icon: Icon(Icons.sort, color: AppTheme.buyerPrimary),
                items: controller.sortOptions.map((sort) {
                  return DropdownMenuItem(
                    value: sort,
                    child: Text(sort, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) controller.updateSortOption(value);
                },
              )),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
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
                      onSelected: (_) => controller.updateCategoryFilter(category),
                      selectedColor: AppTheme.buyerPrimary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.buyerPrimary,
                      backgroundColor: Colors.grey.shade100,
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshFavorites(),
      child: Obx(() {
        if (controller.currentTab.value == 'sellers') {
          return _buildSellersGrid();
        } else {
          return _buildProductsGrid();
        }
      }),
    );
  }

  Widget _buildSellersGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: controller.favoriteSellers.length,
      itemBuilder: (context, index) {
        final seller = controller.favoriteSellers[index];
        return _buildFavoriteSellerCard(seller);
      },
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = controller.favoriteProducts[index];
        return _buildFavoriteProductCard(product);
      },
    );
  }

  Widget _buildFavoriteSellerCard(seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => controller.viewSeller(seller.sellerid ?? 0),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Business Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.sellerGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Business Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.businessname ?? 'Business Name',
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (seller.bio != null && seller.bio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            seller.bio!,
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                       
                      ],
                    ),
                  ),
                  
                  // Favorite Button
                  IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () => controller.toggleSellerFavorite(
                      seller.sellerid ?? 0,
                      seller.businessname ?? 'Seller',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility,
                    label: 'View',
                    onPressed: () => controller.viewSeller(seller.sellerid ?? 0),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildActionButton(
                    icon: Icons.chat,
                    label: 'Contact',
                    onPressed: () => controller.contactSeller(seller),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildActionButton(
                    icon: Icons.directions,
                    label: 'Directions',
                    onPressed: () => controller.getDirections(seller),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: () => controller.shareProfile(seller),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => controller.viewProduct(int.tryParse(product.id) ?? 0),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        product.primaryImageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.shopping_bag,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => controller.toggleProductFavorite(
                            int.tryParse(product.id) ?? 0, 
                            product.name,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.categoryNames?.isNotEmpty == true)
                      Text(
                        product.categoryNames!.first,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Text(
                      product.formattedPrice,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.buyerPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.buyerPrimary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.buyerPrimary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Obx(() {
          final isSellerTab = controller.currentTab.value == 'sellers';
          final tabName = isSellerTab ? 'Sellers' : 'Products';
          final icon = isSellerTab ? Icons.store : Icons.shopping_bag;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: AppTheme.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'No Favorite $tabName Yet',
                style: Get.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSellerTab
                    ? 'Start exploring and add sellers to your favorites\nto see them here!'
                    : 'Start exploring and add products to your favorites\nto see them here!',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textHint,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed('/buyer-home'),
                icon: Icon(isSellerTab ? Icons.explore : Icons.shopping_bag),
                label: Text(isSellerTab ? 'Explore Sellers' : 'Explore Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buyerPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

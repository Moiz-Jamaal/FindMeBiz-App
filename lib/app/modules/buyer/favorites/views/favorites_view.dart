import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/core/widgets/enhanced_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/favorites_controller.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadFavorites,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (controller.hasError.value) {
                return _buildErrorState();
              }

              return _buildFavoritesList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildTab('Products', 'products', controller.products.length)),
          ),
          Expanded(
            child: Obx(() => _buildTab('Sellers', 'sellers', controller.sellers.length)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String value, int count) {
    final isSelected = controller.selectedTab.value == value;
    return InkWell(
      onTap: () => controller.switchTab(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.buyerPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          '$title ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.buyerPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              controller.errorMessage.value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.loadFavorites,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buyerPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Obx(() {
      final items = controller.selectedTab.value == 'products' 
          ? controller.products 
          : controller.sellers;

      if (items.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.separated(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildFavoriteCard(item);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.selectedTab.value == 'products' 
                  ? Icons.favorite_border 
                  : Icons.store_outlined,
              size: 80,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              controller.selectedTab.value == 'products' 
                  ? 'No favorite products' 
                  : 'No favorite sellers',
              style: Get.textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.selectedTab.value == 'products' 
                  ? 'Start exploring products and add them to favorites'
                  : 'Start exploring sellers and add them to favorites',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? EnhancedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          item.type == 'P' ? Icons.image : Icons.store,
                          color: AppTheme.textHint,
                          size: 32,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (item.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppConstants.currency}${item.price!.toStringAsFixed(0)}',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.buyerPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  
                  if (item.sellerName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By ${item.sellerName}',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.chat,
                          label: 'Contact',
                          onPressed: () => controller.contactSeller(item),
                          isPrimary: true,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.directions,
                          label: 'Directions',
                          onPressed: () => controller.getDirections(item),
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions menu
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    item.type == 'P' 
                        ? controller.viewProduct(item)
                        : controller.viewSeller(item);
                    break;
                  case 'remove':
                    controller.removeFromFavorites(item);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(item.type == 'P' ? Icons.visibility : Icons.store),
                      const SizedBox(width: 8),
                      Text(item.type == 'P' ? 'View Product' : 'View Seller'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Favorites'),
                    ],
                  ),
                ),
              ],
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
    required bool isPrimary,
  }) {
    return SizedBox(
      height: 32,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buyerPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.buyerPrimary,
                side: const BorderSide(color: AppTheme.buyerPrimary),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
    );
  }
}

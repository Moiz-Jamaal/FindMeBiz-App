import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
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
        Obx(() => controller.favoriteSellers.isNotEmpty
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
                '${controller.favoriteSellers.length} favorites',
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
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: controller.favoriteSellers.length,
        itemBuilder: (context, index) {
          final seller = controller.favoriteSellers[index];
          return _buildFavoriteCard(seller);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => controller.viewSeller(seller),
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
                        if (seller.stallLocation != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppTheme.textHint,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${seller.stallLocation!.area} • ${seller.stallLocation!.stallNumber}',
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
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
                    onPressed: () => controller.removeFavorite(seller),
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
                    onPressed: () => controller.viewSeller(seller),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No Favorites Yet',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start exploring and add sellers to your favorites\nto see them here!',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/buyer-home'),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Sellers'),
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
        ),
      ),
    );
  }
}

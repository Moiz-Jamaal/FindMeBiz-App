import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/core/widgets/enhanced_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/buyer_search_controller.dart';
import '../../../../services/ad_service.dart';
import '../../../shared/widgets/ads/native_ad_card.dart';
import '../../../shared/widgets/ads/banner_ad_tile.dart';
import '../../../../data/models/sponsored_content.dart';

class SearchView extends GetView<BuyerSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildSearchAppBar(),
      body: Column(
        children: [
          _buildSearchFilters(),
          Expanded(child: _buildSearchContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Container(
        height: 40,
        child: TextField(
          controller: controller.searchTextController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search for products, sellers...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: controller.clearSearch,
                  )
                : const SizedBox()),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onSubmitted: (value) => controller.performSearch(query: value),
        ),
      ),
      actions: [
        Obx(() => IconButton(
          icon: Icon(
            controller.showFilters.value ? Icons.filter_list : Icons.tune,
            color: controller.showFilters.value 
                ? AppTheme.buyerPrimary 
                : AppTheme.textSecondary,
          ),
          onPressed: controller.toggleFilters,
        )),
      ],
    );
  }

  Widget _buildSearchFilters() {
    return Obx(() => AnimatedContainer(
      duration: AppConstants.shortAnimation,
      height: controller.showFilters.value ? 120 : 0,
      child: controller.showFilters.value ? _buildFiltersContent() : null,
    ));
  }

  Widget _buildFiltersContent() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Type Filter
          Row(
            children: [
              Text(
                'Search Type:',
                style: Get.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => Wrap(
                  spacing: 8,
                  children: controller.searchTypes.map((type) {
                    final isSelected = controller.searchType.value == type;
                    return FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (_) => controller.updateSearchType(type),
                      selectedColor: AppTheme.buyerPrimary.withOpacity(0.2),
                      checkmarkColor: AppTheme.buyerPrimary,
                    );
                  }).toList(),
                )),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sort and Location Row
          Row(
            children: [
              // Sort By
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.sortBy.value,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: controller.sortOptions.map((sort) {
                    return DropdownMenuItem(value: sort, child: Text(sort));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.updateSortBy(value);
                  },
                )),
              ),
              
              const SizedBox(width: 16),
              
              // Location Filter
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedCity.value.isEmpty ? null : controller.selectedCity.value,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: controller.availableCities.map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) controller.updateCity(value);
                  },
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSearchContent() {
    return Obx(() {
      if (controller.isSearching.value) {
        return _buildLoadingState();
      } else if (!controller.hasSearched.value) {
        return _buildInitialState();
      } else if (controller.totalResultsCount.value == 0) {
        return _buildEmptyState();
      } else {
        return _buildSearchResults();
      }
    });
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Searching...'),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (controller.recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.recentSearches.take(5).map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () => controller.selectRecentSearch(search),
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Popular Categories
          Text(
            'Popular Categories',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
          
          const SizedBox(height: 24),
          
          // Search Tips
          _buildSearchTips(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final popularCategories = [
      {'name': 'Apparel', 'icon': Icons.checkroom, 'color': Colors.pink},
      {'name': 'Jewelry', 'icon': Icons.diamond, 'color': Colors.amber},
      {'name': 'Food & Beverages', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'Art & Crafts', 'icon': Icons.palette, 'color': Colors.purple},
      {'name': 'Home Decor', 'icon': Icons.home, 'color': Colors.teal},
      {'name': 'Electronics', 'icon': Icons.devices, 'color': Colors.blue},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: popularCategories.length,
      itemBuilder: (context, index) {
        final category = popularCategories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        controller.searchTextController.text = category['name'];
        controller.performSearch(query: category['name']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (category['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                category['icon'],
                color: category['color'],
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'],
              style: Get.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Search Tips',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Try searching for specific products like "silk saree"\n'
            '• Search by seller name or business name\n'
            '• Use category names for broader results\n'
            '• Filter by location to find nearby stalls',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
        ],
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
              Icons.search_off,
              size: 80,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                controller.clearSearch();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.buyerPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results Summary
          _buildResultsSummary(),
          const SizedBox(height: 16),
          
          // Sellers Section
          if (controller.sellerResults.isNotEmpty) ...[
            _buildSectionHeader('Sellers', controller.sellerResults.length),
            const SizedBox(height: 12),
            _buildSellerResults(),
            const SizedBox(height: 24),
          ],
          
          // Products Section
          if (controller.productResults.isNotEmpty) ...[
            _buildSectionHeader('Products', controller.productResults.length),
            const SizedBox(height: 12),
            _buildProductResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.buyerPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppTheme.buyerPrimary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.resultsCountText,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.buyerPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.buyerPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.buyerPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerResults() {
    return Obx(() {
      final sellers = controller.sellerResults;
      // Deterministic placement: insert a single native ad after the 2nd seller if available
      final adIndex = sellers.length >= 2 ? 2 : (sellers.isNotEmpty ? 1 : null);
      final itemCount = sellers.length + (adIndex != null ? 1 : 0);
      final adService = Get.find<AdService>();
      final ad = adService.getSponsoredForSlot(AdSlot.searchSellers).first;

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (adIndex != null && index == adIndex) {
            return NativeAdCard(
              ad: ad,
              onTap: () {
                if (ad.deeplinkRoute != null) {
                  Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                }
              },
            );
          }
          final dataIndex = adIndex != null && index > adIndex ? index - 1 : index;
          final seller = sellers[dataIndex];
          return _buildSellerCard(seller);
        },
      );
    });
  }

  Widget _buildProductResults() {
  final adService = Get.find<AdService>();
  // Deterministic: show a single slim banner above grid if there are any products
  final showBanner = controller.productResults.isNotEmpty;
  final ad = showBanner ? adService.getSponsoredForSlot(AdSlot.searchProducts).first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBanner && ad != null) ...[
          BannerAdTile(
            ad: ad,
            onTap: () {
              if (ad.deeplinkRoute != null) {
                Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.productResults.length,
          itemBuilder: (context, index) {
            final product = controller.productResults[index];
            return _buildProductCard(product);
          },
        ),
      ],
    );
  }
  Widget _buildSellerCard(seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => controller.viewSeller(seller),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Seller Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.buyerPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: seller.logo?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: EnhancedNetworkImage(
                          imageUrl: seller.logo!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                          errorWidget: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.buyerPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.store,
                              color: AppTheme.buyerPrimary,
                              size: 30,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: AppTheme.buyerPrimary,
                        size: 30,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Seller Info
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
                    const SizedBox(height: 4),
                    Text(
                      seller.profilename ?? 'Seller',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (seller.bio?.isNotEmpty == true) ...[
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
                    if (seller.area?.isNotEmpty == true || seller.city?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${seller.area ?? ''}${seller.area?.isNotEmpty == true && seller.city?.isNotEmpty == true ? ', ' : ''}${seller.city ?? ''}'.trim(),
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Contact Button
              IconButton(
                onPressed: () {
                  // Contact seller action
                  Get.snackbar(
                    'Contact Seller',
                    'Opening WhatsApp to contact ${seller.businessname ?? 'Business'}',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: Icon(
                  Icons.chat,
                  color: AppTheme.buyerPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(product) {
    return Card(
      child: InkWell(
        onTap: () {
          // Pass the product object to the controller for proper handling
          controller.viewProduct(product);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: product.primaryImageUrl.isNotEmpty && !product.primaryImageUrl.contains('placeholder')
                      ? Image.network(
                          product.primaryImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: AppTheme.textHint,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: AppTheme.textHint,
                          ),
                        ),
                ),
              ),
            ),
            
            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      product.category,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    if (product.price != null)
                      Text(
                        '${AppConstants.currency}${product.price!.toStringAsFixed(0)}',
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.buyerPrimary,
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
}

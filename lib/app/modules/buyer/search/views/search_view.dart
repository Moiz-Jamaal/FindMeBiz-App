import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:souq/app/data/models/api/category_master.dart';
import 'package:souq/core/widgets/enhanced_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          _buildLocationToggle(),
          Expanded(child: _buildSearchContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: SizedBox(
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
            controller.useLocation.value ? Icons.location_on : Icons.location_off,
            color: controller.useLocation.value 
                ? AppTheme.buyerPrimary 
                : AppTheme.textSecondary,
          ),
          onPressed: controller.toggleLocationSearch,
          tooltip: controller.useLocation.value ? 'Disable location' : 'Enable nearby search',
        )),
      ],
    );
  }

  Widget _buildLocationToggle() {
    return Obx(() {
      if (!controller.useLocation.value) return const SizedBox.shrink();
      
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.buyerPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.buyerPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.hasValidLocation 
                    ? 'Showing nearby results within ${controller.radiusKm.value.toInt()} km'
                    : 'Getting your location...',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.buyerPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!controller.hasValidLocation)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.buyerPrimary),
                ),
              ),
          ],
        ),
      );
    });
  }


  Widget _buildSearchContent() {
    return Obx(() {
      if (controller.isSearching.value) {
        return _buildLoadingState();
  } else if (!controller.hasSearched.value && !controller.useLocation.value) {
        return _buildInitialState();
  } else if (controller.totalResultsCount.value == 0 && controller.placesResults.isEmpty) {
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
    return Obx(() {
      if (controller.availableCategories.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      final categories = controller.availableCategories.take(6).toList();
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category);
        },
      );
    });
  }

  Widget _buildCategoryCard(CategoryMaster category) {
    // Map category names to icons and colors
    final categoryMap = {
      'Apparel': {'icon': Icons.checkroom, 'color': Colors.pink},
      'Jewelry': {'icon': Icons.diamond, 'color': Colors.amber},
      'Food & Beverages': {'icon': Icons.restaurant, 'color': Colors.orange},
      'Art & Crafts': {'icon': Icons.palette, 'color': Colors.purple},
      'Home Decor': {'icon': Icons.home, 'color': Colors.teal},
      'Electronics': {'icon': Icons.devices, 'color': Colors.blue},
      'Fashion': {'icon': Icons.checkroom, 'color': Colors.pink},
      'Accessories': {'icon': Icons.diamond, 'color': Colors.amber},
      'Food': {'icon': Icons.restaurant, 'color': Colors.orange},
      'Crafts': {'icon': Icons.palette, 'color': Colors.purple},
      'Home': {'icon': Icons.home, 'color': Colors.teal},
      'Technology': {'icon': Icons.devices, 'color': Colors.blue},
    };
    
    final categoryData = categoryMap[category.catname] ?? 
        {'icon': Icons.category, 'color': Colors.grey};
    final rawUrl = category.icon;
    String? iconUrl = rawUrl;
    if (iconUrl != null) {
      if (!iconUrl.contains('://')) {
        iconUrl = 'https://findmebiz-media.s3.us-east-1.amazonaws.com/icons/' + iconUrl;
      }
      try {
        final uri = Uri.parse(iconUrl);
        final encoded = Uri(
          scheme: uri.scheme,
          userInfo: uri.userInfo,
          host: uri.host,
          port: uri.hasPort ? uri.port : null,
          pathSegments: uri.pathSegments.map(Uri.encodeComponent).toList(),
          query: uri.query,
          fragment: uri.fragment,
        );
        iconUrl = encoded.toString();
      } catch (_) {
        iconUrl = (iconUrl ?? '').replaceAll(' ', '%20');
      }
    }
    final bool isSvg = (() {
      if (iconUrl == null) return false;
      try {
        final p = Uri.parse(iconUrl).path.toLowerCase();
        return p.endsWith('.svg');
      } catch (_) {
        return iconUrl.toLowerCase().endsWith('.svg');
      }
    })();
    
    return GestureDetector(
      onTap: () {
        // Selecting a category should populate the search box with its name
        // and run search consistently using both query and category filter.
        if (category.catid != null) {
          controller.onCategorySelected(category);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: (categoryData['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: (iconUrl != null && iconUrl.isNotEmpty)
                  ? Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: isSvg
                          ? SvgPicture.network(
                              iconUrl,
                              fit: BoxFit.contain,
                              placeholderBuilder: (ctx) => Icon(
                                categoryData['icon'] as IconData,
                                color: categoryData['color'] as Color,
                                size: 20,
                              ),
                            )
                          : Image.network(
                              iconUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, st) => Icon(
                                categoryData['icon'] as IconData,
                                color: categoryData['color'] as Color,
                                size: 20,
                              ),
                            ),
                    )
                  : Icon(
                      categoryData['icon'] as IconData,
                      color: categoryData['color'] as Color,
                      size: 24,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              category.catname,
              style: Get.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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

          // Google Places supplemental results (always after app results)
          if (controller.placesResults.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Nearby on Google', controller.placesResults.length),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.placesResults.length,
              itemBuilder: (context, index) {
                final place = controller.placesResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: place.photoUrl != null && place.photoUrl!.isNotEmpty
                            ? Image.network(
                                place.photoUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.place, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.place, color: Colors.grey),
                              ),
                      ),
                    ),
                    title: Text(place.displayName.isNotEmpty ? place.displayName : 'Place'),
                    subtitle: Text(place.formattedAddress),
                    trailing: IconButton(
                      icon: const Icon(Icons.map, color: Colors.green),
                      onPressed: () => controller.openPlaceInMaps(place),
                    ),
                    onTap: () => controller.openPlaceInMaps(place),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
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
            color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
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

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (adIndex != null && index == adIndex) {
            return FutureBuilder<List<SponsoredContent>>(
              future: Get.find<AdService>().getSponsoredForSlotSync(AdSlot.searchSellers),
              builder: (context, snapshot) {
                final ads = snapshot.data ?? [];
                if (ads.isEmpty) return const SizedBox.shrink();
                
                final ad = ads.first;
                return NativeAdCard(
                  ad: ad,
                  onTap: () {
                    if (ad.deeplinkRoute != null) {
                      Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                    }
                  },
                );
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
    return FutureBuilder<List<SponsoredContent>>(
      future: Get.find<AdService>().getSponsoredForSlotSync(AdSlot.searchProducts),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? [];
        // Only attempt to show a banner if we have products and a candidate ad with a URL
  final hasCandidates = controller.productResults.isNotEmpty && ads.isNotEmpty;
  final ad = hasCandidates ? ads.first : null;
  final bannerUrl = ad?.imageUrl;
  final shouldTryBanner = hasCandidates && bannerUrl != null && bannerUrl.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      if (shouldTryBanner && ad != null)
              FutureBuilder<bool>(
        future: _imageLoads(context, ad.imageUrl!),
                builder: (context, snap) {
                  final ok = snap.data == true;
                  if (ok) {
                    return Column(
                      children: [
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
                    );
                  }
                  // If image is loading or failed, do not show any fallback banner
                  return const SizedBox.shrink();
                },
              ),
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
      },
    );
  }

  // Ensure we only show banner ads when the image actually loads from the internet.
  Future<bool> _imageLoads(BuildContext context, String url) async {
    try {
      final completer = Completer<bool>();
      final provider = NetworkImage(url);
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo _, bool __) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (Object _, StackTrace? __) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      stream.addListener(listener);
      // Avoid hanging forever if the request stalls.
      return completer.future.timeout(const Duration(seconds: 6), onTimeout: () => false);
    } catch (_) {
      return false;
    }
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
                  color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
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
                              color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/modules/daily_offer/controllers/daily_offer_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/api/index.dart';
import '../controllers/buyer_home_controller.dart';
import '../../../shared/widgets/module_switcher.dart';
import '../../../../services/ad_service.dart';
import '../../../../services/url_handler_service.dart';
import '../../../shared/widgets/ads/banner_ad_tile.dart';
import '../../../shared/widgets/ads/rotating_banner_carousel.dart';
import '../../../../data/models/sponsored_content.dart';

class BuyerHomeView extends GetView<BuyerHomeController> {
  const BuyerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildHomeTab(),
    );
  }
    
  // Register the route for the settings/info page (if not already present)
  // Add this to your GetMaterialApp routes/pages list, typically in your main.dart or route config:
  // GetPage(
  //   name: '/app-info-seings',
  //   page: () => const AppInfoSettingsView(),
  // ),

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshData(),
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildTopBannerCarousel(),
          _buildSearchSection(),
          _buildDailyOfferSection(),
          // _buildBelowSearchBannerCarousel(),
          _buildFeaturedSellersSection(),
          _buildFeaturedProductsSection(),
          _buildCategoriesSection(),
        ],
      ),
    );
  }

  Widget _buildTopBannerCarousel() {
    final adService = Get.find<AdService>();
    
    return FutureBuilder<List<SponsoredContent>>(
      future: adService.getSponsoredForSlotSync(AdSlot.homeHeaderBanner, limit: 5),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? [];
        if (ads.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        
        // If only one ad, show banner tile; else carousel
        final widgetToShow = ads.length == 1
            ? BannerAdTile(
                ad: ads.first,
                height: 200, // Increased height
                onTap: () {
                  final ad = ads.first;
                  final externalUrl = ad.payload?['externalUrl'] as String?;
                  if (externalUrl != null) {
                    Get.find<UrlHandlerService>().handleCampaignUrl(externalUrl, payload: ad.payload);
                  } else if (ad.deeplinkRoute != null) {
                    Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                  }
                },
              )
            : RotatingBannerCarousel(
                items: ads,
                height: 200, // Increased height
                onTap: (ad) {
                  final externalUrl = ad.payload?['externalUrl'] as String?;
                  if (externalUrl != null) {
                    Get.find<UrlHandlerService>().handleCampaignUrl(externalUrl, payload: ad.payload);
                  } else if (ad.deeplinkRoute != null) {
                    Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                  }
                },
              );

        return SliverToBoxAdapter(child: widgetToShow);
      },
    );
  }

  // ignore: unused_element
  Widget _buildBelowSearchBannerCarousel() {
    final adService = Get.find<AdService>();
    
    return FutureBuilder<List<SponsoredContent>>(
      future: adService.getSponsoredForSlotSync(AdSlot.homeBelowSearchBanner, limit: 5),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? [];
        if (ads.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        
        final widgetToShow = ads.length == 1
            ? BannerAdTile(
                ad: ads.first,
                height: 180, // Increased height
                onTap: () {
                  final ad = ads.first;
                  final externalUrl = ad.payload?['externalUrl'] as String?;
                  if (externalUrl != null) {
                    Get.find<UrlHandlerService>().handleCampaignUrl(externalUrl, payload: ad.payload);
                  } else if (ad.deeplinkRoute != null) {
                    Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                  }
                },
              )
            : RotatingBannerCarousel(
                items: ads,
                height: 180, // Increased height
                onTap: (ad) {
                  if (ad.deeplinkRoute != null) {
                    Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                  }
                },
              );
        
        return SliverToBoxAdapter(child: widgetToShow);
      },
    );
  }
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: false,
      backgroundColor: Colors.white,
      elevation: 1,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 8,
          ),
          color: Colors.white,
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Discover Amazing',
                        style: Get.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Sellers at Istefada',
                        style: Get.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.buyerPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const ModuleSwitchButton(),
                IconButton(
                  icon: const Icon(
                    Icons.favorite_outline,
                    color: AppTheme.textPrimary,
                    size: 28,
                  ),
                  onPressed: () {
                    Get.toNamed('/buyer-favorites');
                  },
                  tooltip: 'Favorites',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: AppTheme.textPrimary,
                    size: 28,
                  ),
                  onPressed: () {
                    Get.toNamed('/app-info-settings');
                  },
                  tooltip: 'Settings',
                ),
                // IconButton(
                //   icon: const Icon(
                //     Icons.person_outline,
                //     color: AppTheme.textPrimary,
                //     size: 28,
                //   ),
                //   onPressed: () {
                //     Get.toNamed('/buyer-profile');
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Search Bar
            GestureDetector(
              onTap: () => Get.toNamed('/buyer-search'), // Navigate to search screen
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.buyerPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.buyerPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppTheme.buyerPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search for products, sellers...',
                      style: Get.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textHint,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.filter_list,
                      color: AppTheme.buyerPrimary,
                      size: 20,
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

  Widget _buildDailyOfferSection() {
    return SliverToBoxAdapter(
      child: Obx(() {
    final dailyCtrl = Get.isRegistered<DailyOfferController>()
      ? Get.find<DailyOfferController>()
      : Get.put(DailyOfferController(), permanent: true);
        if (!dailyCtrl.hasOffer.value) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.buyerPrimary.withOpacity(0.8),
                    const Color(0xFF6366F1).withOpacity(0.9),
                  ],
                ),
              ),
              child: InkWell(
                onTap: () => Get.toNamed('/daily-offer'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Exclusive Offer',
                              style: Get.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Special deals just for you',
                              style: Get.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Pending Badge (observe existing controller instance)
                      GetX<DailyOfferController>(builder: (controller) {
                        if (controller.hasOffer.value && !controller.isRedeemed.value) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PENDING',
                              style: Get.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturedSellersSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              'Featured Sellers',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: controller.featuredSellers.length,
              itemBuilder: (context, index) {
                final seller = controller.featuredSellers[index];
                return _buildFeaturedSellerCard(seller);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSellerCard(SponsoredContent seller) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            final sellerId = seller.payload?['sellerId'];
            if (sellerId != null) {
              controller.viewSeller(sellerId is int ? sellerId : int.tryParse(sellerId.toString()) ?? 0);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seller Image
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.shade200,
                ),
                child: seller.imageUrl != null && seller.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          seller.imageUrl!,
                          width: double.infinity,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                        ),
                      )
                    : _buildPlaceholderIcon(),
              ),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.title,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seller.subtitle ?? 'Featured',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              'Featured Products',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 240,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: controller.featuredProducts.length,
              itemBuilder: (context, index) {
                final product = controller.featuredProducts[index];
                return _buildFeaturedProductCard(product);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductCard(SponsoredContent product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            final productId = product.deeplinkRoute?.split('/').last;
            if (productId != null) {
              controller.viewProduct(int.tryParse(productId) ?? 0);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.shade200,
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.imageUrl!,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: AppTheme.buyerPrimary,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.shopping_bag,
                          size: 40,
                          color: AppTheme.buyerPrimary,
                        ),
                      ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.subtitle ?? 'Featured Product',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.ctaLabel ?? 'View',
                        style: Get.textTheme.labelSmall?.copyWith(
                          color: AppTheme.buyerPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.store,
        size: 40,
        color: AppTheme.buyerPrimary,
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              'Browse Categories',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // Grid view of categories
          Obx(() {
            final categories = controller.categories;
            if (categories.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryMaster category) {
    // Simple category icons mapping
    IconData getIconForCategory(String categoryName) {
      switch (categoryName.toLowerCase()) {
        case 'apparel':
          return Icons.checkroom;
        case 'jewelry':
          return Icons.diamond;
        case 'food & beverages':
          return Icons.restaurant;
        case 'art & crafts':
          return Icons.palette;
        case 'home decor':
          return Icons.home;
        case 'electronics':
          return Icons.devices;
        default:
          return Icons.category;
      }
    }

    final rawUrl = category.icon;
    String? iconUrl = rawUrl;
    if (iconUrl != null) {
      // If backend sent only a filename, prepend the S3 base path
      if (!iconUrl.contains('://')) {
        iconUrl = 'https://findmebiz-media.s3.us-east-1.amazonaws.com/icons/' + iconUrl;
      }
      // Encode spaces and unsafe characters in path to avoid 403/404 from S3
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

    return Container(
      // Fill available grid cell width
      width: double.infinity,
      // Spacing handled by GridView's crossAxisSpacing/mainAxisSpacing
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => controller.browseCategory(category.catid ?? 0, category.catname),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: (iconUrl != null && iconUrl.isNotEmpty)
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isSvg
              ? SvgPicture.network(
                iconUrl,
                fit: BoxFit.contain,
                placeholderBuilder: (ctx) => Center(
                                child: Icon(
                                  getIconForCategory(category.catname ),
                                  color: AppTheme.buyerPrimary,
                                  size: 24,
                                ),
                              ),
                            )
                          : Image.network(
                              iconUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, st) => Icon(
                                getIconForCategory(category.catname ),
                                color: AppTheme.buyerPrimary,
                                size: 24,
                              ),
                            ),
                    )
                  : Icon(
                      getIconForCategory(category.catname ),
                      color: AppTheme.buyerPrimary,
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


}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/api/index.dart';
import '../controllers/buyer_home_controller.dart';
import '../../../shared/widgets/module_switcher.dart';
import '../../../../services/ad_service.dart';
import '../../../../services/url_handler_service.dart';
import '../../../shared/widgets/ads/banner_ad_tile.dart';
import '../../../shared/widgets/ads/native_ad_card.dart';
import '../../../shared/widgets/ads/rotating_banner_carousel.dart';
import '../../../../data/models/sponsored_content.dart';
import '../../../../core/widgets/app_logo.dart';

class BuyerHomeView extends GetView<BuyerHomeController> {
  const BuyerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildHomeTab(),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshData(),
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildTopBannerCarousel(),
          _buildSearchSection(),
          _buildBelowSearchBannerCarousel(),
          _buildFeaturedSection(),
          _buildCategoriesSection(),
          _buildNewSellersSection(),
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
                    Icons.person_outline,
                    color: AppTheme.textPrimary,
                    size: 28,
                  ),
                  onPressed: () {
                    Get.toNamed('/buyer-profile');
                  },
                ),
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

  Widget _buildFeaturedSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Sellers',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See all',
                    style: TextStyle(color: AppTheme.buyerPrimary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: controller.featuredSellers.isEmpty ? 0 : controller.featuredSellers.length + 1,
              itemBuilder: (context, index) {
                // Deterministic: insert a single ad after the 3rd card if possible
                if (index == 3 && controller.featuredSellers.isNotEmpty) {
                  return FutureBuilder<List<SponsoredContent>>(
                    future: Get.find<AdService>().getSponsoredForSlotSync(AdSlot.homeFeatured),
                    builder: (context, snapshot) {
                      final ads = snapshot.data ?? [];
                      if (ads.isEmpty) return const SizedBox.shrink();
                      
                      final ad = ads.first;
                      return SizedBox(
                        width: 160,
                        child: NativeAdCard(
                          ad: ad,
                          onTap: () {
                            if (ad.deeplinkRoute != null) {
                              Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                            }
                          },
                        ),
                      );
                    },
                  );
                }
                if (controller.featuredSellers.isEmpty) {
                  return const SizedBox();
                }
                final dataIndex = index % controller.featuredSellers.length;
                final seller = controller.featuredSellers[dataIndex];
                return _buildFeaturedSellerCard(seller);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSellerCard(SellerDetails seller) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => controller.viewSeller(seller.sellerid ?? 0),
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
                child: Center(
                  child: Icon(
                    Icons.store,
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
                      seller.businessname ?? 'Business',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seller.area ?? 'Location',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.5', // Default rating since not in SellerDetails
                          style: Get.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
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
                            seller.city ?? 'Location',
                            style: Get.textTheme.labelSmall?.copyWith(
                              color: AppTheme.buyerPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
          SizedBox(
            height: 120,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return _buildCategoryCard(category);
              },
            )),
          ),
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

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
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
              child: Icon(
                getIconForCategory(category.catname ),
                color: AppTheme.buyerPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.catname ,
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

  Widget _buildNewSellersSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              'New Sellers',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Obx(() => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
            ),
            itemCount: controller.newSellers.length + 1, // one ad slot
            itemBuilder: (context, index) {
              // Deterministic: insert a single ad after the 4th tile if possible
              if (index == 4) {
                return FutureBuilder<List<SponsoredContent>>(
                  future: Get.find<AdService>().getSponsoredForSlotSync(AdSlot.homeNewSellers),
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
              if (index < controller.newSellers.length) {
                final seller = controller.newSellers[index];
                return _buildNewSellerTile(seller);
              }
              return const SizedBox.shrink();
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNewSellerTile(SellerDetails seller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.store,
            color: AppTheme.buyerPrimary,
          ),
        ),
        title: Text(
          seller.businessname ?? 'Business',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(seller.area ?? 'Location'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NEW',
                style: Get.textTheme.labelSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              seller.city ?? 'Location',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () => controller.viewSeller(seller.sellerid ?? 0),
      ),
    );
  }


}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/buyer_home_controller.dart';
import '../../../shared/widgets/module_switcher.dart';
import '../../../../services/ad_service.dart';
import '../../../shared/widgets/ads/banner_ad_tile.dart';
import '../../../shared/widgets/ads/native_ad_card.dart';
import '../../../../data/models/sponsored_content.dart';
import '../../../../core/widgets/app_logo.dart';

class BuyerHomeView extends GetView<BuyerHomeController> {
  const BuyerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWideWeb = kIsWeb && width >= 900;

    final Widget stackedTabs = Obx(() => IndexedStack(
          index: controller.currentIndex.value,
          children: [
            _buildHomeTab(),
            _buildSearchTab(),
            _buildEnquiryTab(),
            _buildMapTab(),
            _buildProfileTab(),
          ],
        ));

    if (isWideWeb) {
      // Instagram-like web layout: left sidebar + centered fixed-width content
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Row(
            children: [
              Obx(() => NavigationRail(
                    backgroundColor: Colors.white,
                    selectedIndex: controller.currentIndex.value,
                    onDestinationSelected: controller.changeTab,
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: AppLogo(size: 36),
                    ),
                    selectedIconTheme: IconThemeData(color: AppTheme.buyerPrimary),
                    selectedLabelTextStyle: TextStyle(
                      color: AppTheme.buyerPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search),
                        selectedIcon: Icon(Icons.search),
                        label: Text('Search'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.help_outline),
                        selectedIcon: Icon(Icons.help),
                        label: Text('Enquiry'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.map_outlined),
                        selectedIcon: Icon(Icons.map),
                        label: Text('Map'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Profile'),
                      ),
                    ],
                  )),
              const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: stackedTabs,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile/tablet: keep bottom navigation
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: stackedTabs,
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.buyerPrimary,
            unselectedItemColor: AppTheme.textHint,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.help_outline),
                label: 'Enquiry',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          )),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshData(),
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildSearchSection(),
          _buildHeaderAdBanner(),
          _buildFeaturedSection(),
          _buildCategoriesSection(),
          _buildNewSellersSection(),
        ],
      ),
    );
  }
  
  Widget _buildHeaderAdBanner() {
  final adService = Get.find<AdService>();
  // Show a single subtle banner header deterministically
  final ads = adService.getSponsoredForSlot(AdSlot.homeHeaderBanner);
  if (ads.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
  final ad = ads.first;
    return SliverToBoxAdapter(
      child: BannerAdTile(
        ad: ad,
        onTap: () {
          if (ad.deeplinkRoute != null) {
            Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
          }
        },
      ),
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
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.textPrimary,
                        size: 28,
                      ),
                      // Notification badge (mock)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // Navigate to notifications
                    Get.snackbar(
                      'Notifications',
                      'Opening notifications...',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    // In future: Get.toNamed('/buyer-notifications');
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search for products, sellers...',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textHint,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.filter_list,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/buyer-map'),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buyerPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/buyer-create-enquiry'),
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Post Enquiry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              
              ],
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
              itemCount: controller.featuredSellers.length + 1,
              itemBuilder: (context, index) {
                final adService = Get.find<AdService>();
                // Deterministic: insert a single ad after the 3rd card if possible
                if (index == 3) {
                  final ad = adService.getSponsoredForSlot(AdSlot.homeFeatured).first;
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

  Widget _buildFeaturedSellerCard(Map<String, dynamic> seller) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => controller.viewSeller(seller['id']),
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
                      seller['businessName'],
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seller['category'],
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
                          seller['rating'].toString(),
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
                            color: AppTheme.buyerPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            seller['stallNumber'],
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

  Widget _buildCategoryCard(String category) {
    // Simple category icons mapping
    IconData getIconForCategory(String category) {
      switch (category.toLowerCase()) {
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
        onTap: () => controller.browseCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.buyerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getIconForCategory(category),
                color: AppTheme.buyerPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
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
            itemCount: controller.newSellers.length + 1, // one subtle ad
            itemBuilder: (context, index) {
              final adService = Get.find<AdService>();
              // Deterministic: insert a single ad after the 4th tile if possible
              if (index == 4) {
                final ad = adService.getSponsoredForSlot(AdSlot.homeNewSellers).first;
                return NativeAdCard(
                  ad: ad,
                  onTap: () {
                    if (ad.deeplinkRoute != null) {
                      Get.toNamed(ad.deeplinkRoute!, arguments: ad.payload);
                    }
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

  Widget _buildNewSellerTile(Map<String, dynamic> seller) {
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
          seller['businessName'],
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(seller['category']),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
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
              seller['stallNumber'],
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () => controller.viewSeller(seller['id']),
      ),
    );
  }

  // Replace placeholder search tab with actual SearchView
  Widget _buildSearchTab() {
    return const Center(
      child: Text('Redirecting to Search...'),
    );
  }

  Widget _buildEnquiryTab() {
    return const Center(
      child: Text('Redirecting to Enquiry...'),
    );
  }

  Widget _buildMapTab() {
    return const Center(
      child: Text('Map Tab - Coming Soon'),
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Text('Redirecting to Profile...'),
    );
  }
}

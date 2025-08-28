import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../../products/widgets/products_sliver_widget.dart';
import '../../../shared/widgets/module_switcher.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../products/views/products_view.dart';

class SellerDashboardView extends GetView<SellerDashboardController> {
  const SellerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWideWeb = kIsWeb && width >= 900;

    if (isWideWeb) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Row(
            children: [
              Container(
                width: 80,
                color: Colors.grey[800],
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: AppLogo(size: 36),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.inventory_2,
                        color: AppTheme.buyerLight,
                      ),
                      title: Text(
                        'Products',
                        style: TextStyle(
                          color: AppTheme.buyerLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      dense: true,
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _buildDashboardContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: controller.addProduct,
          backgroundColor: AppTheme.primaryDark,
          child:  Icon(Icons.add, color: Colors.grey[800]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildDashboardContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addProduct,
        backgroundColor: const Color(0xFFC4DFAA),
        child:  Icon(Icons.add, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshData(),
      child: CustomScrollView(
        slivers: [
          _buildDashboardAppBar(),
          Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingCard();
            }
            return controller.isProfilePublished.value
                ? _buildPlanDetailsCard()
                : _buildProfileStatusCard();
          }),
          Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingStatsCards();
            }
            return _buildStatsCards();
          }),
          Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingQuickActions();
            }
            return _buildQuickActions();
          }),
          _buildProductsSectionHeader(),
          const ProductsCategoryFilterSliver(),
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            sliver: ProductsSliverWidget(
              isEmbedded: true,
              maxItems: 6,
              onViewAllPressed: () => Get.to(() => const ProductsView()),
            ),
          ),
          _buildViewAllProductsButton(),
          _buildBottomSpacing(),
        ],
      ),
    );
  }

  Widget _buildDashboardAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: false,
      backgroundColor: Colors.grey[800],
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
                        'Welcome back!',
                        style: Get.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Obx(() => Text(
                        controller.businessName.value,
                        style: Get.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      )),
                    ],
                  ),
                ),
                const ModuleSwitchButton(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatusCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
                  AppTheme.buyerPrimary.withValues(alpha: 0.5),
                AppTheme.buyerPrimary.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Completion',
                        style: Get.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        '${(controller.profileCompletion.value * 100).toInt()}%',
                        style: Get.textTheme.headlineLarge?.copyWith(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                
                  child:  Icon(
                    Icons.person_outline,
                    color: Colors.grey[800],
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => LinearProgressIndicator(
              value: controller.profileCompletion.value,
              backgroundColor: Colors.grey[800],
              valueColor:  AlwaysStoppedAnimation<Color>(Colors.grey[800]!),
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.editProfile,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:  Text(
                      'Edit Profile',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.publishProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF90C8AC),
                      foregroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Publish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        child: Row(
          children: [
            Expanded(child: _buildStatCard('Products', controller.totalProducts, Icons.inventory_2, const Color(0xFF73A9AD))),
            const SizedBox(width: 12),
            Expanded(child: _buildRatingStatCard('Rating', controller.averageRating, Icons.star, const Color(0xFF90C8AC))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Reviews', controller.totalReviews, Icons.reviews, const Color(0xFFC4DFAA))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, RxInt value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
              value.value.toString(),
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )),
            Text(
              title,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStatCard(String title, RxDouble value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
              value.value == 0.0 ? '-' : value.value.toStringAsFixed(1),
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )),
            Text(
              title,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Add Product',
                        Icons.add_box,
                        controller.addProduct,
                        const Color(0xFFC4DFAA),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Edit Profile',
                        Icons.edit,
                        controller.editProfile,
                        const Color(0xFF73A9AD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Reviews',
                        Icons.star,
                        () => Get.toNamed('/seller-reviews'),
                        const Color(0xFF90C8AC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.grey[800],
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Get.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSectionHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.defaultPadding, 
          24, 
          AppConstants.defaultPadding, 
          8
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'My Products',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              'Recent 6 items',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllProductsButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        child: OutlinedButton.icon(
          onPressed: () => Get.to(() => const ProductsView()),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('View All Products'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF73A9AD),
            side: const BorderSide(color: Color(0xFF73A9AD)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 28,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStatsCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        child: Row(
          children: [
            Expanded(child: _buildLoadingStatCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingStatCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingStatCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStatCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 24,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 16,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildLoadingQuickActionButton()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildLoadingQuickActionButton()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildLoadingQuickActionButton()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingQuickActionButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetailsCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor,
                  AppTheme.successColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Profile Published',
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your profile is live and visible to buyers',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.subscriptionPlanName.toUpperCase(),
                              style: Get.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${controller.subscriptionCurrency} ${controller.subscriptionAmount.toStringAsFixed(0)}',
                            style: Get.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (controller.subscriptionStartDate != null &&
                          controller.subscriptionEndDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${controller.subscriptionStartDate} - ${controller.subscriptionEndDate}',
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSpacing() {
    return const SliverToBoxAdapter(
      child: SizedBox(height: 80), // Space for floating action button
    );
  }
}

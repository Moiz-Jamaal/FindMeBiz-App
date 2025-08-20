import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../../products/views/products_view.dart';
import '../../../shared/widgets/module_switcher.dart';
import '../../../../core/widgets/app_logo.dart';

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
                color: Colors.white,
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
                        color: AppTheme.sellerPrimary,
                      ),
                      title: Text(
                        'Products',
                        style: TextStyle(
                          color: AppTheme.sellerPrimary,
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
          backgroundColor: AppTheme.sellerPrimary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildDashboardContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addProduct,
        backgroundColor: AppTheme.sellerPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshData(),
      child: CustomScrollView(
        slivers: [
          _buildDashboardAppBar(),
          _buildProfileStatusCard(),
          _buildStatsCards(),
          _buildProductsSection(),
        ],
      ),
    );
  }

  Widget _buildDashboardAppBar() {
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
                        'Welcome back!',
                        style: Get.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Obx(() => Text(
                        controller.businessName.value,
                        style: Get.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.sellerPrimary,
                        ),
                      )),
                    ],
                  ),
                ),
                const ModuleSwitchButton(),
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
          gradient: AppTheme.sellerGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sellerPrimary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        '${(controller.profileCompletion.value * 100).toInt()}%',
                        style: Get.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => LinearProgressIndicator(
              value: controller.profileCompletion.value,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.editProfile,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.publishProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.sellerPrimary,
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
            Expanded(child: _buildStatCard('Products', controller.totalProducts, Icons.inventory_2)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Views', controller.totalViews, Icons.visibility)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Contacts', controller.totalContacts, Icons.message)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, RxInt value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppTheme.sellerPrimary,
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              value.value.toString(),
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            )),
            Text(
              title,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'My Products',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.sellerPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Embed the ProductsView content here
          SizedBox(
            height: 600, // Fixed height for the products section
            child: const ProductsView(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
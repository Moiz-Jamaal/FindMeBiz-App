import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/buyer_profile_controller.dart';

class BuyerProfileView extends GetView<BuyerProfileController> {
  const BuyerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value && controller.buyer.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildStatsSection(),
              const SizedBox(height: 20),
              _buildMenuSections(),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: const Text(
        'Profile',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      actions: [
        Obx(() => IconButton(
          icon: Icon(
            controller.isEditing.value ? Icons.save : Icons.edit,
            color: AppTheme.buyerPrimary,
          ),
          onPressed: controller.toggleEditMode,
        )),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image
            Stack(
              children: [
                Obx(() => CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                  backgroundImage: controller.profileImagePath.value.isNotEmpty
                      ? AssetImage('assets/images/placeholder_profile.png') // Placeholder
                      : null,
                  child: controller.profileImagePath.value.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.buyerPrimary,
                        )
                      : null,
                )),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: controller.selectProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.buyerPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Name and Email
            Obx(() {
              if (controller.isEditing.value) {
                return Column(
                  children: [
                    TextField(
                      controller: controller.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Text(
                      controller.buyer.value?.fullname ?? 'User Name',
                      style: Get.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.buyer.value?.emailid ?? 'user@example.com',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (controller.buyer.value?.mobileno?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        controller.buyer.value!.mobileno!,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              controller.memberSince,
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Obx(() => _buildStatItem(
              'Favorites',
              '${controller.favoriteCount}',
              Icons.favorite,
              () => controller.viewFavorites(),
            )),
            Container(
              height: 50,
              width: 1,
              color: Colors.grey.shade300,
            ),
            Obx(() => _buildStatItem(
              'Reviews',
              '${controller.reviewsCount}',
              Icons.star,
              () => controller.viewReviews(),
            )),
            Container(
              height: 50,
              width: 1,
              color: Colors.grey.shade300,
            ),
            Obx(() => _buildStatItem(
              'Orders',
              '${controller.orderHistory}',
              Icons.shopping_bag,
              () => controller.viewOrderHistory(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.buyerPrimary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.buyerPrimary,
            ),
          ),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections() {
    return Column(
      children: [
        // Settings Section
        _buildMenuSection(
          title: 'Settings',
          items: [
            _buildMenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              trailing: Obx(() => Switch(
                value: controller.notificationsEnabled.value,
                onChanged: controller.updateNotificationSettings,
                activeColor: AppTheme.buyerPrimary,
              )),
            ),
            _buildMenuItem(
              icon: Icons.location_on,
              title: 'Location Services',
              trailing: Obx(() => Switch(
                value: controller.locationEnabled.value,
                onChanged: controller.updateLocationSettings,
                activeColor: AppTheme.buyerPrimary,
              )),
            ),
            _buildMenuItem(
              icon: Icons.language,
              title: 'Language',
              subtitle: controller.preferredLanguage.value,
              onTap: controller.changeLanguage,
            ),
            _buildMenuItem(
              icon: Icons.palette,
              title: 'Theme',
              subtitle: controller.theme.value,
              onTap: controller.changeTheme,
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Support Section
        _buildMenuSection(
          title: 'Support',
          items: [
            _buildMenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: controller.contactSupport,
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: controller.showPrivacyPolicy,
            ),
            _buildMenuItem(
              icon: Icons.description,
              title: 'Terms of Service',
              onTap: controller.showTermsOfService,
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Account Section
        _buildMenuSection(
          title: 'Account',
          items: [
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: controller.logout,
              textColor: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: Get.textTheme.bodyLarge?.copyWith(
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textHint,
                )
              : null),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/data/models/seller.dart';
import 'package:flutter/foundation.dart';
import 'package:souq/app/modules/buyer/product_view/views/buyer_product_view.dart' ;
import 'package:souq/core/widgets/enhanced_network_image.dart';
import 'package:souq/app/widgets/reviews/review_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/seller_profile_view_controller.dart';

// Error state widget for seller profile
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
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
}

class SellerProfileView extends GetView<SellerProfileViewController> {
  const SellerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        // Show error state if there's an error
        if (controller.hasError.value) {
          return ErrorStateWidget(
            title: 'Oops! Something went wrong',
            message: controller.errorMessage.value,
            onRetry: controller.retryLoading,
            icon: Icons.store_outlined,
          );
        }
        
        if (controller.isLoading.value && controller.seller.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.seller.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Unable to load seller profile'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => controller.loadSellerData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        return CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildProfileHeader(),
            _buildActionButtons(),
            _buildStallInfo(),
            _buildProductsSection(),
            _buildReviews(),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      pinned: true,
      title: Text(
        controller.seller.value?.businessName ?? '',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() => IconButton(
          icon: Icon(
            controller.isFavorite.value ? Icons.favorite : Icons.favorite_border,
            color: controller.isFavorite.value ? Colors.red : AppTheme.textSecondary,
          ),
          onPressed: controller.toggleFavorite,
        )),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'share':
                controller.shareProfile();
                break;
              case 'report':
                controller.reportProfile();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Share Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, size: 20),
                  SizedBox(width: 8),
                  Text('Report'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: () {
          final seller = controller.seller.value!;
          return Column(
            children: [
              // Profile Picture and Basic Info
              Row(
                children: [
                  // Profile Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.sellerGradient,
                      shape: BoxShape.circle,
                    ),
                    child: _buildSellerLogo(seller),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Products', '${controller.products.length}'),
                        Obx(() => _buildStatColumn('Rating', controller.averageRating.value.toStringAsFixed(1))),
                        Obx(() => _buildStatColumn('Reviews', '${controller.totalReviews.value}')),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Business Name and Owner
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.businessName,
                      style: Get.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${seller.fullName}',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bio
              if (seller.bio?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    seller.bio!,
                    style: Get.textTheme.bodyMedium,
                  ),
                ),
              ],
              
              // Social Media Links
              if (seller.socialMediaLinks.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSocialMediaLinks(seller.socialMediaLinks),
              ],
            ],
          );
        }(),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaLinks(List<String> links) {
    return Row(
      children: links.map((link) {
        if (link.startsWith('instagram:')) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.pink,
                ),
                const SizedBox(width: 4),
                Text(
                  link.substring(10), // Remove 'instagram:' prefix
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      }).toList(),
    );
  }
  Widget _buildActionButtons() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            // Contact Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: controller.contactSeller,
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.buyerPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Directions Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.getDirections,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.buyerPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStallInfo() {
    return SliverToBoxAdapter(
      child: () {
        final stallLocation = controller.seller.value?.stallLocation;
        if (stallLocation == null) return const SizedBox();
        return Container(
          margin: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppTheme.buyerPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stall Location',
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (stallLocation.stallNumber != null) ...[
                    _buildInfoRow('Stall Number', stallLocation.stallNumber!),
                    const SizedBox(height: 8),
                  ],
                  if (stallLocation.area != null) ...[
                    _buildInfoRow('Area', stallLocation.area!),
                    const SizedBox(height: 8),
                  ],
                  if (stallLocation.address != null) ...[
                    _buildInfoRow('Address', stallLocation.address!),
                  ],
                ],
              ),
            ),
          ),
        );
      }(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Get.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Products Header
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      color: AppTheme.buyerPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Products',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Obx(() => Text(
                      '${controller.filteredProducts.length} items',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    )),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Category Filter
                Obx(() => controller.sellerCategories.length > 2 // More than just "All"
                    ? _buildCategoryFilter()
                    : const SizedBox()),
                
                const SizedBox(height: 16),
                
                // Products Grid
                Obx(() => _buildProductsGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.sellerCategories.length,
        itemBuilder: (context, index) {
          final category = controller.sellerCategories[index];
          final isSelected = controller.selectedProductCategory.value == index;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => controller.filterProductsByCategory(index),
              selectedColor: AppTheme.buyerPrimary.withOpacity(0.2),
              checkmarkColor: AppTheme.buyerPrimary,
            ),
          );
        },
      )),
    );
  }

  Widget _buildProductsGrid() {
    final products = controller.filteredProducts;
    
    if (controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'No products available',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildSellerLogo(Seller seller) {
    if (seller.businessLogo != null && seller.businessLogo!.isNotEmpty) {
      return ClipOval(
        child: EnhancedNetworkImage(
          imageUrl: seller.businessLogo!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(40),
          errorWidget: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.sellerGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.store,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          placeholder: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.sellerGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Fallback to store icon
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppTheme.sellerGradient,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.store,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductImage(product) {
    // Check if product has images
    if (product.images != null && product.images.isNotEmpty) {
      final imageUrl = product.images.first;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading product image: $error');
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 32,
                  color: AppTheme.textHint,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.buyerPrimary),
                  ),
                ),
              ),
            );
          },
        );
      }
    }
    
    // Fallback placeholder
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image,
          size: 32,
          color: AppTheme.textHint,
        ),
      ),
    );
  }

  Widget _buildProductCard(product) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Handle different product ID types and ensure valid ID before navigation
          if (product?.id != null) {
            int? productId;
            if (product.id is int) {
              productId = product.id as int;
            } else if (product.id is String) {
              productId = int.tryParse(product.id as String);
            }
            
            if (productId != null && productId > 0) {
              controller.viewProduct(product);
            } else {
              Get.snackbar(
                'Error',
                'Invalid product information',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          }
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
                  child: _buildProductImage(product),
                ),
              ),
            ),
            
            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Get.textTheme.bodyMedium?.copyWith(
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
                          '₹${product.price!.toStringAsFixed(0)}',
                          style: Get.textTheme.bodyMedium?.copyWith(
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

    Widget _buildReviews() {
      return SliverToBoxAdapter(
        child: () {
          final seller = controller.seller.value;
          if (seller == null) return const SizedBox();
          
          final sellerId = int.tryParse(seller.id);
          if (sellerId == null) return const SizedBox();
          
          return Container(
            margin: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ReviewWidget(
                  refId: sellerId,
                  type: 'S',
                  entityName: seller.businessName,
                ),
              ),
            ),
          );
        }(),
      );
    }
  }

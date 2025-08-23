import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/core/widgets/enhanced_network_image.dart';
import 'package:souq/app/widgets/reviews/review_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

import '../controllers/buyer_product_view_controller.dart';

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

class BuyerProductView extends GetView<BuyerProductViewController> {
  const BuyerProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        // Show error state if there's an error
        if (controller.hasError.value) {
          return ErrorStateWidget(
            title: 'Oops! Something went wrong',
            message: controller.errorMessage.value,
            onRetry: controller.retryLoading,
            icon: Icons.shopping_bag_outlined,
          );
        }
        
        // Show loading if product is null and not in error state
        if (controller.product.value == null && controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildProductImages(),
            _buildProductInfo(),
            _buildSellerInfo(),
            _buildActionButtons(),
            _buildReviews(),
            _buildRelatedProducts(),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
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
        IconButton(
          icon: const Icon(Icons.share, color: AppTheme.textSecondary),
          onPressed: controller.shareProduct,
        ),
      ],
    );
  }

  Widget _buildProductImages() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 300,
        child: Obx(() {
          if (controller.productImages.isEmpty) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 80,
                  color: AppTheme.textHint,
                ),
              ),
            );
          }

          return Stack(
            children: [
              // Main Image
              PageView.builder(
                itemCount: controller.productImages.length,
                onPageChanged: controller.changeImage,
                itemBuilder: (context, index) {
                  final imageUrl = controller.productImages[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: EnhancedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              
              // Image Indicators
              if (controller.productImages.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      controller.productImages.length,
                      (index) => Obx(() => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.currentImageIndex.value == index
                              ? AppTheme.buyerPrimary
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      )),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProductInfo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Obx(() {
          final product = controller.product.value;
          if (product == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              Text(
                product.name,
                style: Get.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Category
              if (product.categories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.categories.first,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.buyerPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Price
              if (product.price != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Price: ',
                        style: Get.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${AppConstants.currency}${product.price!.toStringAsFixed(0)}',
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.buyerPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Description
              if (product.description?.isNotEmpty == true) ...[
                Text(
                  'Description',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                  product.description ?? '',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: controller.showFullDescription.value ? null : 3,
                  overflow: controller.showFullDescription.value 
                      ? null 
                      : TextOverflow.ellipsis,
                )),
                if ((product.description?.length ?? 0) > 150)
                  TextButton(
                    onPressed: controller.toggleDescription,
                    child: Obx(() => Text(
                      controller.showFullDescription.value 
                          ? 'Show less' 
                          : 'Show more',
                      style: const TextStyle(color: AppTheme.buyerPrimary),
                    )),
                  ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSellerInfo() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final seller = controller.seller.value;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller Information',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (seller != null) ...[
                    // Seller data available
                    Row(
                      children: [
                        // Seller Avatar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: seller.businessLogo != null && seller.businessLogo!.isNotEmpty
                              ? EnhancedNetworkImage(
                                  imageUrl: seller.businessLogo!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(8),
                                  errorWidget: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.sellerGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.store,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.sellerGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Seller Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seller.businessName,
                                style: Get.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                seller.fullName,
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (seller.stallLocation != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: AppTheme.textHint,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${seller.stallLocation!.area} • ${seller.stallLocation!.stallNumber}',
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
                        
                        // View Profile Button
                        TextButton(
                          onPressed: controller.viewSeller,
                          child: const Text(
                            'View Profile',
                            style: TextStyle(color: AppTheme.buyerPrimary),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Seller data not available - show fallback
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seller Information',
                                style: Get.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                'Loading seller details...',
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            // Contact Seller Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: controller.inquireAboutProduct,
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Contact Seller'),
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
            
            const SizedBox(width: 12),
            
            // Directions Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.getDirections,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.buyerPrimary,
                  side: const BorderSide(color: AppTheme.buyerPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
      child: Obx(() {
        final product = controller.product.value;
        if (product == null) return const SizedBox();
        
        final productId = int.tryParse(product.id);
        if (productId == null) return const SizedBox();
        
        return Container(
          margin: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ReviewWidget(
                refId: productId,
                type: 'P',
                entityName: product.name,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRelatedProducts() {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.relatedProducts.isEmpty) {
          return const SizedBox();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Text(
                'Related Products',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                itemCount: controller.relatedProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.relatedProducts[index];
                  return _buildRelatedProductCard(product);
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }

  Widget _buildRelatedProductCard(dynamic product) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => controller.viewRelatedProduct(product),
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
                    child: _buildRelatedProductImage(product),
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
                        style: Get.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      if (product.price != null)
                        Text(
                          '${AppConstants.currency}${product.price!.toStringAsFixed(0)}',
                          style: Get.textTheme.bodySmall?.copyWith(
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
      ),
    );
  }

  Widget _buildRelatedProductImage(dynamic product) {
    // Check if product has images from the media property
    if (product.media != null && product.media.isNotEmpty) {
      final imageUrl = product.media.first.mediaUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
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
                  width: 16,
                  height: 16,
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
    
    // Check if product has images array (fallback)
    if (product.images != null && product.images.isNotEmpty) {
      final imageUrl = product.images.first;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
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
                  width: 16,
                  height: 16,
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
    
    // Check primaryImageUrl property
    if (product.primaryImageUrl != null && product.primaryImageUrl.isNotEmpty && !product.primaryImageUrl.contains('placeholder')) {
      return Image.network(
        product.primaryImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
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
                width: 16,
                height: 16,
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
}

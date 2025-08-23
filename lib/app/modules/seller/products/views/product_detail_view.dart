import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/product_detail_controller.dart';

class ProductDetailView extends GetView<ProductDetailController> {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  controller.editProduct();
                  break;
                case 'share':
                  controller.shareProduct();
                  break;
                case 'delete':
                  controller.deleteProduct();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Product'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Product'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Product', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final product = controller.product.value;
        if (product == null) {
          return const Center(
            child: Text('Product not found'),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGallery(),
              _buildProductInfo(),
              _buildProductStats(),
              _buildActionButtons(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildImageGallery() {
    return Obx(() {
      final product = controller.product.value;
      if (product == null || product.images.isEmpty) {
        return Container(
          height: 200,
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(
              Icons.image,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
        );
      }

      return SizedBox(
        height: 300,
        child: PageView.builder(
          itemCount: product.images.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(product.images[index]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildProductInfo() {
    return Obx(() {
      final product = controller.product.value!;
      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name and Availability
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isAvailable
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: product.isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Category
            Row(
              children: [
                Icon(Icons.category, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  product.categories.isNotEmpty ? product.categories.first : 'No Category',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Price
            if (product.price != null) ...[
              Text(
                '₹${product.price!.toStringAsFixed(0)}',
                style: Get.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sellerPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Description
            if (product.description?.isNotEmpty == true) ...[
              Text(
                'Description',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description ?? '',
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // Dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _formatDate(product.createdAt),
                        style: Get.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Updated',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _formatDate(product.updatedAt),
                        style: Get.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProductStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Analytics',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Views',
                      '${controller.mockStats['views']}',
                      Icons.visibility,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Inquiries',
                      '${controller.mockStats['inquiries']}',
                      Icons.message,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Favorites',
                      '${controller.mockStats['favorites']}',
                      Icons.favorite,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Edit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.editProduct,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sellerPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Secondary Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.shareProduct,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.duplicateProduct,
                  icon: const Icon(Icons.copy),
                  label: const Text('Duplicate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}

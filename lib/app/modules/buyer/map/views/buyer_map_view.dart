import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/buyer_map_controller.dart';

class BuyerMapView extends GetView<BuyerMapController> {
  const BuyerMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Map Area
          _buildMapArea(),
          
          // Filters Panel
          Obx(() => controller.showFilters.value
              ? _buildFiltersPanel()
              : const SizedBox()),
          
          // Map Controls
          _buildMapControls(),
          
          // Seller Preview
          Obx(() => controller.showSellerPreview.value
              ? _buildSellerPreview()
              : const SizedBox()),
          
          // Filter Status
          _buildFilterStatus(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: const Text(
        'Seller Map',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() => Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.tune, color: AppTheme.textPrimary),
              onPressed: controller.toggleFilters,
            ),
            if (controller.activeFiltersCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.buyerPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${controller.activeFiltersCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        )),
        IconButton(
          icon: const Icon(Icons.my_location, color: AppTheme.textPrimary),
          onPressed: controller.centerOnUserLocation,
        ),
      ],
    );
  }

  Widget _buildMapArea() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return _buildInteractiveMap();
    });
  }

  Widget _buildInteractiveMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade100,
            Colors.green.shade200,
            Colors.green.shade100,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Grid pattern to simulate map
          CustomPaint(
            size: Size.infinite,
            painter: MapGridPainter(),
          ),
          
          // Seller pins
          ...controller.visibleSellers.map((seller) => 
            _buildSellerPin(seller)),
          
          // Center marker
          const Center(
            child: Icon(
              Icons.add,
              size: 20,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: strict_top_level_inference
  Widget _buildSellerPin(seller) {
    // Calculate pin position based on seller location
    // This is simplified - in real app, convert lat/lng to screen coordinates
    final random = seller.id.hashCode % 100;
    final left = 50 + (random * 3.0);
    final top = 100 + ((random * 2) % 400).toDouble();
    
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => controller.selectSeller(seller),
        child: Obx(() {
          final isSelected = controller.selectedSeller.value?.id == seller.id;
          final isFavorite = controller.isFavorite(seller.id);
          
          return AnimatedContainer(
            duration: AppConstants.shortAnimation,
            width: isSelected ? 50 : 40,
            height: isSelected ? 50 : 40,
            child: Stack(
              children: [
                // Pin background
                Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.buyerPrimary 
                        : AppTheme.sellerPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.store,
                    color: Colors.white,
                    size: isSelected ? 24 : 20,
                  ),
                ),
                
                // Favorite indicator
                if (isFavorite)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        children: [
          // Zoom In
          _buildMapControlButton(
            icon: Icons.add,
            onPressed: controller.zoomIn,
          ),
          const SizedBox(height: 8),
          
          // Zoom Out
          _buildMapControlButton(
            icon: Icons.remove,
            onPressed: controller.zoomOut,
          ),
          const SizedBox(height: 8),
          
          // Reset View
          _buildMapControlButton(
            icon: Icons.center_focus_strong,
            onPressed: controller.resetMapView,
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Icon(
            icon,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSellerPreview() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Obx(() {
        final seller = controller.selectedSeller.value;
        if (seller == null) return const SizedBox();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Business Logo/Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.sellerPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: AppTheme.sellerPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Business Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seller.businessName ,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (seller.stallLocation != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${seller.stallLocation!.area} • ${seller.stallLocation!.stallNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Favorite Button
                        IconButton(
                          icon: Icon(
                            controller.isFavorite(seller.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: controller.isFavorite(seller.id)
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () => controller.toggleFavorite(seller),
                        ),
                        
                        // Close Button
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: controller.deselectSeller,
                        ),
                      ],
                    ),
                    
                    if (seller.bio != null && seller.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        seller.bio!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: controller.viewSellerProfile,
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('View Profile'),
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
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: controller.contactSeller,
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('Contact'),
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
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.buyerPrimary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => controller.getDirectionsToSeller(seller),
                            icon: const Icon(
                              Icons.directions,
                              color: AppTheme.buyerPrimary,
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
        );
      }),
    );
  }

  Widget _buildFiltersPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Category Filter
            _buildFilterSection(
              title: 'Category',
              value: controller.selectedCategory.value,
              options: controller.categories,
              onChanged: controller.updateCategoryFilter,
            ),
            
            const SizedBox(height: 16),
            
            // Area Filter
            _buildFilterSection(
              title: 'Area',
              value: controller.selectedArea.value,
              options: controller.areas,
              onChanged: controller.updateAreaFilter,
            ),
            
            const SizedBox(height: 16),
            
            // Favorites Filter
            Row(
              children: [
                const Text(
                  'Show only favorites',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Obx(() => Switch(
                  value: controller.showOnlyFavorites.value,
                  onChanged: (_) => controller.toggleFavoritesFilter(),
                  activeColor: AppTheme.buyerPrimary,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = value == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.buyerPrimary
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterStatus() {
    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: Obx(() {
        if (controller.showFilters.value) return const SizedBox();
        
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            controller.filterStatusText,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }),
    );
  }
}

// Custom painter for map grid
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw grid lines
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
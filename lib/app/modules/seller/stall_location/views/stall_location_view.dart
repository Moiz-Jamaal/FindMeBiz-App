import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/constants/app_constants.dart';
import '../controllers/stall_location_controller.dart';

class StallLocationView extends GetView<StallLocationController> {
  const StallLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Select Stall Location'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Obx(() => TextButton(
            onPressed: controller.canSave ? controller.saveLocation : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: controller.canSave 
                    ? AppTheme.sellerPrimary 
                    : AppTheme.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          // Search and Actions Bar
          _buildSearchBar(),
          
          // Map Area
          Expanded(
            flex: 3,
            child: _buildMapArea(),
          ),
          
          // Location Details Form
          Expanded(
            flex: 2,
            child: _buildLocationForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Search Field
          TextFormField(
            controller: controller.searchTextController,
            decoration: InputDecoration(
              hintText: 'Search for location or area...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                if (controller.isLoading.value) {
                  return const SizedBox(
                    height: 18,
                    width: 18,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (controller.searchResults.isNotEmpty || controller.searchTextController.text.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clearSearch();
                    },
                  );
                }
                return const SizedBox.shrink();
              }),
            ),
            onChanged: (q) => controller.locationSearchQuery.value = q,
            onFieldSubmitted: (q) => controller.searchLocation(q, showToast: true),
          ),
          // Results List
          Obx(() {
            final results = controller.searchResults;
            if (results.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final item = results[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place, color: AppTheme.sellerPrimary),
                    title: Text(
                      (item['display_name'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => controller.selectSearchResult(item),
                  );
                },
              ),
            );
          }),
          
          const SizedBox(height: 12),
          
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.useCurrentLocation,
                  icon: const Icon(Icons.gps_fixed, size: 18),
                  label: const Text('Use Current'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sellerPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.resetToDefault,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildMapArea() {
    return Obx(() {
      final center = ll.LatLng(
        controller.selectedLatitude.value,
        controller.selectedLongitude.value,
      );
      final zoom = controller.currentZoom.value;
      return Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              onTap: (tapPosition, latLng) {
                controller.onMapTap(latLng.latitude, latLng.longitude);
              },
              onMapEvent: (evt) {
                if (evt is MapEventMoveEnd) {
                  // Keep zoom value in sync when user pinches
                  controller.currentZoom.value = evt.camera.zoom;
                }
              },
            ),
            mapController: controller.mapController,
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a','b','c'],
                userAgentPackageName: 'com.findmebiz.app',
              ),
              MarkerLayer(
                markers: [
                  if (controller.hasLocationSelected.value)
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.sellerPrimary,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Quick location buttons
          Positioned(
            top: 16,
            left: 16,
            child: _buildQuickLocations(),
          ),

          // Zoom Controls
          Positioned(
            right: 16,
            top: 16,
            child: _buildZoomControls(),
          ),

          // Location Info Overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildLocationInfoCard(),
          ),
        ],
      );
    });
  }

  Widget _buildQuickLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Quick Locations',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...controller.quickLocations.map((location) => 
          _buildQuickLocationButton(location)),
      ],
    );
  }

  Widget _buildQuickLocationButton(Map<String, dynamic> location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ElevatedButton(
        onPressed: () => controller.selectQuickLocation(location),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: AppTheme.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          location['name'],
          style: Get.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: controller.zoomIn,
            icon: const Icon(Icons.add),
            color: AppTheme.textPrimary,
          ),
          Container(
            width: 1,
            height: 1,
            color: Colors.grey.shade300,
          ),
          IconButton(
            onPressed: controller.zoomOut,
            icon: const Icon(Icons.remove),
            color: AppTheme.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfoCard() {
    return Obx(() => AnimatedContainer(
      duration: AppConstants.shortAnimation,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: controller.hasLocationSelected.value 
            ? AppTheme.sellerPrimary 
            : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            controller.hasLocationSelected.value 
                ? Icons.location_on 
                : Icons.location_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.selectedLocationText,
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (controller.hasLocationSelected.value)
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
        ],
      ),
    ));
  }
  Widget _buildLocationForm() {
    return Container(
      color: Colors.white,
      child: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Stall Details',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Stall Number
              TextFormField(
                controller: controller.stallNumberController,
                decoration: const InputDecoration(
                  labelText: 'Stall Number',
                  hintText: 'e.g., A-23, B-45',
                  prefixIcon: Icon(Icons.store),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              
              const SizedBox(height: 16),
              
              // Area/Section
              TextFormField(
                controller: controller.areaController,
                decoration: const InputDecoration(
                  labelText: 'Area/Section',
                  hintText: 'e.g., Food Court, Handicraft Zone',
                  prefixIcon: Icon(Icons.location_city),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                controller: controller.addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address *',
                  hintText: 'Complete address of your stall',
                  prefixIcon: Icon(Icons.place),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the stall address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5A4).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0EA5A4).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF0EA5A4),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map above to select your exact stall location. This helps buyers find you easily!',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF0B8584),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Save Button
              Obx(() => SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.canSave ? controller.saveLocation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sellerPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.textHint,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Stall Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// removed placeholder painter, using real map now

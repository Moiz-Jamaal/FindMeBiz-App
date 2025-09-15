import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/stall_location_controller.dart';

class StallLocationView extends GetView<StallLocationController> {
  const StallLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Select Business Location'),
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
                separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
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
                tileProvider: CancellableNetworkTileProvider(),
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
            color: Colors.black.withValues(alpha: 0.7),
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
          backgroundColor: Colors.white.withValues(alpha: 0.9),
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
            color: Colors.black.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.2),
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
                'Business Location Details',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Geolocation Section - matching onboarding and edit profile
              _buildGeolocationSection(),
              
              const SizedBox(height: 16),
              
              // Business Address
              TextFormField(
                controller: controller.addressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address *',
                  hintText: 'Complete address of your business',
                  prefixIcon: Icon(Icons.location_on),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the business address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Area/Section
              TextFormField(
                controller: controller.areaController,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  hintText: 'Local area or neighborhood',
                  prefixIcon: Icon(Icons.location_city),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // City and State Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'Enter city name',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        hintText: 'Enter state name',
                        prefixIcon: Icon(Icons.map),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Pincode
              TextFormField(
                controller: controller.pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  hintText: 'Enter 6-digit pincode',
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5A4).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0EA5A4).withValues(alpha: 0.2),
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
                        'Use "Get Location" to auto-fill address fields from your current location, or tap on the map to select a specific location.',
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
                          'Save Location',
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

  Widget _buildGeolocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sellerPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.sellerPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location,
                color: AppTheme.sellerPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Location',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.sellerPrimary,
                ),
              ),
              const Spacer(),
              Obx(() => controller.isGettingLocation.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.sellerPrimary,
                      ),
                    )
                  : GestureDetector(
                      onTap: controller.getCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sellerPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_searching,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Get Location',
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: controller.hasLocationSet
                    ? AppTheme.sellerPrimary.withValues(alpha: 0.3)
                    : AppTheme.textHint.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      controller.hasLocationSet
                          ? Icons.location_on
                          : Icons.location_off,
                      size: 16,
                      color: controller.hasLocationSet
                          ? AppTheme.sellerPrimary
                          : AppTheme.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.hasLocationSet
                          ? 'Location Set'
                          : 'No location set',
                      style: Get.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: controller.hasLocationSet
                            ? AppTheme.sellerPrimary
                            : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
                if (controller.hasLocationSet) ...[
                  const SizedBox(height: 6),
                  Text(
                    controller.currentLocationDisplay,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          )),
          const SizedBox(height: 8),
          Text(
            'Get your current location to auto-fill address fields and set your position on the map.',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// removed placeholder painter, using real map now

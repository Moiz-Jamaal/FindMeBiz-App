import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/theme/app_theme.dart';
import 'location_selector_controller.dart';

class LocationSelector extends StatelessWidget {
  final LocationSelectorController? controller;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final bool showMapByDefault;
  final bool showAddressForm;
  final VoidCallback? onLocationSelected;
  final GlobalKey<FormState>? formKey;

  const LocationSelector({
    super.key,
    this.controller,
    this.title = 'Select Location',
    this.subtitle = 'Choose your business location on the map',
    this.primaryColor = AppTheme.sellerPrimary,
    this.showMapByDefault = false,
    this.showAddressForm = true,
    this.onLocationSelected,
    this.formKey,
  });

  LocationSelectorController get _controller {
    return controller ?? Get.find<LocationSelectorController>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildCurrentLocationDisplay(),
          
          // Map Selection Section
          Obx(() => _controller.showMapSelection.value || showMapByDefault
              ? _buildMapSelectionSection()
              : const SizedBox()),
          
          // Address Form
          if (showAddressForm)
            _buildAddressForm(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Obx(() => ElevatedButton.icon(
          onPressed: _controller.isGettingLocation.value 
              ? null 
              : _controller.getCurrentLocation,
          icon: _controller.isGettingLocation.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 18),
          label: Text(
            _controller.isGettingLocation.value 
                ? 'Getting...' 
                : 'Current Location',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        )),
      ],
    );
  }

  Widget _buildCurrentLocationDisplay() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _controller.hasLocationSelected.value 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _controller.hasLocationSelected.value 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _controller.hasLocationSelected.value 
                ? Icons.check_circle 
                : Icons.location_off,
            color: _controller.hasLocationSelected.value 
                ? Colors.green 
                : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _controller.hasLocationSelected.value
                  ? 'Location Selected: ${_controller.currentLocationDisplay}'
                  : 'No location selected',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: _controller.hasLocationSelected.value 
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!showMapByDefault)
            TextButton.icon(
              onPressed: _controller.toggleMapSelection,
              icon: Icon(_controller.showMapSelection.value 
                  ? Icons.map_outlined 
                  : Icons.map),
              label: Text(_controller.showMapSelection.value 
                  ? 'Hide Map' 
                  : 'Show Map'),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildMapSelectionSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              _buildSearchBar(),
              
              // Search Results or Map
              Expanded(
                child: Obx(() {
                  final results = _controller.searchResults;
                  if (results.isNotEmpty) {
                    return _buildSearchResults(results);
                  }
                  return _buildMiniMap();
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller.searchTextController,
              decoration: InputDecoration(
                hintText: 'Search for a location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => _controller.searchResults.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _controller.clearSearch,
                      )
                    : const SizedBox()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => _controller.locationSearchQuery.value = value,
              onFieldSubmitted: (query) => _controller.searchLocation(query, showToast: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results) {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(
            result['display_name'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            _controller.selectSearchResult(result);
            onLocationSelected?.call();
          },
        );
      },
    );
  }

  Widget _buildMiniMap() {
    return Obx(() {
      final center = ll.LatLng(
        _controller.selectedLatitude.value,
        _controller.selectedLongitude.value,
      );
      final zoom = _controller.currentZoom.value;
      
      return Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              onTap: (tapPosition, point) {
                _controller.onMapTap(point.latitude, point.longitude);
                onLocationSelected?.call();
              },
            ),
            mapController: _controller.mapController,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.souq.app',
              ),
              MarkerLayer(
                markers: [
                  if (_controller.hasLocationSelected.value)
                    Marker(
                      width: 40,
                      height: 40,
                      point: center,
                      child: Icon(
                        Icons.location_on,
                        color: primaryColor,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Zoom Controls
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildZoomControls(),
          ),

          // Location Info
          if (_controller.hasLocationSelected.value)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Lat: ${_controller.selectedLatitude.value.toStringAsFixed(6)}\nLng: ${_controller.selectedLongitude.value.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      );
    });
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
            icon: const Icon(Icons.add),
            onPressed: _controller.zoomIn,
            color: primaryColor,
          ),
          Container(
            width: 32,
            height: 1,
            color: Colors.grey.shade300,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _controller.zoomOut,
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller.addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Enter complete address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controller.areaController,
                      decoration: const InputDecoration(
                        labelText: 'Area',
                        hintText: 'e.g., Ring Road',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _controller.cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'e.g., Surat',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controller.stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        hintText: 'e.g., Gujarat',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _controller.pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        hintText: 'e.g., 395007',
                        prefixIcon: Icon(Icons.pin_drop),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
                            return 'Enter valid 6-digit pincode';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

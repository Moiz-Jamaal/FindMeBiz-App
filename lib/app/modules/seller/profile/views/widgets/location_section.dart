import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/seller_profile_edit_controller.dart';

class LocationSection extends GetView<SellerProfileEditController> {
  const LocationSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Location',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Current Location Button
        Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: controller.hasLocationSet 
                ? Colors.green.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
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
                    color: controller.hasLocationSet 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.hasLocationSet 
                          ? 'Location Set' 
                          : 'No Location Set',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: controller.hasLocationSet 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: controller.isGettingLocation.value 
                        ? null 
                        : controller.getCurrentLocation,
                    icon: controller.isGettingLocation.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(
                      controller.isGettingLocation.value 
                          ? 'Getting...' 
                          : 'Use Current Location',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (controller.hasLocationSet) ...[
                const SizedBox(height: 8),
                Text(
                  controller.currentLocationDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        )),
        
        const SizedBox(height: 16),
        
        // Address Fields
        _buildAddressField(
          'Business Address',
          controller.addressController,
          'Enter your business address',
          maxLines: 2,
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildAddressField(
                'Area/Locality',
                controller.areaController,
                'e.g., Rajkot Road',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAddressField(
                'City',
                controller.cityController,
                'e.g., Ahmedabad',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildAddressField(
                'State',
                controller.stateController,
                'e.g., Gujarat',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAddressField(
                'PIN Code',
                controller.pincodeController,
                'e.g., 380001',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Location Benefits Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Setting your location helps customers find your business more easily on maps and in local searches.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}

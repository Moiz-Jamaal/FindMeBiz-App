import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

class ImagePickerWidget extends StatelessWidget {
  final List<String> images;
  final Function(String) onImageAdded;
  final Function(int) onImageRemoved;
  final int maxImages;
  final String emptyText;
  final double? height;

  const ImagePickerWidget({
    super.key,
    required this.images,
    required this.onImageAdded,
    required this.onImageRemoved,
    this.maxImages = 5,
    this.emptyText = 'Add Images',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 120,
      child: images.isEmpty ? _buildEmptyState() : _buildImageList(),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              emptyText,
              style: Get.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add images',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: images.length + (images.length < maxImages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == images.length) {
          // Add more button
          return _buildAddMoreButton();
        } else {
          // Image item
          return _buildImageItem(index);
        }
      },
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.primaryColor.withOpacity(0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                'Add More',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // Image container (placeholder for now)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 32,
                color: AppTheme.textHint,
              ),
            ),
          ),
          
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onImageRemoved(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Image Source',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    'Camera',
                    Icons.camera_alt,
                    () => _pickImage('camera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    'Gallery',
                    Icons.photo_library,
                    () => _pickImage('gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage(String source) {
    Get.back(); // Close bottom sheet
    
    // Placeholder for actual image picking
    // In a real app, this would use image_picker package
    String mockImagePath = 'mock_image_${DateTime.now().millisecondsSinceEpoch}';
    onImageAdded(mockImagePath);
    
    Get.snackbar(
      'Image Added',
      'Image from $source added successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

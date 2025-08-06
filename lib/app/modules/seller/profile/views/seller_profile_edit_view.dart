import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/seller_profile_edit_controller.dart';

class SellerProfileEditView extends GetView<SellerProfileEditController> {
  const SellerProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !controller.hasChanges.value,
      onPopInvoked: (didPop) {
        if (!didPop && controller.hasChanges.value) {
          controller.discardChanges();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar(),
        body: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCompletionCard(),
                const SizedBox(height: 20),
                _buildProfileImagesSection(),
                const SizedBox(height: 20),
                _buildBasicInfoSection(),
                const SizedBox(height: 20),
                _buildContactInfoSection(),
                const SizedBox(height: 20),
                _buildBusinessInfoSection(),
                const SizedBox(height: 20),
                _buildSocialMediaSection(),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
        floatingActionButton: _buildSaveButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Edit Profile'),
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (controller.hasChanges.value) {
            controller.discardChanges();
          } else {
            Get.back();
          }
        },
      ),
      actions: [
        Obx(() => controller.hasChanges.value
            ? TextButton(
                onPressed: controller.canSave ? controller.saveProfile : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: controller.canSave 
                        ? AppTheme.sellerPrimary 
                        : AppTheme.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const SizedBox()),
      ],
    );
  }
  Widget _buildProfileCompletionCard() {
    return Obx(() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.sellerPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile Completion',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(controller.profileCompletionPercentage * 100).toInt()}%',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sellerPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: controller.profileCompletionPercentage,
              backgroundColor: AppTheme.sellerPrimary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.sellerPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your profile to attract more buyers',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildProfileImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Images',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Profile Photo
                Expanded(
                  child: Column(
                    children: [
                      _buildImagePicker(
                        title: 'Profile Photo',
                        imagePath: controller.profileImage,
                        onImageSelected: controller.updateProfileImage,
                        onImageRemoved: controller.removeProfileImage,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Photo',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Business Logo
                Expanded(
                  child: Column(
                    children: [
                      _buildImagePicker(
                        title: 'Business Logo',
                        imagePath: controller.businessLogo,
                        onImageSelected: controller.updateBusinessLogo,
                        onImageRemoved: controller.removeBusinessLogo,
                        icon: Icons.business,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Business Logo',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required RxString imagePath,
    required Function(String) onImageSelected,
    required VoidCallback onImageRemoved,
    required IconData icon,
  }) {
    return Obx(() => GestureDetector(
      onTap: () => _showImageSourceDialog(onImageSelected),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: imagePath.value.isNotEmpty 
                ? AppTheme.sellerPrimary 
                : AppTheme.textHint,
            width: 2,
            style: imagePath.value.isEmpty 
                ? BorderStyle.solid 
                : BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: imagePath.value.isEmpty 
              ? AppTheme.sellerPrimary.withOpacity(0.1) 
              : Colors.grey.shade200,
        ),
        child: imagePath.value.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: AppTheme.sellerPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Photo',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppTheme.sellerPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 40,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image Added',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onImageRemoved,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
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
      ),
    ));
  }
  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.fullNameController,
              decoration: const InputDecoration(
                labelText: 'Your Full Name *',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.bioController,
              decoration: const InputDecoration(
                labelText: 'Business Description',
                hintText: 'Tell buyers about your business...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description),
                ),
              ),
              maxLines: 4,
              maxLength: AppConstants.maxBioLength,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(AppConstants.emailPattern).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.whatsappController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                hintText: '+91 98765 43210',
                prefixIcon: Icon(Icons.chat),
                helperText: 'Buyers will contact you on this number',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Business Location',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Get.toNamed('/seller-stall-location'),
                  icon: const Icon(Icons.location_on, size: 18),
                  label: const Text('Set Location'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.sellerPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sellerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.sellerPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.sellerPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stall Location',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.sellerPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Not set - Tap to add your stall location',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.sellerPrimary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSocialMediaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Media & Website',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help buyers find you on social media',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.instagramController,
              decoration: const InputDecoration(
                labelText: 'Instagram Handle',
                hintText: '@yourbusiness',
                prefixIcon: Icon(Icons.camera_alt),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook Page',
                hintText: 'Your Facebook page name',
                prefixIcon: Icon(Icons.facebook),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'https://yourwebsite.com',
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => controller.hasChanges.value
        ? FloatingActionButton.extended(
            onPressed: controller.canSave ? controller.saveProfile : null,
            backgroundColor: controller.canSave 
                ? AppTheme.sellerPrimary 
                : AppTheme.textHint,
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              controller.isLoading.value ? 'Saving...' : 'Save Changes',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : const SizedBox());
  }

  void _showImageSourceDialog(Function(String) onImageSelected) {
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
                    () => _pickImage('camera', onImageSelected),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    'Gallery',
                    Icons.photo_library,
                    () => _pickImage('gallery', onImageSelected),
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
              color: AppTheme.sellerPrimary,
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

  void _pickImage(String source, Function(String) onImageSelected) {
    Get.back(); // Close bottom sheet
    
    // Placeholder for actual image picking
    // In a real app, this would use image_picker package
    String mockImagePath = 'mock_image_${DateTime.now().millisecondsSinceEpoch}';
    onImageSelected(mockImagePath);
    
    Get.snackbar(
      'Image Selected',
      'Image from $source selected successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
    );
  }
}

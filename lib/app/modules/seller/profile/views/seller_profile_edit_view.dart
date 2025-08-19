import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/seller_profile_edit_controller.dart';

class SellerProfileEditView extends GetView<SellerProfileEditController> {
  const SellerProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Row(
              children: [
                Text(
                  'Business Logo',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (controller.businessLogoUrl.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Uploaded',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Business Logo only
            Center(
              child: _buildImagePicker(
                title: 'Business Logo',
                imagePath: controller.businessLogoUrl,
                onImageSelected: controller.updateBusinessLogo,
                onImageRemoved: controller.removeBusinessLogo,
                icon: Icons.business,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Obx(() => Text(
                controller.tempLogoPath.value.isNotEmpty 
                    ? 'Selected! Image is being uploaded...'
                    : controller.businessLogoUrl.value.isNotEmpty
                        ? 'Tap to change your business logo'
                        : 'Upload your business logo to build trust with buyers',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: controller.tempLogoPath.value.isNotEmpty 
                      ? AppTheme.sellerPrimary
                      : AppTheme.textSecondary,
                  fontWeight: controller.tempLogoPath.value.isNotEmpty 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              )),
            ),
            if (controller.isUploadingLogo.value) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.sellerPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.sellerPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Uploading logo...',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: AppTheme.sellerPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Debug info (remove in production)
            if (Get.isLogEnable) ...[
              const SizedBox(height: 8),
              Obx(() => Text(
                'Debug: Logo URL: ${controller.businessLogoUrl.value.isEmpty ? 'empty' : 'set'}, '
                'Temp: ${controller.tempLogoPath.value.isEmpty ? 'empty' : 'set'}, '
                'Uploading: ${controller.isUploadingLogo.value}',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required RxString imagePath,
    required VoidCallback onImageSelected,
    required VoidCallback onImageRemoved,
    required IconData icon,
  }) {
    return Obx(() {
      // Check if we have a temp local image or a network URL
      final hasImage = imagePath.value.isNotEmpty || controller.tempLogoPath.value.isNotEmpty;
      final isLocalImage = controller.tempLogoPath.value.isNotEmpty;
      final imageToShow = isLocalImage ? controller.tempLogoPath.value : imagePath.value;
      
      // Debug logging
      print('🎨 UI Update - hasImage: $hasImage, isLocalImage: $isLocalImage, imageToShow: $imageToShow');
      print('🎨 tempLogoPath: ${controller.tempLogoPath.value}');
      print('🎨 businessLogoUrl: ${imagePath.value}');
      
      return GestureDetector(
        onTap: onImageSelected,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: hasImage 
                  ? AppTheme.sellerPrimary 
                  : AppTheme.textHint,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
            color: !hasImage 
                ? AppTheme.sellerPrimary.withOpacity(0.1) 
                : Colors.grey.shade200,
          ),
          child: !hasImage
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
                    // Display the actual image (local or network)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: isLocalImage
                            ? Image.file(
                                File(imageToShow),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Local image load error: $error');
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        size: 32,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Load Error',
                                        style: Get.textTheme.bodySmall?.copyWith(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : Image.network(
                                imageToShow,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      color: AppTheme.sellerPrimary,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Network image load error: $error');
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        size: 32,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Load Error',
                                        style: Get.textTheme.bodySmall?.copyWith(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                    // Remove button
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
                    // Upload indicator overlay
                    if (controller.isUploadingLogo.value)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    // Local image indicator
                    if (isLocalImage && !controller.isUploadingLogo.value)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Selected',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildGeolocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sellerPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.sellerPrimary.withOpacity(0.2),
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
                    ? AppTheme.sellerPrimary.withOpacity(0.3)
                    : AppTheme.textHint.withOpacity(0.3),
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
            'Get your current location to auto-fill address fields and help buyers find you on the map.',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
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
              controller: controller.profileNameController,
              decoration: const InputDecoration(
                labelText: 'Profile Name *',
                prefixIcon: Icon(Icons.person),
                helperText: 'This will be your display name (no spaces)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Profile name is required';
                }
                if (value.trim().contains(' ')) {
                  return 'Profile name cannot contain spaces';
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
              controller: controller.contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_android),
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
            Text(
              'Business Location',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Geolocation Section
            _buildGeolocationSection(),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.addressController,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.establishedYearController,
              decoration: const InputDecoration(
                labelText: 'Established Year',
                prefixIcon: Icon(Icons.calendar_today),
                helperText: 'When was your business established?',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
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
            
            Obx(() {
              if (controller.isLoadingSocialMedia.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (controller.socialMediaPlatforms.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
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
                        Icons.link,
                        color: AppTheme.sellerPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No social media platforms available',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.sellerPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: controller.isDisposed ? [] : controller.socialMediaPlatforms.map((platform) {
                  final key = platform.smid.toString();
                  final controllerText = controller.socialControllers[key];
                  
                  // Safety check - don't render if controller is disposed
                  if (controller.isDisposed || controllerText == null) {
                    return const SizedBox.shrink();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSocialMediaField(
                      platform.sname,
                      controllerText,
                      _getIconForPlatform(platform.sname),
                      _getHintForPlatform(platform.sname),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaField(
    String platformName,
    TextEditingController? textController,
    IconData icon,
    String hint,
  ) {
    return TextFormField(
      controller: textController,
      decoration: InputDecoration(
        labelText: platformName.toUpperCase(),
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.sellerPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.sellerPrimary),
        ),
      ),
      keyboardType: TextInputType.url,
      textCapitalization: TextCapitalization.none,
    );
  }

  IconData _getIconForPlatform(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'youtube':
        return Icons.play_circle;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  String _getHintForPlatform(String platformName) {
    switch (platformName.toLowerCase()) {
      case 'instagram':
        return 'https://instagram.com/yourbusiness';
      case 'facebook':
        return 'https://facebook.com/yourbusiness';
      case 'twitter':
        return 'https://twitter.com/yourbusiness';
      case 'youtube':
        return 'https://youtube.com/c/yourbusiness';
      case 'website':
        return 'https://yourbusiness.com';
      default:
        return 'Enter your ${platformName.toLowerCase()} URL';
    }
  }

  Widget _buildSaveButton() {
    return Obx(() => controller.hasChanges.value
        ? FloatingActionButton.extended(
            onPressed: controller.canSave ? controller.saveProfile : null,
            backgroundColor: controller.canSave 
                ? AppTheme.sellerPrimary 
                : AppTheme.textHint,
            icon: controller.isSaving.value
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
              controller.isSaving.value ? 'Saving...' : 'Save Changes',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : const SizedBox());
  }
}

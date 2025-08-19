import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
                        imagePath: controller.profileImageUrl,
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
                        imagePath: controller.businessLogoUrl,
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
    required VoidCallback onImageSelected,
    required VoidCallback onImageRemoved,
    required IconData icon,
  }) {
    return Obx(() => GestureDetector(
      onTap: onImageSelected,
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
            
            Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Social Media Links',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.sellerPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Social media management will be available in the next update',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

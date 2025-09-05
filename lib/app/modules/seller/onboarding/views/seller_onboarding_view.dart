import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/api/category_master.dart';
import '../controllers/seller_onboarding_controller.dart';

class SellerOnboardingView extends GetView<SellerOnboardingController> {
  const SellerOnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Setup Your Seller Profile'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Obx(() => controller.currentStep.value > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: controller.previousStep,
              )
            : const SizedBox()),
        actions: [
          TextButton.icon(
            onPressed: () => Get.offAllNamed('/buyer-home'),
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('Back to Buyers'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.sellerPrimary,
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          
          // Content
          Expanded(
            child: Obx(() {
              // Explicitly access all observables that might be used in child widgets
              final currentStep = controller.currentStep.value;
              final isLoading = controller.isLoading.value;
              final availableCategories = controller.availableCategories.toList();
              final selectedCategories = controller.selectedCategories.toList();
              // Also read lengths to guarantee dependency tracking on RxList
              final _ = controller.availableCategories.length + controller.selectedCategories.length;

              Widget content;
              switch (currentStep) {
                case 0:
                  content = _buildBasicInfoStep();
                  break;
                case 1:
                  content = _buildContactStep();
                  break;
                case 2:
                  content = _buildBioStep(isLoading, availableCategories, selectedCategories);
                  break;
                case 3:
                  content = _buildCompletionStep();
                  break;
                default:
                  content = const SizedBox();
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: content,
              );
            }),
          ),
          
          // Bottom Navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Colors.white,
      child: Obx(() => Row(
        children: List.generate(4, (index) {
          final isActive = index <= controller.currentStep.value;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppTheme.sellerPrimary 
                    : AppTheme.sellerPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      )),
    );
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Form(
        key: controller.basicInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about your business',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This information will help buyers find and connect with you',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: controller.businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
                hintText: 'Enter your business name',
              ),
              validator: controller.businessNameValidator,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.profileNameController,
              decoration: const InputDecoration(
                labelText: 'Profile Name *',
                hintText: 'Enter a unique profile name',
              ),
              validator: controller.profileNameValidator,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Form(
        key: controller.contactInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buyers will use this to reach out to you',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: controller.contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                hintText: 'Enter your contact number',
              ),
              keyboardType: TextInputType.phone,
              validator: controller.contactValidator,
            ),
            
            const SizedBox(height: 16),
            
            // Geolocation Section
            _buildGeolocationSection(),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.addressController,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                hintText: 'Enter your business address',
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Enter your city',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioStep(bool isLoading, List<CategoryMaster> availableCategories, List<CategoryMaster> selectedCategories) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Form(
        key: controller.businessInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Categories',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select categories that best describe your business',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Categories selection - Use passed parameters instead of accessing controller
            isLoading 
                ? const Center(child: CircularProgressIndicator())
                : availableCategories.isEmpty
                    ? const Text('No categories available')
                    : _buildCategoriesGrid(availableCategories, selectedCategories),
            
            const SizedBox(height: 24),
            
            TextFormField(
              controller: controller.bioController,
              decoration: const InputDecoration(
                labelText: 'Business Description (Optional)',
                hintText: 'Describe your products, story, what makes you unique...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: AppConstants.maxBioLength,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(List<CategoryMaster> availableCategories, List<CategoryMaster> selectedCategories) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: availableCategories.map((category) {
        return FilterChip(
          label: Text(category.catname),
          selected: selectedCategories.contains(category),
          onSelected: (_) => controller.toggleCategory(category),
          selectedColor: const Color(0xFF0EA5A4).withValues(alpha: 0.2),
          checkmarkColor: const Color(0xFF0EA5A4),
        );
      }).toList(),
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.sellerPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: AppTheme.sellerPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Profile Setup Complete!',
            style: Get.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re all set! You can now add products and customize your profile further.',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            'Get your current location to auto-fill address fields and help buyers find you on the map.',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.2,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(() {
            // Ensure Obx depends on all needed observables
            final currentStep = controller.currentStep.value;
            final isSubmitting = controller.isSubmitting.value;
            
            // Compute canProceed directly here to ensure reactive dependencies
            bool canProceed;
            switch (currentStep) {
              case 0:
                canProceed = controller.businessName.value.trim().isNotEmpty && 
                           controller.profileName.value.trim().isNotEmpty;
                break;
              case 1:
                canProceed = true; // Contact info is optional
                break;
              case 2:
                canProceed = controller.selectedCategories.isNotEmpty;
                break;
              case 3:
                canProceed = true; // Final step - review
                break;
              default:
                canProceed = false;
            }

            return ElevatedButton(
              onPressed: canProceed
                  ? (currentStep == 3
                      ? controller.completeOnboarding
                      : controller.nextStep)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sellerPrimary,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      currentStep == 3 
                          ? 'Get Started' 
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            );
          }),
        ),
      ),
    );
  }
}

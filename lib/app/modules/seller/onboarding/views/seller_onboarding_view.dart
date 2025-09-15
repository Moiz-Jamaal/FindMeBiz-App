import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/api/category_master.dart';
import '../../../../shared/widgets/location_selector/index.dart';
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
              final currentStep = controller.currentStep.value;
              final isLoading = controller.isLoading.value;
              final availableCategories = controller.availableCategories.toList();
              final selectedCategories = controller.selectedCategories.toList();

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
                color: isActive ? AppTheme.sellerPrimary : Colors.grey.shade300,
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
              'Basic Information',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let\'s start with the basics of your business',
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
                prefixIcon: Icon(Icons.business),
              ),
              validator: controller.businessNameValidator,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.profileNameController,
              decoration: InputDecoration(
                labelText: 'Profile Name *',
                hintText: 'lowercase, no spaces (e.g., myshop)',
                prefixIcon: const Icon(Icons.person),
                helperText: 'This will be part of your public profile URL',
                suffixIcon: Obx(() {
                  if (controller.profileName.value.trim().isEmpty) return const SizedBox.shrink();
                  if (controller.isCheckingProfileName.value) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return Icon(
                    controller.isProfileNameAvailable.value ? Icons.check_circle : Icons.error_outline,
                    color: controller.isProfileNameAvailable.value ? Colors.green : Colors.red,
                  );
                }),
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
              'Help customers reach you easily',
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
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: controller.contactValidator,
            ),
            
            const SizedBox(height: 16),
            
            // Location Selector Section
            Builder(
              builder: (context) {
                try {
                  final locationController = Get.find<LocationSelectorController>(tag: 'onboarding_location');
                  return LocationSelector(
                    controller: locationController,
                    title: 'Business Location',
                    subtitle: 'Select your business location to help buyers find you',
                    primaryColor: AppTheme.sellerPrimary,
                    showMapByDefault: false,
                    showAddressForm: true,
                  );
                } catch (e) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(height: 8),
                        const Text('Location selector is loading...'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Re-initialize the controller
                            controller.onInit();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
              },
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
              'Business Details',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell customers about your business',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Categories selection
            Text(
              'Business Categories',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select categories that best describe your business',
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Category search
            TextField(
              controller: controller.categorySearchController,
              decoration: InputDecoration(
                hintText: 'Search categories',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
                  borderSide: const BorderSide(color: AppTheme.sellerPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Obx(() {
              final query = controller.categorySearchQuery.value.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? availableCategories
                  : availableCategories.where((c) => c.catname.toLowerCase().contains(query)).toList();

              return isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'No categories match your search',
                            style: Get.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                          ),
                        )
                      : _buildCategoriesGrid(filtered, selectedCategories);
            }),
            
            const SizedBox(height: 24),
            
            TextFormField(
              controller: controller.bioController,
              decoration: const InputDecoration(
              labelText: 'Product Catalog (Optional)',
              hintText: 'List your product names, key items, or descriptions to improve visibility in buyer search results...',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            
            const SizedBox(height: 24),
            
            TextFormField(
              controller: controller.establishedYearController,
              decoration: const InputDecoration(
                labelText: 'Established Year (Optional)',
                hintText: 'e.g., 2010',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              validator: controller.yearValidator,
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
        final isSelected = selectedCategories.contains(category);
        return FilterChip(
          label: Text(category.catname),
          selected: isSelected,
          onSelected: (_) => controller.toggleCategory(category),
          selectedColor: AppTheme.sellerPrimary.withValues(alpha: 0.2),
          checkmarkColor: AppTheme.sellerPrimary,
          backgroundColor: Colors.grey.shade100,
          side: BorderSide(
            color: isSelected ? AppTheme.sellerPrimary : Colors.grey.shade300,
          ),
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
            final currentStep = controller.currentStep.value;
            final isSubmitting = controller.isSubmitting.value;
            
      // Compute canProceed for each step
      bool canProceed;
            switch (currentStep) {
              case 0:
        canProceed = controller.canProceed;
                break;
              case 1:
                canProceed = controller.locationSelector.isValid;
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
              onPressed: canProceed && !isSubmitting
                  ? (currentStep == 3
                      ? controller.completeOnboarding
                      : controller.nextStep)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sellerPrimary,
                disabledBackgroundColor: Colors.grey.shade300,
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

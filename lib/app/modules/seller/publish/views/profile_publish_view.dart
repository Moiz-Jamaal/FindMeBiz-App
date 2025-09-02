import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/profile_publish_controller.dart';

class ProfilePublishView extends GetView<ProfilePublishController> {
  const ProfilePublishView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
  body: _buildStepContent(),
  bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Obx(() => Text(controller.stepTitle)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (controller.currentStep.value > 0) {
            controller.currentStep.value--;
          } else {
            Get.back();
          }
        },
      ),
    );
  }

  Widget _buildStepContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      switch (controller.currentStep.value) {
        case 0:
          return _buildPreviewStep();
        case 1:
          return _buildSuccessStep();
        default:
          return const SizedBox();
      }
    });
  }

  Widget _buildPreviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Description
          _buildStepHeader(),
          
          const SizedBox(height: 20),
          
          // Profile Completion Card
          _buildProfileCompletionCard(),
          
          const SizedBox(height: 20),
          
          // Validation Status Card
          Obx(() => controller.isProfileValid 
              ? const SizedBox() 
              : _buildValidationErrorsCard()),
          
          const SizedBox(height: 20),
          
          // Profile Preview Card
          _buildProfilePreviewCard(),
          
          const SizedBox(height: 20),
          
          // Publishing Benefits
          _buildBenefitsCard(),
          
          const SizedBox(height: 80), // Space for bottom navigation
        ],
      ),
    );
  }
  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.sellerPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.sellerPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.sellerPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Almost Ready!',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.sellerPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Review your profile and products before publishing. Once published, buyers will be able to discover and contact you.',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    return Card(
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
                Obx(() => Text(
                  '${(controller.profileCompletionScore * 100).toInt()}%',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sellerPrimary,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => LinearProgressIndicator(
              value: controller.profileCompletionScore,
              backgroundColor: AppTheme.sellerPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.sellerPrimary),
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.editProfile,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sellerPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.refreshProfileData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePreviewCard() {
    return Obx(() {
      final seller = controller.sellerProfile.value;
      if (seller == null) return const SizedBox();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Business Profile',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Business info
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.sellerPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppTheme.sellerPrimary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.businessname ?? 'Business Name',
                          style: Get.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seller.profilename ?? 'Profile Name',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (seller.bio?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  seller.bio!,
                  style: Get.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Contact info
              if (seller.whatsappno?.isNotEmpty == true)
                Row(
                  children: [
                    Icon(
                      Icons.chat,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      seller.whatsappno!,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }


  Widget _buildBenefitsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publishing Benefits',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildBenefitItem(
              Icons.visibility,
              'Visibility',
              'Your profile becomes visible to all event attendees',
            ),
            _buildBenefitItem(
              Icons.search,
              'Discoverability',
              'Buyers can find you through search and categories',
            ),
            _buildBenefitItem(
              Icons.location_on,
              'Map Presence',
              'Your stall appears on the interactive event map',
            ),
            _buildBenefitItem(
              Icons.chat,
              'Direct Contact',
              'Buyers can contact you directly via WhatsApp',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.sellerPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.sellerPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success Animation/Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppTheme.successColor,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Profile Published Successfully!',
            style: Get.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Your profile is now live and visible to all buyers at the Istefada event. They can find you, view your products, and contact you directly.',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Success Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'What happens next?',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSuccessItem(
                    Icons.visibility,
                    'Visible to Buyers',
                    'Your profile appears in search results and category listings',
                  ),
                  _buildSuccessItem(
                    Icons.location_on,
                    'On the Map',
                    'Your stall location is marked on the event map',
                  ),
                  _buildSuccessItem(
                    Icons.chat,
                    'Direct Contact',
                    'Buyers can contact you via WhatsApp and phone',
                  ),
                  _buildSuccessItem(
                    Icons.analytics,
                    'Track Performance',
                    'Monitor views, contacts, and engagement in your dashboard',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.previewAsbuyer,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View as Buyer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sellerPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.goToDashboard,
                  icon: const Icon(Icons.dashboard, size: 18),
                  label: const Text('Go to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sellerPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationErrorsCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Required Fields Missing',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...controller.validationErrors.map((error) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: controller.editProfile,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Complete Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ));
  }

  Widget _buildSuccessItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.successColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
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
          top: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: SafeArea(
        child: Obx(() {
          if (controller.currentStep.value == 0) {
            // Preview step - show publish button
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.canProceed && !controller.isPublishing.value
                    ? controller.publishProfile
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sellerPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.textHint,
                ),
                child: controller.isPublishing.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Publish Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          } else {
            // Success step - show navigation buttons
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.previewAsbuyer,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View as Buyer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sellerPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.goToDashboard,
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sellerPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}

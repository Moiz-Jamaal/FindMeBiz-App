import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/api/index.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
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
            'Your profile is now live and visible to buyers. To add products, subscribe to a plan below.',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Subscription Plans
          Obx(() {
            if (controller.availableSubscriptions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading subscription plans...',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Check if any subscription has invalid data
            final hasValidSubscription = controller.availableSubscriptions.any((sub) => 
              _getPlanPrice(sub) != 'Price unavailable'
            );
            
            if (!hasValidSubscription) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load subscription plans',
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your internet connection and try again later.',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => controller.loadSubscriptions(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.sellerPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return _buildSubscriptionPlans();
          }),
          
          const SizedBox(height: 24),
          
          // Payment Methods
          _buildPaymentMethods(),
          
          const SizedBox(height: 80), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Plan',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ...controller.availableSubscriptions.map((subscription) {
              final isSelected = controller.selectedSubscription.value?.subid == subscription.subid;
              final config = controller.subscriptionConfig;
              final amount = (config!['amount'] as num?)?.toDouble() ?? 250.0;
              final currency = config['currency'] as String? ?? 'INR';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => controller.selectSubscription(subscription),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.sellerPrimary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? AppTheme.sellerPrimary.withValues(alpha: 0.1) : null,
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: isSelected,
                          onChanged: (_) => controller.selectSubscription(subscription),
                          activeColor: AppTheme.sellerPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subscription.subname?.toUpperCase() ?? 'PLAN',
                                style: Get.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add unlimited products',
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _getPlanPrice(subscription),
                          style: Get.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sellerPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ...controller.paymentMethods.map((method) {
              final isSelected = controller.selectedPaymentMethod.value == method['id'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => controller.selectPaymentMethod(method['id']),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.sellerPrimary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? AppTheme.sellerPrimary.withValues(alpha: 0.1) : null,
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: isSelected,
                          onChanged: (_) => controller.selectPaymentMethod(method['id']),
                          activeColor: AppTheme.sellerPrimary,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          method['icon'],
                          color: AppTheme.sellerPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    method['name'],
                                    style: Get.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (method['recommended'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sellerPrimary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Recommended',
                                        style: Get.textTheme.bodySmall?.copyWith(
                                          color: AppTheme.sellerPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                method['description'],
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
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getPlanPrice(SubscriptionMaster subscription) {
    try {
      if (subscription.subconfig != null) {
        final config = jsonDecode(subscription.subconfig!);
        final amount = config['amount'];
        final currency = config['currency'];
        
        if (amount != null && currency != null) {
          return '$currency $amount';
        }
      }
    } catch (e) {
      // JSON parsing error - don't show fallback
    }
    return 'Price unavailable'; // Show error instead of fallback
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
            // Success step - show payment and dashboard buttons
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.goToDashboard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sellerPrimary,
                      side: BorderSide(color: AppTheme.sellerPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Skip for Now'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: controller.selectedSubscription.value != null && 
                               controller.subscriptionAmount != null &&
                               !controller.isProcessingPayment.value
                        ? controller.processPayment
                        : controller.selectedSubscription.value != null && 
                          controller.subscriptionAmount == null
                            ? () => Get.snackbar(
                                'Payment Error', 
                                'Unable to load subscription details. Please check your internet connection and try again.',
                                backgroundColor: Colors.red.withValues(alpha: 0.1),
                                colorText: Colors.red,
                              )
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sellerPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: controller.isProcessingPayment.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            controller.selectedSubscription.value != null
                                ? (controller.subscriptionAmount != null && controller.subscriptionCurrency != null
                                    ? 'Subscribe ${controller.subscriptionCurrency} ${controller.subscriptionAmount!.toStringAsFixed(0)}'
                                    : 'Payment Error - Try Again')
                                : 'Select a Plan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

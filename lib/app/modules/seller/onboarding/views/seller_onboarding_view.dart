import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
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
      ),
      body: Column(
        children: [
          // Progress Indicator
          Obx(() => _buildProgressIndicator()),
          
          // Content
          Expanded(
            child: Obx(() => _buildStepContent()),
          ),
          
          // Bottom Navigation
          Obx(() => _buildBottomNavigation()),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Colors.white,
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= controller.currentStep.value;
          final isCompleted = index < controller.currentStep.value;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppTheme.sellerPrimary 
                    : AppTheme.sellerPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (controller.currentStep.value) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildContactStep();
      case 2:
        return _buildBioStep();
      case 3:
        return _buildCompletionStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              hintText: 'Enter your business name',
            ),
            onChanged: controller.updateBusinessName,
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Your Full Name *',
              hintText: 'Enter your full name',
            ),
            onChanged: controller.updateFullName,
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
            decoration: const InputDecoration(
              labelText: 'Email Address *',
              hintText: 'Enter your email',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: controller.updateEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Your Business',
            style: Get.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell buyers what makes your business special (optional)',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Business Description',
              hintText: 'Describe your products, story, what makes you unique...',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: AppConstants.maxBioLength,
            onChanged: controller.updateBio,
          ),
        ],
      ),
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
              color: AppTheme.sellerPrimary.withOpacity(0.1),
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
          child: ElevatedButton(
            onPressed: controller.canProceed
                ? (controller.currentStep.value == 3
                    ? controller.completeOnboarding
                    : controller.nextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sellerPrimary,
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    controller.currentStep.value == 3 
                        ? 'Get Started' 
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

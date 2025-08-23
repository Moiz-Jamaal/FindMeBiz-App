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
      body: Obx(() => _buildStepContent()),
      bottomNavigationBar: Obx(() => _buildBottomNavigation()),
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
    if (controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (controller.currentStep.value) {
      case 0:
        return _buildPreviewStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
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
          
          // Profile Preview Card
          _buildProfilePreviewCard(),
          
          const SizedBox(height: 20),
          
          // Products Preview
          _buildProductsPreviewCard(),
          
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
                    onPressed: controller.previewAsbuyer,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Preview'),
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
  Widget _buildProductsPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Products',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Obx(() => Text(
                  '${controller.products.length} products',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            
            Obx(() => controller.products.isEmpty
                ? _buildNoProductsMessage()
                : _buildProductsList()),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: controller.addMoreProducts,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add More Products'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.sellerPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProductsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add at least one product to make your profile more attractive to buyers',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          final product = controller.products[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: Get.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
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
  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment Amount Card
          Card(
            color: AppTheme.sellerPrimary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Publishing Fee',
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${controller.subscriptionCurrency} ${controller.subscriptionAmount.toStringAsFixed(0)}',
                    style: Get.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One-time fee to make your profile visible',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Payment Methods
          Text(
            'Select Payment Method',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...controller.paymentMethods.map((method) => 
            _buildPaymentMethodCard(method)),
          
          const SizedBox(height: 20),
          
          // Payment Status
          Obx(() => _buildPaymentStatus()),
          
          const SizedBox(height: 80), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    return Obx(() => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => controller.selectPaymentMethod(method['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: controller.selectedPaymentMethod.value == method['id']
                      ? AppTheme.sellerPrimary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method['icon'],
                  color: controller.selectedPaymentMethod.value == method['id']
                      ? AppTheme.sellerPrimary
                      : AppTheme.textSecondary,
                ),
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
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (method['recommended'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Recommended',
                              style: Get.textTheme.labelSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method['description'],
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: method['id'],
                groupValue: controller.selectedPaymentMethod.value,
                onChanged: (value) {
                  if (value != null) {
                    controller.selectPaymentMethod(value);
                  }
                },
                activeColor: AppTheme.sellerPrimary,
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildPaymentStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: controller.paymentCompleted.value
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : controller.isProcessingPayment.value
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.paymentCompleted.value
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : controller.isProcessingPayment.value
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          if (controller.isProcessingPayment.value)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              controller.paymentCompleted.value
                  ? Icons.check_circle
                  : Icons.payment,
              color: controller.paymentCompleted.value
                  ? AppTheme.successColor
                  : AppTheme.textSecondary,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.paymentStatusMessage,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: controller.paymentCompleted.value
                    ? AppTheme.successColor
                    : AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
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
    if (controller.currentStep.value == 2) {
      return const SizedBox(); // No bottom nav on success page
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: controller.canProceed
                ? (controller.currentStep.value == 0
                    ? controller.proceedToPayment
                    : controller.processPayment)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sellerPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.textHint,
            ),
            child: controller.isProcessingPayment.value || controller.isPublishing.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    controller.currentStep.value == 0
                        ? 'Proceed to Payment'
                        : controller.paymentCompleted.value
                            ? 'Publishing...'
                            : 'Pay ${controller.subscriptionCurrency} ${controller.subscriptionAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

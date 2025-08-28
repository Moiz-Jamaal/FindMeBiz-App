import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_role.dart';
import '../controllers/welcome_controller.dart';

class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // App Logo and Title
              _buildHeader(),
              
              const SizedBox(height: 60),
              
              // Role Selection Cards
              Obx(() => AnimatedOpacity(
                opacity: controller.showRoleSelection.value ? 1.0 : 0.0,
                duration: AppConstants.longAnimation,
                child: _buildRoleSelection(),
              )),
              
              const SizedBox(height: 40),
              
              // Continue Button
              Obx(() => _buildContinueButton()),
              
              const SizedBox(height: 20),
              
              // Debug button (for development only)
              if (true) // Change to false for production
                TextButton(
                  onPressed: controller.clearAllAppData,
                  child: Text(
                    'Clear All Data (Debug)',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() => Column(
      children: [
        // App Icon
        const AppLogo(size: 100, radius: 50, padding: EdgeInsets.all(6)),
        
        const SizedBox(height: 24),
        
        // Welcome Text - different for logged in users
        Text(
          controller.userAlreadyLoggedIn.value 
              ? 'Welcome Back!' 
              : AppStrings.welcome,
          style: Get.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          controller.userAlreadyLoggedIn.value 
              ? 'Choose your preferred mode to continue'
              : AppStrings.welcomeSubtitle,
          style: Get.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ));
  }

  Widget _buildRoleSelection() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          controller.userAlreadyLoggedIn.value 
              ? 'Select Your Mode'
              : AppStrings.chooseRole,
          style: Get.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Seller Card
        _buildRoleCard(
          role: UserRole.seller,
          title: AppStrings.seller,
          description: AppStrings.sellerDescription,
          icon: Icons.store_mall_directory,
          gradient: AppTheme.sellerGradient,
          color: AppTheme.sellerPrimary,
        ),
        
        const SizedBox(height: 16),
        
        // Buyer Card
        _buildRoleCard(
          role: UserRole.buyer,
          title: AppStrings.buyer,
          description: AppStrings.buyerDescription,
          icon: Icons.shopping_bag,
          gradient: AppTheme.buyerGradient,
          color: AppTheme.buyerPrimary,
        ),
      ],
    ));
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required LinearGradient gradient,
    required Color color,
  }) {
    return Obx(() {
      final isSelected = controller.isRoleSelected(role);
      
      return AnimatedContainer(
        duration: AppConstants.shortAnimation,
        child: GestureDetector(
          onTap: () => controller.selectRole(role),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isSelected ? gradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              border: Border.all(
                color: isSelected ? Colors.transparent : color.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? color : Colors.grey).withValues(alpha: 0.1),
                  blurRadius: isSelected ? 15 : 5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.2) 
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: isSelected 
                              ? Colors.white.withValues(alpha: 0.9) 
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selection Indicator
                AnimatedContainer(
                  duration: AppConstants.shortAnimation,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? Colors.white 
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected 
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: color,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContinueButton() {
    final hasSelection = controller.selectedRole.value != null;
    final isLoading = controller.isLoading.value;
    
    return Obx(() => AnimatedOpacity(
      opacity: hasSelection ? 1.0 : 0.5,
      duration: AppConstants.shortAnimation,
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: hasSelection && !isLoading 
              ? controller.proceedWithRole 
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasSelection 
                ? (controller.selectedRole.value == UserRole.seller 
                    ? AppTheme.sellerPrimary 
                    : AppTheme.buyerPrimary)
                : AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
          ),
          child: isLoading 
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  controller.userAlreadyLoggedIn.value 
                      ? 'Continue'
                      : AppStrings.next,
                  style: Get.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ));
  }
}

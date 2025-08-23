import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/startup_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class StartupView extends GetView<StartupController> {
  const StartupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.store,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              AppConstants.appName,
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            const SizedBox(height: 16),
            
            // Loading text
            Obx(() => Text(
              controller.isInitialized.value 
                  ? 'Ready!' 
                  : 'Loading...',
              style: Get.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

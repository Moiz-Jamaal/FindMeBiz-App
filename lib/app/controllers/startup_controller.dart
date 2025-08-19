import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';
import '../data/models/user_role.dart';
import '../routes/app_pages.dart';

class StartupController extends GetxController {
  final RxBool isInitialized = false.obs;
  final RxString initialRoute = Routes.WELCOME.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 Initializing app...');
      
      // Wait a bit for services to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check authentication status
      final authService = Get.find<AuthService>();
      print('🔐 Auth status: ${authService.isLoggedIn}');
      
      if (authService.isLoggedIn) {
        // User is logged in, check their role and seller data
        final roleService = Get.find<RoleService>();
        
        // Re-check seller data from backend
        await roleService.checkSellerData();
        
        if (roleService.currentRole.value == UserRole.buyer) {
          initialRoute.value = Routes.BUYER_HOME;
          print('👤 Routing to buyer home');
        } else {
          // Seller role - check if data exists
          final route = roleService.getSellerRoute();
          initialRoute.value = route;
          print('🏪 Routing to seller: $route');
        }
      } else {
        // User not logged in
        initialRoute.value = Routes.WELCOME;
        print('👋 Routing to welcome');
      }
      
      isInitialized.value = true;
      
      // Navigate to the determined route
      Get.offAllNamed(initialRoute.value);
      
    } catch (e) {
      print('❌ Error during app initialization: $e');
      // Fallback to welcome
      initialRoute.value = Routes.WELCOME;
      isInitialized.value = true;
      Get.offAllNamed(Routes.WELCOME);
    }
  }
}

import 'package:get/get.dart';
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
      
      // Services should be ready now, but give a small delay for UI
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check authentication and role status
      final authService = Get.find<AuthService>();
      final roleService = Get.find<RoleService>();
      
      print('🔐 Auth status: ${authService.isLoggedIn}');
      print('📋 Has saved role: ${roleService.hasSavedRole}');
      print('👤 Current role: ${roleService.currentRole.value}');
      
      if (authService.isLoggedIn && roleService.hasSavedRole) {
        // User is logged in and has a saved role preference
        // Re-check seller data from backend
        await roleService.checkSellerData();
        
        if (roleService.currentRole.value == UserRole.buyer) {
          initialRoute.value = Routes.BUYER_HOME;
          print('👤 Routing to buyer home');
        } else {
          // Seller role - check if data exists to determine the correct route
          final route = roleService.getSellerRoute();
          initialRoute.value = route;
          print('🏪 Routing to seller: $route');
        }
      } else if (authService.isLoggedIn && !roleService.hasSavedRole) {
        // User is logged in but hasn't selected a role yet - go to welcome to select role
        initialRoute.value = Routes.WELCOME;
        print('❓ User logged in but no role selected - routing to welcome');
      } else {
        // User not logged in
        initialRoute.value = Routes.WELCOME;
        print('👋 User not logged in - routing to welcome');
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

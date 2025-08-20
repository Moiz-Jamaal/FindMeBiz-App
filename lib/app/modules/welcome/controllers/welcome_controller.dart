import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_role.dart';
import '../../../services/role_service.dart';
import '../../../services/auth_service.dart';

class WelcomeController extends GetxController {
  // Selected role
  final Rx<UserRole?> selectedRole = Rx<UserRole?>(null);
  
  // Animation and UI state
  final RxBool isLoading = false.obs;
  final RxBool showRoleSelection = false.obs;
  final RxBool userAlreadyLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkUserStatus();
    // Trigger animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      showRoleSelection.value = true;
    });
  }

  void _checkUserStatus() {
    final authService = Get.find<AuthService>();
    final roleService = Get.find<RoleService>();
    
    userAlreadyLoggedIn.value = authService.isLoggedIn;
    
    // If user is logged in and has a saved role, pre-select it
    if (authService.isLoggedIn && roleService.hasSavedRole) {
      selectedRole.value = roleService.currentRole.value;
    }
  }

  void selectRole(UserRole role) {
    selectedRole.value = role;
  }

  void clearSelection() {
    selectedRole.value = null;
  }

  void proceedWithRole() async {
    if (selectedRole.value == null) return;
    
    isLoading.value = true;
    
    final authService = Get.find<AuthService>();
    final roleService = Get.find<RoleService>();
    
    // If user is already logged in, directly switch role and navigate
    if (authService.isLoggedIn) {
      try {
        // Persist the role and navigate
        await roleService.switchTo(selectedRole.value!);
        isLoading.value = false;
      } catch (e) {
        
        isLoading.value = false;
        Get.snackbar('Error', 'Failed to switch role. Please try again.');
      }
    } else {
      // User not logged in, proceed to auth screen
      // Simulate navigation delay for smooth UX
      Future.delayed(const Duration(milliseconds: 800), () {
        isLoading.value = false;
        // Set the role temporarily but don't persist yet (will persist after auth)
        roleService.setRoleTemporary(selectedRole.value!);
        
        // If picking seller first time, ensure we mark sellerOnboarded=false
        if (selectedRole.value == UserRole.seller) {
          roleService.sellerOnboarded = false;
        }
        
        // Navigate to auth screen
        Get.toNamed('/auth');
      });
    }
  }

  // Helper method to check if role is selected
  bool isRoleSelected(UserRole role) {
    return selectedRole.value == role;
  }

  // Debug method to clear all app data (for testing)
  void clearAllAppData() async {
    final authService = Get.find<AuthService>();
    await authService.clearAllData();
    
    Get.snackbar(
      'Debug', 
      'All app data cleared. Please restart the app.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
}

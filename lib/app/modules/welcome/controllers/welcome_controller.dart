import 'package:get/get.dart';
import '../../../data/models/user_role.dart';

class WelcomeController extends GetxController {
  // Selected role
  final Rx<UserRole?> selectedRole = Rx<UserRole?>(null);
  
  // Animation and UI state
  final RxBool isLoading = false.obs;
  final RxBool showRoleSelection = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Trigger animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      showRoleSelection.value = true;
    });
  }

  void selectRole(UserRole role) {
    selectedRole.value = role;
  }

  void clearSelection() {
    selectedRole.value = null;
  }

  void proceedWithRole() {
    if (selectedRole.value == null) return;
    
    isLoading.value = true;
    
    // Simulate navigation delay for smooth UX
    Future.delayed(const Duration(milliseconds: 800), () {
      isLoading.value = false;
      
      switch (selectedRole.value!) {
        case UserRole.seller:
          Get.offAllNamed('/seller-onboarding');
          break;
        case UserRole.buyer:
          Get.offAllNamed('/buyer-home');
          break;
      }
    });
  }

  // Helper method to check if role is selected
  bool isRoleSelected(UserRole role) {
    return selectedRole.value == role;
  }
}

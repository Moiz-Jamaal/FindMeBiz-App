import 'package:get/get.dart';
import '../../../../services/role_service.dart';

class SellerOnboardingController extends GetxController {
  // Current step in onboarding process
  final RxInt currentStep = 0.obs;
  
  // Form data
  final RxString businessName = ''.obs;
  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString bio = ''.obs;
  
  // UI state
  final RxBool isLoading = false.obs;


  void nextStep() {
    if (currentStep.value < 3) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void updateBusinessName(String value) {
    businessName.value = value;
  }

  void updateFullName(String value) {
    fullName.value = value;
  }

  void updateEmail(String value) {
    email.value = value;
  }

  void updateBio(String value) {
    bio.value = value;
  }

  void completeOnboarding() {
    isLoading.value = true;
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
  // Mark seller as onboarded for future quick switches
  Get.find<RoleService>().sellerOnboarded = true;
      Get.offAllNamed('/seller-dashboard');
    });
  }

  bool get canProceed {
    switch (currentStep.value) {
      case 0:
        return businessName.value.isNotEmpty && fullName.value.isNotEmpty;
      case 1:
        return email.value.isNotEmpty;
      case 2:
        return true; // Bio is optional
      case 3:
        return true; // Final step
      default:
        return false;
    }
  }
}

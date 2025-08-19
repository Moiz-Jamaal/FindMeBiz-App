import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../routes/app_pages.dart';
import '../data/models/user_role.dart';
import 'auth_service.dart';
import 'seller_service.dart';

class RoleService extends GetxService {
  static const _storageKey = 'current_user_role';
  static const _sellerOnboardedKey = 'seller_onboarded';

  final Rx<UserRole> currentRole = UserRole.buyer.obs;
  final RxBool sellerDataExists = false.obs;
  final box = GetStorage();

  Future<RoleService> init() async {
    final saved = box.read<String>(_storageKey);
    if (saved != null) {
      try {
        currentRole.value = UserRoleExtension.fromString(saved);
      } catch (_) {
        currentRole.value = UserRole.buyer;
      }
    }
    
    // Check for actual seller data if user is logged in
    await _checkSellerData();
    
    return this;
  }

  bool get sellerOnboarded => box.read<bool>(_sellerOnboardedKey) ?? false;
  set sellerOnboarded(bool v) => box.write(_sellerOnboardedKey, v);

  bool get hasSavedRole => box.hasData(_storageKey);

  /// Check if seller data exists in backend (public method)
  Future<void> checkSellerData() async {
    await _checkSellerData();
  }

  /// Check if seller data exists in backend
  Future<void> _checkSellerData() async {
    try {
      final authService = Get.find<AuthService>();
      if (authService.isLoggedIn && authService.currentUser?.userid != null) {
        final sellerService = Get.find<SellerService>();
        final response = await sellerService.getSellerByUserId(authService.currentUser!.userid!);
        
        if (response.success && response.data != null) {
          sellerDataExists.value = true;
          sellerOnboarded = true; // Update local flag
          print('✅ Seller data exists for user ${authService.currentUser!.username}');
        } else {
          sellerDataExists.value = false;
          sellerOnboarded = false; // Update local flag
          print('ℹ️ No seller data found for user ${authService.currentUser!.username}');
        }
      } else {
        sellerDataExists.value = false;
        print('ℹ️ No logged in user to check seller data');
      }
    } catch (e) {
      print('❌ Error checking seller data: $e');
      sellerDataExists.value = false;
    }
  }

  /// Get the correct route for seller based on data existence
  String getSellerRoute() {
    if (sellerDataExists.value || sellerOnboarded) {
      return Routes.SELLER_DASHBOARD;
    } else {
      return Routes.SELLER_ONBOARDING;
    }
  }

  Future<void> switchTo(UserRole role) async {
    if (currentRole.value == role) return;
    
    currentRole.value = role;
    await box.write(_storageKey, role.value);
    
    print('💾 Role saved to storage: ${role.value}');

    // Navigate to the correct root for the role
    if (role == UserRole.buyer) {
      Get.offAllNamed(Routes.BUYER_HOME);
    } else {
      // Check seller data before deciding route
      await _checkSellerData();
      Get.offAllNamed(getSellerRoute());
    }
  }

  /// Set role without navigation (for temporary role setting)
  Future<void> setRoleTemporary(UserRole role) async {
    currentRole.value = role;
    // Don't persist to storage yet
    print('🔄 Role set temporarily: ${role.value}');
  }

  /// Persist the current role to storage
  Future<void> persistCurrentRole() async {
    await box.write(_storageKey, currentRole.value.value);
    print('💾 Role persisted to storage: ${currentRole.value.value}');
  }

  Future<void> toggle() => switchTo(
        currentRole.value == UserRole.buyer ? UserRole.seller : UserRole.buyer,
      );

  /// Call this after successful seller onboarding
  void markSellerOnboarded() {
    sellerOnboarded = true;
    sellerDataExists.value = true;
  }

  /// Call this when user logs out
  void clearSellerData() {
    sellerOnboarded = false;
    sellerDataExists.value = false;
    box.remove(_sellerOnboardedKey);
  }

  /// Clear all role data (when switching accounts or resetting)
  void clearAllRoleData() {
    currentRole.value = UserRole.buyer; // Reset to default
    box.remove(_storageKey);
    clearSellerData();
    print('🧹 All role data cleared');
  }
}

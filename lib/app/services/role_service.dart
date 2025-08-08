import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../routes/app_pages.dart';
import '../data/models/user_role.dart';

class RoleService extends GetxService {
  static const _storageKey = 'current_user_role';
  static const _sellerOnboardedKey = 'seller_onboarded';

  final Rx<UserRole> currentRole = UserRole.buyer.obs;
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
    return this;
  }

  bool get sellerOnboarded => box.read<bool>(_sellerOnboardedKey) ?? false;
  set sellerOnboarded(bool v) => box.write(_sellerOnboardedKey, v);

  bool get hasSavedRole => box.hasData(_storageKey);

  Future<void> switchTo(UserRole role) async {
    if (currentRole.value == role) return;
    currentRole.value = role;
    await box.write(_storageKey, role.value);

    // Navigate to the correct root for the role
    if (role == UserRole.buyer) {
      Get.offAllNamed(Routes.BUYER_HOME);
    } else {
      // If seller hasn't onboarded yet, route to onboarding
      if (sellerOnboarded) {
        Get.offAllNamed(Routes.SELLER_DASHBOARD);
      } else {
        Get.offAllNamed(Routes.SELLER_ONBOARDING);
      }
    }
  }

  Future<void> toggle() => switchTo(
        currentRole.value == UserRole.buyer ? UserRole.seller : UserRole.buyer,
      );
}

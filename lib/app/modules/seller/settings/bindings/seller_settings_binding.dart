import 'package:get/get.dart';
import '../controllers/seller_settings_controller.dart';

class SellerSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerSettingsController>(
      () => SellerSettingsController(),
    );
  }
}

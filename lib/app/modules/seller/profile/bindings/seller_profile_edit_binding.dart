import 'package:get/get.dart';
import '../controllers/seller_profile_edit_controller.dart';

class SellerProfileEditBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.find to get existing instance or create if not exists
    try {
      Get.find<SellerProfileEditController>();
    } catch (e) {
      Get.put<SellerProfileEditController>(
        SellerProfileEditController(),
        permanent: true,
      );
    }
  }
}

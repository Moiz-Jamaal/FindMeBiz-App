import 'package:get/get.dart';
import '../controllers/seller_profile_edit_controller.dart';

class SellerProfileEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerProfileEditController>(
      () => SellerProfileEditController(),
    );
  }
}

import 'package:get/get.dart';
import '../controllers/buyer_profile_controller.dart';

class BuyerProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerProfileController>(
      () => BuyerProfileController(),
    );
  }
}

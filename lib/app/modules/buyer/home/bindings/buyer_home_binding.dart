import 'package:get/get.dart';
import '../controllers/buyer_home_controller.dart';

class BuyerHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerHomeController>(
      () => BuyerHomeController(),
    );
  }
}

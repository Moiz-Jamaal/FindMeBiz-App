import 'package:get/get.dart';
import '../controllers/buyer_map_controller.dart';

class BuyerMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerMapController>(
      () => BuyerMapController(),
    );
  }
}

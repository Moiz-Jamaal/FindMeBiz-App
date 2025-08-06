import 'package:get/get.dart';
import '../controllers/advertising_controller.dart';

class AdvertisingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdvertisingController>(
      () => AdvertisingController(),
    );
  }
}
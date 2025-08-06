import 'package:get/get.dart';
import '../controllers/stall_location_controller.dart';

class StallLocationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StallLocationController>(
      () => StallLocationController(),
    );
  }
}

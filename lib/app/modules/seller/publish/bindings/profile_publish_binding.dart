import 'package:get/get.dart';
import '../controllers/profile_publish_controller.dart';

class ProfilePublishBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfilePublishController>(
      () => ProfilePublishController(),
    );
  }
}

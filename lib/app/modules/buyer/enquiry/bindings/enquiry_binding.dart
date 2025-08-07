import 'package:get/get.dart';
import '../controllers/enquiry_controller.dart';

class EnquiryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EnquiryController>(
      () => EnquiryController(),
    );
  }
}

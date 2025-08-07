import 'package:get/get.dart';
import '../controllers/seller_enquiry_controller.dart';

class SellerEnquiryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerEnquiryController>(
      () => SellerEnquiryController(),
    );
  }
}

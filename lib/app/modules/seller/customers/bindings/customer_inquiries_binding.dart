import 'package:get/get.dart';
import '../controllers/customer_inquiries_controller.dart';

class CustomerInquiriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerInquiriesController>(() => CustomerInquiriesController());
  }
}

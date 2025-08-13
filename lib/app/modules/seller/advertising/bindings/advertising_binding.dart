import 'package:get/get.dart';
import '../controllers/advertising_controller.dart';
import '../../../../services/payment_service.dart';

class AdvertisingBinding extends Bindings {
  @override
  void dependencies() {
    // Payment service
    if (!Get.isRegistered<PaymentService>()) {
      Get.put<PaymentService>(RazorpayPaymentService(), permanent: true);
    }
    Get.lazyPut<AdvertisingController>(
      () => AdvertisingController(),
    );
  }
}
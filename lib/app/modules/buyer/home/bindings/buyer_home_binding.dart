import 'package:get/get.dart';
import '../controllers/buyer_home_controller.dart';
import '../../../../services/ad_service.dart';

class BuyerHomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdService>()) {
      Get.put<AdService>(AdService(), permanent: true);
    }
    Get.lazyPut<BuyerHomeController>(
      () => BuyerHomeController(),
    );
  }
}

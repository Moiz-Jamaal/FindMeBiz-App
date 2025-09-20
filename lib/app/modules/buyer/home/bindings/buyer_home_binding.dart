import 'package:get/get.dart';
import 'package:souq/app/modules/daily_offer/controllers/daily_offer_controller.dart';
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
    Get.lazyPut<DailyOfferController>(
      () => DailyOfferController(),
    );
  }
}

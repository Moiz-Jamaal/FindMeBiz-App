import 'package:get/get.dart';
import '../controllers/buyer_search_controller.dart';
import '../../../../services/ad_service.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdService>()) {
      Get.put<AdService>(AdService(), permanent: true);
    }
    Get.lazyPut<BuyerSearchController>(
      () => BuyerSearchController(),
    );
  }
}

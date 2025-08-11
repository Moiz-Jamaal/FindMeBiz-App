import 'package:get/get.dart';
import '../controllers/search_controller.dart' as search;
import '../../../../services/ad_service.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdService>()) {
      Get.put<AdService>(AdService(), permanent: true);
    }
    Get.lazyPut<search.SearchController>(
      () => search.SearchController(),
    );
  }
}

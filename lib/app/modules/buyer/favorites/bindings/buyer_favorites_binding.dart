import 'package:get/get.dart';
import '../controllers/buyer_favorites_controller.dart';

class BuyerFavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerFavoritesController>(
      () => BuyerFavoritesController(),
    );
  }
}

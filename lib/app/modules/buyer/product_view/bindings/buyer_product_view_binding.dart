import 'package:get/get.dart';
import '../controllers/buyer_product_view_controller.dart';

class BuyerProductViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BuyerProductViewController>(
      () => BuyerProductViewController(),
    );
  }
}

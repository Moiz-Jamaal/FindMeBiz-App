import 'package:get/get.dart';
import '../controllers/seller_dashboard_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../profile/controllers/seller_profile_edit_controller.dart';

class SellerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerDashboardController>(
      () => SellerDashboardController(),
    );
    Get.lazyPut<ProductsController>(
      () => ProductsController(),
    );
    // Use Get.find to get existing instance or create if not exists
    try {
      Get.find<SellerProfileEditController>();
    } catch (e) {
      Get.put<SellerProfileEditController>(
        SellerProfileEditController(),
        permanent: true,
      );
    }
  }
}

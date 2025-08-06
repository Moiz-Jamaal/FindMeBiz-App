import 'package:get/get.dart';
import '../controllers/seller_profile_view_controller.dart';

class SellerProfileViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SellerProfileViewController>(
      () => SellerProfileViewController(),
    );
  }
}

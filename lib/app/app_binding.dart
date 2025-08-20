import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'services/api/api_client.dart';
import 'services/auth_service.dart';
import 'services/seller_service.dart';
import 'services/category_service.dart';
import 'services/subscription_service.dart';
import 'services/role_service.dart';
import 'services/product_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize GetStorage first
    Get.put<GetStorage>(GetStorage(), permanent: true);
    
    // Initialize API Client
    Get.put<ApiClient>(ApiClient(), permanent: true);
    
    // Initialize Services
    Get.put<RoleService>(RoleService(), permanent: true);
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<SellerService>(SellerService(), permanent: true);
    Get.put<CategoryService>(CategoryService(), permanent: true);
    Get.put<SubscriptionService>(SubscriptionService(), permanent: true);
    Get.put<ProductService>(ProductService.instance, permanent: true);
  }
}

class AppInitializer {
  static Future<void> initialize() async {
    // Initialize GetStorage
    await GetStorage.init();
    
    // Initialize role service
    if (Get.isRegistered<RoleService>()) {
      await Get.find<RoleService>().init();
    }
  }
}

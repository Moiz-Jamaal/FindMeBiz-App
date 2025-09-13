import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'services/api/api_client.dart';
import 'services/auth_service.dart';
import 'services/seller_service.dart';
import 'services/category_service.dart';
import 'services/subscription_service.dart';
import 'services/role_service.dart';
import 'services/product_service.dart';
import 'services/buyer_service.dart';
import 'services/favorites_service.dart';
import 'services/viewed_history_service.dart';
import 'services/user_settings_service.dart';
import 'services/ad_service.dart';
import 'services/campaign_service.dart';
import 'services/fallback_content_service.dart';
import 'services/app_links_service.dart';
import 'services/url_handler_service.dart';
import 'services/image_upload_service.dart';

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
    
    // Initialize Buyer Services
    Get.put<BuyerService>(BuyerService(), permanent: true);
    Get.put<FavoritesService>(FavoritesService(), permanent: true);
    Get.put<ViewedHistoryService>(ViewedHistoryService(), permanent: true);
    Get.put<UserSettingsService>(UserSettingsService(), permanent: true);
    
    // Initialize Campaign & Ad Services (order matters)
    Get.put<AppLinksService>(AppLinksService(), permanent: true);
    Get.put<CampaignService>(CampaignService(), permanent: true);
    Get.put<FallbackContentService>(FallbackContentService(), permanent: true);
    Get.put<AdService>(AdService(), permanent: true);
    Get.put<UrlHandlerService>(UrlHandlerService(), permanent: true);
  Get.put<ImageUploadService>(ImageUploadService(), permanent: true);
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

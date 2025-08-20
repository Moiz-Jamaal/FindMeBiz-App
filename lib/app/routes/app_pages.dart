import 'package:get/get.dart';
import '../services/role_service.dart';
import '../data/models/user_role.dart';
import '../controllers/startup_controller.dart';
import '../modules/startup/startup_view.dart';

// Core modules
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';

import '../modules/welcome/bindings/welcome_binding.dart';
import '../modules/welcome/views/welcome_view.dart';

// Seller modules
import '../modules/seller/onboarding/bindings/seller_onboarding_binding.dart';
import '../modules/seller/onboarding/views/seller_onboarding_view.dart';
import '../modules/seller/dashboard/bindings/seller_dashboard_binding.dart';
import '../modules/seller/dashboard/views/seller_dashboard_view.dart';
import '../modules/seller/products/bindings/add_product_binding.dart';
import '../modules/seller/products/views/add_product_view.dart';
import '../modules/seller/products/bindings/edit_product_binding.dart';
import '../modules/seller/products/views/edit_product_view.dart';
import '../modules/seller/products/bindings/product_detail_binding.dart';
import '../modules/seller/products/views/product_detail_view.dart';
import '../modules/seller/profile/bindings/seller_profile_edit_binding.dart';
import '../modules/seller/profile/views/seller_profile_edit_view.dart';
import '../modules/seller/stall_location/bindings/stall_location_binding.dart';
import '../modules/seller/stall_location/views/stall_location_view.dart';
import '../modules/seller/publish/bindings/profile_publish_binding.dart';
import '../modules/seller/publish/views/profile_publish_view.dart';


import '../modules/seller/settings/bindings/seller_settings_binding.dart';
import '../modules/seller/settings/views/seller_settings_view.dart';

// Buyer modules
import '../modules/buyer/home/bindings/buyer_home_binding.dart';
import '../modules/buyer/home/views/buyer_home_view.dart';
import '../modules/buyer/search/bindings/search_binding.dart';
import '../modules/buyer/search/views/search_view.dart';
import '../modules/buyer/enquiry/bindings/enquiry_binding.dart';
import '../modules/buyer/enquiry/views/enquiry_view.dart';
import '../modules/buyer/enquiry/views/create_enquiry_view.dart';
import '../modules/buyer/enquiry/views/enquiry_details_view.dart';
import '../modules/buyer/seller_view/bindings/seller_profile_view_binding.dart';
import '../modules/buyer/seller_view/views/seller_profile_view.dart';
import '../modules/buyer/map/bindings/buyer_map_binding.dart';
import '../modules/buyer/map/views/buyer_map_view.dart';
import '../modules/buyer/profile/bindings/buyer_profile_binding.dart';
import '../modules/buyer/profile/views/buyer_profile_view.dart';
import '../modules/buyer/favorites/bindings/buyer_favorites_binding.dart';
import '../modules/buyer/favorites/views/buyer_favorites_view.dart';
import '../modules/buyer/product_view/bindings/buyer_product_view_binding.dart';
import '../modules/buyer/product_view/views/buyer_product_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static String get INITIAL => Routes.STARTUP;

  static final routes = [
    // Startup route
    GetPage(
      name: _Paths.STARTUP,
      page: () => const StartupView(),
      binding: BindingsBuilder(() {
        Get.put(StartupController());
      }),
    ),
    
    // Core routes
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.WELCOME,
      page: () => const WelcomeView(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    
    // Seller routes
    GetPage(
      name: _Paths.SELLER_ONBOARDING,
      page: () => const SellerOnboardingView(),
      binding: SellerOnboardingBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_DASHBOARD,
      page: () => const SellerDashboardView(),
      binding: SellerDashboardBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_ADD_PRODUCT,
      page: () => const AddProductView(),
      binding: AddProductBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_EDIT_PRODUCT,
      page: () => const EditProductView(),
      binding: EditProductBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_PRODUCT_DETAIL,
      page: () => const ProductDetailView(),
      binding: ProductDetailBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_PROFILE_EDIT,
      page: () => const SellerProfileEditView(),
      binding: SellerProfileEditBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_STALL_LOCATION,
      page: () => const StallLocationView(),
      binding: StallLocationBinding(),
    ),
    GetPage(
      name: _Paths.SELLER_PUBLISH,
      page: () => const ProfilePublishView(),
      binding: ProfilePublishBinding(),
    ),
  
    GetPage(
      name: _Paths.SELLER_SETTINGS,
      page: () => const SellerSettingsView(),
      binding: SellerSettingsBinding(),
    ),
    
    // Buyer routes
    GetPage(
      name: _Paths.BUYER_HOME,
      page: () => const BuyerHomeView(),
      binding: BuyerHomeBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_ENQUIRY,
      page: () => const EnquiryView(),
      binding: EnquiryBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_CREATE_ENQUIRY,
      page: () => const CreateEnquiryView(),
      binding: EnquiryBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_ENQUIRY_DETAILS,
      page: () => const EnquiryDetailsView(),
      binding: EnquiryBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_SELLER_VIEW,
      page: () => const SellerProfileView(),
      binding: SellerProfileViewBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_MAP,
      page: () => const BuyerMapView(),
      binding: BuyerMapBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_PROFILE,
      page: () => const BuyerProfileView(),
      binding: BuyerProfileBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_FAVORITES,
      page: () => const BuyerFavoritesView(),
      binding: BuyerFavoritesBinding(),
    ),
    GetPage(
      name: _Paths.BUYER_PRODUCT_VIEW,
      page: () => const BuyerProductView(),
      binding: BuyerProductViewBinding(),
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:souq/app/services/ad_service.dart';
import 'package:souq/app/services/buyer_service.dart';
import 'package:souq/app/services/campaign_service.dart';
import 'package:souq/app/services/app_links_service.dart';
import 'package:souq/app/services/url_handler_service.dart';
import 'package:souq/app/services/favorites_service.dart';
import 'package:souq/app/services/user_settings_service.dart';
import 'package:souq/app/services/viewed_history_service.dart';

import 'app/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/constants/app_constants.dart';
import 'app/services/communication_service.dart';
import 'app/services/performance_service.dart';
import 'app/services/role_service.dart';
import 'app/services/push_notification_service.dart';
import 'app/services/api/api_client.dart';
import 'app/services/auth_service.dart';
import 'app/services/seller_service.dart';
import 'app/services/category_service.dart';
import 'app/services/subscription_service.dart';
import 'services/product_service.dart';
import 'app/services/image_upload_service.dart';
import 'app/services/location_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'app/services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize critical services first
  await _initializeCriticalServices();
  
  // Initialize remaining services in parallel (non-blocking)
  _initializeSecondaryServices();
  
  // Set system UI styles
  _configureSystemUI();
  
  runApp(MyApp());
}

/// Initialize only critical services that are needed immediately
Future<void> _initializeCriticalServices() async {
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Setup error handling
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // Initialize only essential services synchronously
  Get.put(CommunicationService());
  Get.put(PerformanceService());
  Get.put(AnalyticsService(FirebaseAnalytics.instance));
  Get.put<ApiClient>(ApiClient(), permanent: true);
  
  // Initialize AuthService (critical for navigation decisions)
  await Get.putAsync<AuthService>(() async => AuthService().init(), permanent: true);
}

/// Initialize secondary services asynchronously (non-blocking)
void _initializeSecondaryServices() {
  // These services can be initialized after the app starts
  Future(() async {
    // Initialize services in parallel groups to reduce blocking
    
    // Group 1: Core business services
    final group1 = [
      () => Get.put<CategoryService>(CategoryService(), permanent: true),
      () => Get.put<ProductService>(ProductService(), permanent: true),
      () => Get.put<SellerService>(SellerService(), permanent: true),
    ];
    
    // Group 2: User experience services
    final group2 = [
      () => Get.put<FavoritesService>(FavoritesService(), permanent: true),
      () => Get.put<ViewedHistoryService>(ViewedHistoryService(), permanent: true),
      () => Get.put<UserSettingsService>(UserSettingsService(), permanent: true),
    ];
    
    // Group 3: Campaign and subscription services
    final group3 = [
      () => Get.put<AdService>(AdService(), permanent: true),
      () => Get.put<CampaignService>(CampaignService(), permanent: true),
      () => Get.put<SubscriptionService>(SubscriptionService(), permanent: true),
    ];
    
    // Group 4: Utility services
    final group4 = [
      () => Get.put<ImageUploadService>(ImageUploadService(), permanent: true),
      () => Get.put<LocationService>(LocationService(), permanent: true),
      () => Get.put<BuyerService>(BuyerService(), permanent: true),
      () => Get.put<AppLinksService>(AppLinksService(), permanent: true),
      () => Get.put<UrlHandlerService>(UrlHandlerService(), permanent: true),
    ];
    
    // Execute each group in parallel
    await Future.wait([
      Future(() async {
        for (final service in group1) service();
      }),
      Future(() async {
        for (final service in group2) service();
      }),
      Future(() async {
        for (final service in group3) service();
      }),
      Future(() async {
        for (final service in group4) service();
      }),
    ]);
    
    // Initialize async services last
    await Future.wait([
      Get.putAsync<RoleService>(() async => RoleService().init()),
      Get.putAsync<PushNotificationService>(() async => PushNotificationService().init()),
    ]);
    
    // Preload critical data only after UI is responsive
    Get.find<PerformanceService>().preloadCriticalData();
  });
}

void _configureSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      
      // Global settings
      defaultTransition: Transition.cupertino,
      transitionDuration: AppConstants.shortAnimation,
      
      // Error handling
      builder: (context, child) {
        // Normalize text scale
        final normalized = MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );

        // Instagram-like web layout: center all pages at fixed width on wide web
        if (kIsWeb) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final route = Get.currentRoute;
              // Do not center hub pages that have their own web sidebar layout
              final bool isHub = route == Routes.BUYER_HOME || route == Routes.SELLER_DASHBOARD;
              final bool useFixed = width >= 900 && !isHub;
              if (useFixed) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: normalized,
                  ),
                );
              }
              return normalized;
            },
          );
        }

        return normalized;
      },
    );
  }
}

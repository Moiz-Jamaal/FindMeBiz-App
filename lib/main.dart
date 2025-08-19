import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

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
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Crashlytics: capture Flutter errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Capture zone errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // Initialize services
  Get.put(CommunicationService());
  Get.put(PerformanceService());
  Get.put(AnalyticsService(FirebaseAnalytics.instance));
  
  // Initialize API services
  Get.put<ApiClient>(ApiClient(), permanent: true);
  
  // Initialize AuthService asynchronously and wait for it to load saved user data
  await Get.putAsync<AuthService>(() async => AuthService().init(), permanent: true);
  
  Get.put<SellerService>(SellerService(), permanent: true);
  Get.put<CategoryService>(CategoryService(), permanent: true);
  Get.put<SubscriptionService>(SubscriptionService(), permanent: true);
  Get.put<ImageUploadService>(ImageUploadService(), permanent: true);
  Get.put<LocationService>(LocationService(), permanent: true);
  
  await Get.putAsync<RoleService>(() async => RoleService().init());
  await Get.putAsync<PushNotificationService>(() async => PushNotificationService().init());
  
  // Preload critical data
  Get.find<PerformanceService>().preloadCriticalData();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    GetMaterialApp(
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
      
      // Global bindings if needed
      // initialBinding: GlobalBinding(),
      
      // Error handling
      builder: (context, child) {
        // Normalize text scale
        final normalized = MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
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
    ),
  );
}

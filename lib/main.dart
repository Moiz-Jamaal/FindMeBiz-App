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
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Initialize services
  Get.put(CommunicationService());
  Get.put(PerformanceService());
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

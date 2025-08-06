import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/constants/app_constants.dart';
import 'app/services/communication_service.dart';
import 'app/services/performance_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  Get.put(CommunicationService());
  Get.put(PerformanceService());
  
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
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    ),
  );
}

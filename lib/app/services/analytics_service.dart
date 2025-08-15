import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';

class AnalyticsService extends GetxService {
  final FirebaseAnalytics analytics;
  AnalyticsService(this.analytics);

  static AnalyticsService get to => Get.find();

  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    await analytics.logScreenView(screenName: screenName, screenClass: screenClass ?? screenName);
  }

  Future<void> logEvent(String name, {Map<String, Object> parameters = const {}}) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  void setUserId(String? id) {
    analytics.setUserId(id: id);
  }

  void setUserProperty(String name, String? value) {
    analytics.setUserProperty(name: name, value: value);
  }

  // Crashlytics helpers
  void recordNonFatal(Object error, StackTrace stack, {Map<String, String>? info}) {
    if (info != null) {
      info.forEach((k, v) => FirebaseCrashlytics.instance.setCustomKey(k, v));
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
  }
}

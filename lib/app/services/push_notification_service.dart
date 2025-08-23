import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:souq/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

// Top-level handler for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  try {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

class PushNotificationService extends GetxService {
  FirebaseMessaging? _messaging; // nullable to support web where we may skip full setup
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  late final AndroidNotificationChannel _defaultChannel;

  Future<PushNotificationService> init() async {
    await _initFirebase();
    // Now that Firebase is initialized, set up messaging differently for web vs mobile
    if (!kIsWeb) {
      _messaging = FirebaseMessaging.instance;
      await _initLocalNotifications();
      await _configureMessaging();
    } else {
      // Web: avoid local notifications and Apple-specific presentation options.
      // Listen to foreground messages and show a simple in-app banner.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        if (notification != null) {
          Get.snackbar(
            notification.title ?? 'Notification',
            notification.body ?? '',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
        }
      });
    }
    // Log token for debugging/registration purposes
    try {
      final token = await getFcmToken();
      if (token != null) {
        Get.log('FCM token: $token');
      }
    } catch (_) {}
    return this;
  }

  Future<void> _initFirebase() async {
    try {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      // ignore if already initialized
    }
  }

  Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(initSettings);

    _defaultChannel = const AndroidNotificationChannel(
      'default_channel',
      'General Notifications',
      description: 'Default channel for app notifications',
      importance: Importance.high,
    );

    await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultChannel);
  }

  Future<void> _configureMessaging() async {
    // Permissions
    if (Platform.isIOS) {
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground notifications presentation (iOS/web)
  await _messaging!.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show local notification when a message arrives in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final android = notification?.android;
      if (notification != null) {
        await _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _defaultChannel.id,
              _defaultChannel.name,
              channelDescription: _defaultChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Handle when user taps a notification and opens the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      Get.log('Notification tapped with data: ${message.data}');
      // TODO: Navigate based on message.data if needed
    });
  }

  Future<String?> getFcmToken() async {
    try {
      if (_messaging == null) return null; // web path without vapidKey, skip
      if (kIsWeb) {
        // On web, a VAPID key is required for push tokens; return null if not configured
        return await _messaging!.getToken();
      }
      return await _messaging!.getToken();
    } catch (_) {
      return null;
    }
  }
}

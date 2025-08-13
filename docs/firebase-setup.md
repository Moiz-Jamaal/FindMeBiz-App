# Firebase setup (Android + iOS)

Follow these steps to connect this app to your Firebase project. Android builds are already wired to accept Firebase config; we only need the config files.

## 1) Create a Firebase project
- Go to https://console.firebase.google.com and create/select a project.

## 2) Add Android app
- Package name: com.application.findmebiz (must match android/app/build.gradle.kts `applicationId`)
- App nickname: FindMeBiz (optional)
- SHA-1/256: optional for now (required for Google Sign-In / Dynamic Links).
- Download `google-services.json` and place it here:
  - android/app/google-services.json

The Android module will auto-apply the Google Services plugin when this file exists.

## 3) Add iOS app (optional, if you target iOS)
- Bundle ID: Use your iOS bundle id (defaults to Runner if unmodified). If you want to match Android, set it in Xcode project settings.
- Download `GoogleService-Info.plist` and place it here:
  - ios/Runner/GoogleService-Info.plist

Open Xcode and ensure the plist is included in the Runner target (Build Phases > Copy Bundle Resources).

## 4) Dependencies (already added)
- firebase_core
- firebase_messaging
- flutter_local_notifications 19.4.0

Android Gradle is configured with core library desugaring (2.1.4), required by flutter_local_notifications 19.4.0.

## 5) Test
- Run the app on a device/emulator.
- Check logs for `FCM token:` in the console. Copy the token and send a test message from Firebase Console > Cloud Messaging.
- Foreground messages show a local notification; background/tapped messages log payload and can be routed later.

## 6) Optional improvements
- Use `firebase_options.dart` via FlutterFire CLI for multi-platform config.
- Handle notification tap navigation in `PushNotificationService` based on `message.data`.
- Persist FCM tokens to your backend and subscribe to topics as needed.

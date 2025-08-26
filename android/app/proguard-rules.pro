# Proguard rules for release builds
# Flutter/Dart keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.** { *; }
-keep class com.yourcompany.** { *; }
# Keep classes with @Keep annotation
-keep @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
    @androidx.annotation.Keep <fields>;
}
# Keep Firebase Analytics and Crashlytics
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
# Keep Gson (if used)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
# Keep classes used for JSON serialization/deserialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
# Keep reflection
-keepclassmembers class * {
    public <init>(...);
}
# Add any additional rules for plugins you use below

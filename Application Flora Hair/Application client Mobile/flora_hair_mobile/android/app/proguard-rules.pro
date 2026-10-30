# Flutter — ne pas toucher au wrapper Flutter ni au moteur.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase Cloud Messaging
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# OkHttp / Retrofit (utilise par certains plugins Flutter)
-dontwarn okhttp3.**
-dontwarn okio.**

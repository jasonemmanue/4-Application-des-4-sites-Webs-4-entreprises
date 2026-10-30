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

# Google Play Core — Flutter référence les classes de « deferred components »
# (SplitCompat / SplitInstall) sans que la lib Play Core soit une dépendance.
# Sans ces règles, R8 échoue sur « Missing classes ». Non utilisées ici.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

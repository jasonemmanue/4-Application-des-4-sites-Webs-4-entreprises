# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Prevent R8 from leaving Data Binding Reflection Classes
-dontwarn android.databinding.**
-keep class android.databinding.** { *; }

# Google Play Core — Flutter référence les classes de « deferred components »
# (SplitCompat / SplitInstall) sans que la lib Play Core soit une dépendance.
# Sans ces règles, R8 échoue sur « Missing classes ». Non utilisées ici.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

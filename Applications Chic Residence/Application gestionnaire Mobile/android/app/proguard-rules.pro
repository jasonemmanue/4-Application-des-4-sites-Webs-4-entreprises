## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Firebase
-keep class com.google.firebase.** { *; }

## Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

## Google Play Services
-keep class com.google.android.gms.** { *; }

## Google Play Core — Flutter référence les classes de « deferred components »
## (SplitCompat / SplitInstall) sans que la lib Play Core soit une dépendance.
## Sans ces règles, R8 échoue sur « Missing classes ». On ne les utilise pas,
## d'où -dontwarn plutôt qu'un -keep.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

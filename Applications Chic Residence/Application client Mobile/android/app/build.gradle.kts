import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin google-services lit `android/app/google-services.json` à la
    // compilation. Il faut avoir déposé ce fichier depuis Firebase Console
    // *avant* le premier build — sinon, erreur explicite au moment du build.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Signing release (Play Store) ─────────────────────────────────────────
// Les identifiants du keystore vivent dans `android/key.properties` (non
// versionné). En son absence, le release retombe sur les clés de debug — ce
// qui permet un `flutter run --release` local sans configuration.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

android {
    namespace = "com.chicresidence.chic_residence_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.chicresidence.chic_residence_mobile"
        // Firebase Messaging exige API 21+, Play Store recommande 23+.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Le multidex n'est plus nécessaire depuis minSdk 21, mais Firebase
        // et les dépendances Google Play Services le déclenchent parfois.
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Si key.properties existe → signature release.
            // Sinon → fallback debug pour que `flutter run --release` marche
            // encore, y compris quand un dev clone le repo sans keystore.
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

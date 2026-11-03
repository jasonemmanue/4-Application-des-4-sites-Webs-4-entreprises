import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configuration native de Firebase (GoogleService-Info.plist) avant Flutter :
    // le jeton APNs peut arriver avant que le Dart n'appelle initializeApp().
    // Le swizzling Firebase reste actif : il transmet ce jeton à FCM tout seul.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)

    // Affiche les notifications quand l'app est ouverte.
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

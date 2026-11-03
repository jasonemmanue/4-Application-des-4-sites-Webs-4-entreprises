import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Affiche les notifications quand l'application est ouverte (sinon iOS
    // ne les montre qu'en arrière-plan). Firebase transmet le jeton APNs
    // lui-même : `FirebaseAppDelegateProxyEnabled` reste à sa valeur par défaut.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

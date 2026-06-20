import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  var pushService: PushNotificationService?

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Task { @MainActor in
      pushService?.handleDeviceToken(deviceToken)
    }
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    // Simulator and missing capability — expected during local dev
  }
}

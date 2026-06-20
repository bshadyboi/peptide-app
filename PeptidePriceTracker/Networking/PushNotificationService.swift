import Foundation
import UIKit
import UserNotifications

@MainActor
final class PushNotificationService: NSObject, ObservableObject {
  @Published private(set) var deviceToken: String?

  private weak var authSession: AuthSession?
  private var api: APIClient?

  func configure(authSession: AuthSession, api: APIClient?) {
    self.authSession = authSession
    self.api = api
    UNUserNotificationCenter.current().delegate = self
  }

  func registerForPushNotifications() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
      granted, _ in
      guard granted else { return }
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  func handleDeviceToken(_ tokenData: Data) {
    let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
    deviceToken = token
    Task { await uploadToken(token) }
  }

  private func uploadToken(_ token: String) async {
    guard let api, let authSession, authSession.isSignedIn else { return }
    do {
      try await api.registerDevice(apnsToken: token, accessToken: authSession.accessToken)
    } catch {
      // Non-fatal — will retry on next launch
    }
  }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {}

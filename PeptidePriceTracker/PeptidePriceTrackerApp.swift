import SwiftUI
import SwiftData

@main
struct PeptidePriceTrackerApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var pushService = PushNotificationService()
  @StateObject private var syncService: DataSyncService

  init() {
    let auth = AuthSession()
    _syncService = StateObject(wrappedValue: DataSyncService(api: APIClient(), authSession: auth))
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(syncService)
        .task {
          appDelegate.pushService = pushService
          pushService.configure(authSession: syncService.authSession, api: APIClient())
          guard SupabaseConfig.isConfigured else { return }
          await syncService.ensureSignedIn()
          pushService.registerForPushNotifications()
          await pushService.uploadPendingTokenIfNeeded()
        }
    }
    .modelContainer(ModelContainerFactory.shared)
  }
}

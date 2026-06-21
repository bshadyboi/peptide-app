import SwiftUI

struct ContentView: View {
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

  init() {
    let tabBar = UITabBar.appearance()
    tabBar.unselectedItemTintColor = UIColor(white: 0.55, alpha: 1)
    tabBar.barTintColor = UIColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1)
    tabBar.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1)
  }

  var body: some View {
    TabView {
      HomeView()
        .tabItem {
          Label("Home", systemImage: "house.fill")
        }

      WatchlistView()
        .tabItem {
          Label("Watchlist", systemImage: "bell")
        }

      SubmitView()
        .tabItem {
          Label("Submit", systemImage: "square.and.pencil")
        }
    }
    .tint(AppTheme.accent)
    .fullScreenCover(isPresented: onboardingBinding) {
      OnboardingView(isPresented: onboardingBinding)
    }
  }

  private var onboardingBinding: Binding<Bool> {
    Binding(
      get: { !hasCompletedOnboarding },
      set: { show in
        if !show { hasCompletedOnboarding = true }
      }
    )
  }
}

#Preview {
  ContentView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .environmentObject(FavoritesStore())
    .modelContainer(for: [Peptide.self, Dose.self, Vendor.self, Price.self, PriceAlert.self], inMemory: true)
}

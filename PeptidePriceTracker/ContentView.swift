import SwiftUI

struct ContentView: View {
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

  init() {
    UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel
  }

  var body: some View {
    TabView {
      HomeView()
        .tabItem {
          Label("Compare", systemImage: "list.bullet")
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
    .modelContainer(for: [Peptide.self, Dose.self, Vendor.self, Price.self, PriceAlert.self], inMemory: true)
}

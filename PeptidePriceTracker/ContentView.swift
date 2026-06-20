import SwiftUI

struct ContentView: View {
  init() {
    UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel
  }

  var body: some View {
    TabView {
      HomeView()
        .tabItem {
          Label("Prices", systemImage: "chart.bar.doc.horizontal")
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
  }
}

#Preview {
  ContentView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [Peptide.self, Dose.self, Vendor.self, Price.self, PriceAlert.self], inMemory: true)
}

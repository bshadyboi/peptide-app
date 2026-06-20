import SwiftUI
import SwiftData

struct WatchlistView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @Query(sort: \PriceAlert.createdAt, order: .reverse) private var alerts: [PriceAlert]

  var body: some View {
    NavigationStack {
      Group {
        if !SupabaseConfig.isConfigured {
          ContentUnavailableView {
            Label("Supabase Not Configured", systemImage: "key.slash")
          } description: {
            Text("Add your Supabase URL and anon key in Secrets.xcconfig.")
          }
        } else if alerts.isEmpty {
          ContentUnavailableView {
            Label("No Alerts Yet", systemImage: "bell")
          } description: {
            Text("Tap \"Alert me\" on a peptide detail screen to track a target $/mg.")
          }
        } else {
          List {
            ForEach(alerts.filter(\.active), id: \.id) { alert in
              NavigationLink {
                if let peptide = alert.dose?.peptide {
                  PeptideDetailView(peptide: peptide)
                }
              } label: {
                WatchlistRow(alert: alert)
              }
            }
            .onDelete(perform: deleteAlerts)
          }
        }
      }
      .navigationTitle("Watchlist")
      .task {
        guard SupabaseConfig.isConfigured else { return }
        await syncService.ensureSignedIn()
        await syncService.syncAlerts(context: modelContext)
      }
      .refreshable {
        await syncService.syncAlerts(context: modelContext)
      }
    }
  }

  private func deleteAlerts(at offsets: IndexSet) {
    let active = alerts.filter(\.active)
    Task {
      for index in offsets {
        let alert = active[index]
        try? await syncService.deleteAlert(id: alert.id, context: modelContext)
      }
    }
  }
}

private struct WatchlistRow: View {
  let alert: PriceAlert

  private var dose: Dose? { alert.dose }

  private var bestPricePerMg: Decimal? {
    guard let dose else { return nil }
    return Price.sortedForCompare(dose.prices).first(where: \.inStock)?.pricePerMg
  }

  private var isTriggered: Bool {
    alert.isTriggered(bestPricePerMg: bestPricePerMg)
  }

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(isTriggered ? Color.red : Color.clear)
        .frame(width: 10, height: 10)
        .overlay {
          Circle()
            .stroke(Color.secondary.opacity(0.3), lineWidth: isTriggered ? 0 : 1)
        }

      VStack(alignment: .leading, spacing: 4) {
        Text(dose?.peptide?.name ?? "Unknown peptide")
          .font(.headline)

        if let dose {
          Text(dose.displayName)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Text("Target \(CurrencyFormatter.formatPerMg(alert.targetPerMg))")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      if let best = bestPricePerMg {
        Text(CurrencyFormatter.formatPerMg(best))
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(isTriggered ? .red : .primary)
      } else {
        Text("—")
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  WatchlistView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [PriceAlert.self, Dose.self, Peptide.self, Price.self], inMemory: true)
}

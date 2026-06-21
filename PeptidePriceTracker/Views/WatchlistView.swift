import SwiftUI
import SwiftData

struct WatchlistView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @Query(sort: \PriceAlert.createdAt, order: .reverse) private var alerts: [PriceAlert]

  private var activeAlerts: [PriceAlert] {
    alerts.filter(\.active)
  }

  var body: some View {
    NavigationStack {
      Group {
        if !SupabaseConfig.isConfigured {
          ContentUnavailableView {
            Label("Supabase Not Configured", systemImage: "key.slash")
          } description: {
            Text("Add your Supabase URL and anon key in Secrets.xcconfig.")
          }
        } else if activeAlerts.isEmpty {
          ContentUnavailableView {
            Label("No Alerts Yet", systemImage: "bell")
          } description: {
            Text("Tap Alert on a peptide detail screen to track a target $/mg.")
          }
        } else {
          List {
            ForEach(activeAlerts, id: \.id) { alert in
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
          .listStyle(.plain)
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
    Task {
      for index in offsets {
        let alert = activeAlerts[index]
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
    HStack(spacing: 14) {
      if let slug = dose?.peptide?.slug {
        PeptideArtwork(slug: slug, size: 44, cornerRadius: 12)
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(AppTheme.accentSoft)
            .frame(width: 44, height: 44)
          Image(systemName: "bell")
            .foregroundStyle(AppTheme.accent)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(dose?.peptide?.name ?? "Unknown peptide")
          .font(.body)
          .fontWeight(.semibold)

        HStack(spacing: 6) {
          if let dose {
            Text(dose.displayName)
              .foregroundStyle(.secondary)
          }
          Text("·")
            .foregroundStyle(.tertiary)
          Text("target \(CurrencyFormatter.formatPerMg(alert.targetPerMg))")
            .foregroundStyle(.secondary)
        }
        .font(.caption)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 2) {
        if let best = bestPricePerMg {
          Text(CurrencyFormatter.formatPerMg(best))
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(isTriggered ? AppTheme.sale : AppTheme.inStock)
            .monospacedDigit()

          if isTriggered {
            Label("At target", systemImage: "bell.fill")
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundStyle(AppTheme.sale)
          }
        } else {
          Text("—")
            .foregroundStyle(.tertiary)
        }
      }
    }
    .padding(.vertical, 6)
  }
}

#Preview {
  WatchlistView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [PriceAlert.self, Dose.self, Peptide.self, Price.self], inMemory: true)
}

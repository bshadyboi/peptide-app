import SwiftUI
import SwiftData

private enum WatchlistTab: String, CaseIterable {
  case saved = "Saved"
  case alerts = "Alerts"
}

struct WatchlistView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @EnvironmentObject private var favorites: FavoritesStore
  @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
  @Query(sort: \PriceAlert.createdAt, order: .reverse) private var alerts: [PriceAlert]

  @State private var tab: WatchlistTab = .saved

  private var activeAlerts: [PriceAlert] {
    alerts.filter(\.active)
  }

  private var savedPeptides: [Peptide] {
    favorites.sortedPeptides(from: allPeptides)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        DarkAuroraBackground()

        VStack(spacing: 0) {
          Picker("Section", selection: $tab) {
            ForEach(WatchlistTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
          }
          .pickerStyle(.segmented)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)

          Group {
            if !SupabaseConfig.isConfigured {
              configurationPrompt
            } else if tab == .saved {
              savedContent
            } else {
              alertsContent
            }
          }
        }
      }
      .navigationTitle("Watchlist")
      .toolbarBackground(.hidden, for: .navigationBar)
      .preferredColorScheme(.dark)
      .task {
        guard SupabaseConfig.isConfigured else { return }
        await syncService.ensureSignedIn()
        await syncService.syncCatalog(context: modelContext)
        await syncService.syncAlerts(context: modelContext)
      }
      .refreshable {
        await syncService.syncCatalog(context: modelContext)
        await syncService.syncAlerts(context: modelContext)
      }
    }
  }

  @ViewBuilder
  private var savedContent: some View {
    if savedPeptides.isEmpty {
      ContentUnavailableView {
        Label("No Saved Peptides", systemImage: "heart")
      } description: {
        Text("Tap the heart on a peptide detail screen to save it here.")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ScrollView {
        LazyVStack(spacing: 10) {
          ForEach(savedPeptides, id: \.id) { peptide in
            NavigationLink {
              PeptideDetailView(peptide: peptide)
            } label: {
              DarkPeptideListRow(peptide: peptide, displayMode: .perMg)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
      }
    }
  }

  @ViewBuilder
  private var alertsContent: some View {
    if activeAlerts.isEmpty {
      ContentUnavailableView {
        Label("No Alerts Yet", systemImage: "bell")
      } description: {
        Text("Tap Alert on a peptide detail screen to track a target $/mg.")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ScrollView {
        LazyVStack(spacing: 10) {
          ForEach(activeAlerts, id: \.id) { alert in
            NavigationLink {
              if let peptide = alert.dose?.peptide {
                PeptideDetailView(peptide: peptide)
              }
            } label: {
              WatchlistAlertRow(alert: alert)
            }
            .buttonStyle(.plain)
            .contextMenu {
              Button(role: .destructive) {
                Task { try? await syncService.deleteAlert(id: alert.id, context: modelContext) }
              } label: {
                Label("Delete alert", systemImage: "trash")
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
      }
    }
  }

  private var configurationPrompt: some View {
    ContentUnavailableView {
      Label("Supabase Not Configured", systemImage: "key.slash")
    } description: {
      Text("Add your Supabase URL and anon key in Secrets.xcconfig.")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private struct WatchlistAlertRow: View {
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
      if let peptide = dose?.peptide {
        PeptideMonogramBadge(name: peptide.name, slug: peptide.slug, size: 50)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(dose?.peptide?.name ?? "Unknown peptide")
          .font(.body.weight(.semibold))
          .foregroundStyle(.white)

        HStack(spacing: 6) {
          if let dose {
            Text(dose.displayName)
              .foregroundStyle(Color.white.opacity(0.5))
          }
          Text("· target \(CurrencyFormatter.formatPerMg(alert.targetPerMg))")
            .foregroundStyle(Color.white.opacity(0.5))
        }
        .font(.caption)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        if let best = bestPricePerMg {
          Text(CurrencyFormatter.formatPerMg(best))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isTriggered ? AppTheme.sale : AppTheme.neonCyan)
            .monospacedDigit()

          if isTriggered {
            Label("At target", systemImage: "bell.fill")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(AppTheme.sale)
          }
        } else {
          Text("—")
            .foregroundStyle(Color.white.opacity(0.35))
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(AppTheme.darkCard.opacity(0.75))
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
  }
}

#Preview {
  WatchlistView()
    .environmentObject(FavoritesStore())
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [PriceAlert.self, Dose.self, Peptide.self, Price.self], inMemory: true)
}

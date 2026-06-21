import SwiftUI
import SwiftData

struct PeptideDetailView: View {
  let peptide: Peptide

  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @EnvironmentObject private var favorites: FavoritesStore
  @State private var selectedDoseID: UUID?
  @State private var showAlertSheet = false
  @State private var inStockOnly = true
  @State private var dosePoints: [PricePoint] = []

  private var doses: [Dose] { peptide.doses.sorted { $0.mg < $1.mg } }

  private var selectedDose: Dose? {
    if let id = selectedDoseID, let match = doses.first(where: { $0.id == id }) { return match }
    return doses.first
  }

  private var prices: [Price] {
    guard let dose = selectedDose else { return [] }
    return Price.sortedForCompare(dose.prices, inStockOnly: inStockOnly)
  }

  private var best: Price? { prices.first(where: \.inStock) }

  private var trend: PriceTrend? {
    guard let dose = selectedDose else { return nil }
    let t = PriceHistoryAnalytics.trend(
      for: dose.id,
      currentBestPerMg: best?.pricePerMg,
      points: dosePoints
    )
    return (t.changePercent != nil || t.isLowestEver) ? t : nil
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        detailHero
        if !doses.isEmpty { dosePicker }
        if let best { DetailBestPriceBanner(price: best, trend: trend) }
        compareSection
      }
      .padding()
      .padding(.bottom, 80)
    }
    .navigationTitle(peptide.name)
    .navigationBarTitleDisplayMode(.large)
    .background(DarkAuroraBackground())
    .preferredColorScheme(.dark)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          favorites.toggle(peptide.slug)
        } label: {
          Image(systemName: favorites.isFavorite(peptide.slug) ? "heart.fill" : "heart")
            .foregroundStyle(favorites.isFavorite(peptide.slug) ? AppTheme.sale : AppTheme.neonCyan)
        }
      }
    }
    .onAppear { if selectedDoseID == nil { selectedDoseID = doses.first?.id } }
    .task(id: selectedDoseID) { await reload() }
    .refreshable { await reload() }
    .safeAreaInset(edge: .bottom) { bottomBar }
    .sheet(isPresented: $showAlertSheet) {
      if let dose = selectedDose {
        AlertSetupSheet(dose: dose, suggestedTarget: best?.pricePerMg)
      }
    }
  }

  private var detailHero: some View {
    HStack(spacing: 16) {
      PeptideMonogramBadge(name: peptide.name, slug: peptide.slug, size: 64)

      VStack(alignment: .leading, spacing: 6) {
        let topic = PeptideCatalog.topic(for: peptide.slug)
        if peptide.category == .blend {
          DarkCategoryPill(label: "Blend", color: AppTheme.neonPurple)
        } else if topic != .all {
          DarkCategoryPill(label: topic.rawValue, color: topic.accent)
        }

        if let best = peptide.bestPricePerMg {
          Text("from \(CurrencyFormatter.formatPerMg(best))")
            .font(.title3.weight(.bold))
            .foregroundStyle(AppTheme.neonCyan)
            .monospacedDigit()
        }
      }

      Spacer()
    }
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(AppTheme.darkCard.opacity(0.85))
        .overlay {
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(
              LinearGradient(
                colors: [AppTheme.neonCyan.opacity(0.4), AppTheme.neonPurple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1
            )
        }
    }
  }

  private var dosePicker: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(doses, id: \.id) { dose in
          Button(dose.displayName) { selectedDoseID = dose.id }
            .buttonStyle(.bordered)
            .tint(selectedDose?.id == dose.id ? AppTheme.accent : .secondary)
        }
      }
    }
  }

  private var compareSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Toggle("In stock only", isOn: $inStockOnly)
      if prices.isEmpty {
        Text("No prices yet.").foregroundStyle(.secondary)
      } else {
        VendorCompareTable(prices: prices, bestPriceID: best?.id)
      }
      if let dose = selectedDose {
        NavigationLink("Price history") { PriceHistoryView(dose: dose) }
          .font(.subheadline)
      }
    }
  }

  private var bottomBar: some View {
    HStack {
      if let dose = selectedDose, let best {
        ShareLink(item: ShareBestDeal.message(peptide: peptide, dose: dose, price: best)) {
          Image(systemName: "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
      }
      Button { showAlertSheet = true } label: {
        Text("Alert").frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(.bar)
  }

  private func reload() async {
    guard let id = selectedDoseID else { return }
    await syncService.syncPrices(for: id, context: modelContext)
    await syncService.syncHistory(for: id, range: .days30, context: modelContext)
    let since = HistoryRange.days30.startDate
    let descriptor = FetchDescriptor<PricePoint>(
      predicate: #Predicate { $0.doseId == id && $0.capturedAt >= since }
    )
    dosePoints = (try? modelContext.fetch(descriptor)) ?? []
  }
}

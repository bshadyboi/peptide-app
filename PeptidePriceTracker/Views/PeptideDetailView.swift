import SwiftUI
import SwiftData

struct PeptideDetailView: View {
  let peptide: Peptide

  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @Query private var allPricePoints: [PricePoint]
  @State private var selectedDoseID: UUID?
  @State private var showAlertSheet = false
  @State private var inStockOnly = true

  private var sortedDoses: [Dose] {
    peptide.doses.sorted { $0.mg < $1.mg }
  }

  private var selectedDose: Dose? {
    if let selectedDoseID,
       let match = sortedDoses.first(where: { $0.id == selectedDoseID }) {
      return match
    }
    return sortedDoses.first
  }

  private var sortedPrices: [Price] {
    guard let selectedDose else { return [] }
    return Price.sortedForCompare(selectedDose.prices, inStockOnly: inStockOnly)
  }

  private var bestInStockPrice: Price? {
    sortedPrices.first(where: \.inStock)
  }

  private var inStockVendorCount: Int {
    guard let selectedDose else { return 0 }
    let ids = Price.sortedForCompare(selectedDose.prices)
      .filter(\.inStock)
      .compactMap { $0.vendor?.id }
    return Set(ids).count
  }

  private var priceTrend: PriceTrend {
    guard let dose = selectedDose else {
      return PriceTrend(changePercent: nil, isLowestEver: false, daysOfHistory: nil, historicalLow: nil)
    }
    return PriceHistoryAnalytics.trend(
      for: dose.id,
      currentBestPerMg: bestInStockPrice?.pricePerMg,
      points: allPricePoints
    )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        PeptideHeroBanner(peptide: peptide)

        if peptide.category == .blend, !peptide.blendComponents.isEmpty {
          blendComponentsSection
        } else if let description = peptide.peptideDescription {
          Text(description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if !sortedDoses.isEmpty {
          doseSelector
        }

        if let best = bestInStockPrice {
          DetailBestPriceBanner(
            price: best,
            vendorCount: inStockVendorCount,
            trend: priceTrend
          )
        }

        compareSection
      }
      .padding(.horizontal)
      .padding(.top, 8)
      .padding(.bottom, 100)
    }
    .background(AppTheme.pageBackground)
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      if selectedDoseID == nil {
        selectedDoseID = sortedDoses.first?.id
      }
    }
    .task(id: selectedDoseID) {
      guard let selectedDoseID else { return }
      await syncService.syncPrices(for: selectedDoseID, context: modelContext)
      await syncService.syncHistory(for: selectedDoseID, range: .days90, context: modelContext)
    }
    .refreshable {
      guard let selectedDoseID else { return }
      await syncService.syncPrices(for: selectedDoseID, context: modelContext)
      await syncService.syncHistory(for: selectedDoseID, range: .days90, context: modelContext)
    }
    .safeAreaInset(edge: .bottom) {
      if selectedDose != nil {
        detailActionBar
      }
    }
    .sheet(isPresented: $showAlertSheet) {
      if let dose = selectedDose {
        AlertSetupSheet(
          dose: dose,
          suggestedTarget: bestInStockPrice?.pricePerMg
        )
      }
    }
  }

  private var blendComponentsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Blend")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.purple)

      Text(
        peptide.blendComponents
          .sorted { $0.componentName < $1.componentName }
          .map(\.displayLine)
          .joined(separator: " · ")
      )
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
  }

  private var doseSelector: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Dose")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(sortedDoses, id: \.id) { dose in
            Button {
              selectedDoseID = dose.id
            } label: {
              Text(dose.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                  selectedDose?.id == dose.id
                    ? AppTheme.accent
                    : Color(.tertiarySystemFill)
                )
                .foregroundStyle(
                  selectedDose?.id == dose.id ? Color.white : Color.primary
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private var compareSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Compare")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .textCase(.uppercase)

        Spacer()

        Toggle("In stock", isOn: $inStockOnly)
          .toggleStyle(.switch)
          .controlSize(.mini)
          .font(.caption)
      }

      if sortedPrices.isEmpty {
        Text("No prices for this dose yet.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 32)
      } else {
        VendorCompareTable(
          prices: sortedPrices,
          bestPriceID: bestInStockPrice?.id
        )
      }
    }
  }

  private var detailActionBar: some View {
    HStack(spacing: 10) {
      if let dose = selectedDose, let best = bestInStockPrice {
        ShareLink(item: ShareBestDeal.message(peptide: peptide, dose: dose, price: best)) {
          Label("Share", systemImage: "square.and.arrow.up")
            .labelStyle(.iconOnly)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.bordered)
      }

      if let dose = selectedDose {
        NavigationLink {
          PriceHistoryView(dose: dose)
        } label: {
          Label("History", systemImage: "chart.xyaxis.line")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
      }

      Button {
        showAlertSheet = true
      } label: {
        Label("Alert", systemImage: "bell.badge")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    .background(.bar)
  }
}

#Preview {
  let peptide = Peptide(
    name: "BPC-157",
    slug: "bpc-157",
    category: .single,
    description: "Preview peptide"
  )
  let dose = Dose(mg: 5, peptide: peptide)
  let vendor = Vendor(name: "Peptide Sciences")
  let price = Price(price: 59.50, discountCode: "RESEARCH10", coaAvailable: true, dose: dose, vendor: vendor)
  dose.prices = [price]
  peptide.doses = [dose]

  return NavigationStack {
    PeptideDetailView(peptide: peptide)
      .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
  }
}

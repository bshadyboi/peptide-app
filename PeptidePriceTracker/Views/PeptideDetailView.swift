import SwiftUI
import SwiftData

struct PeptideDetailView: View {
    let peptide: Peptide

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: DataSyncService
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if peptide.category == .blend, !peptide.blendComponents.isEmpty {
                    blendComponentsSection
                }

                if !sortedDoses.isEmpty {
                    doseSelector
                }

                if let best = bestInStockPrice {
                    BestPriceCard(price: best)
                }

                vendorSection

                if let dose = selectedDose {
                    NavigationLink {
                        PriceHistoryView(dose: dose)
                    } label: {
                        Label("Price history", systemImage: "chart.xyaxis.line")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showAlertSheet = true
                    } label: {
                        Label("Alert me", systemImage: "bell.badge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle(peptide.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if selectedDoseID == nil {
                selectedDoseID = sortedDoses.first?.id
            }
        }
        .task(id: selectedDoseID) {
            guard let selectedDoseID else { return }
            await syncService.syncPrices(for: selectedDoseID, context: modelContext)
        }
        .refreshable {
            guard let selectedDoseID else { return }
            await syncService.syncPrices(for: selectedDoseID, context: modelContext)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if peptide.category == .blend {
                Text("Blend")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Capsule())
            }

            if let description = peptide.peptideDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var blendComponentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's in it")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(peptide.blendComponents.sorted(by: { $0.componentName < $1.componentName }), id: \.id) { component in
                    Text(component.displayLine)
                        .font(.subheadline)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private var vendorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All vendors")
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedPrices.enumerated()), id: \.element.id) { index, price in
                        VendorPriceRow(
                            price: price,
                            isBest: price.inStock && price.id == bestInStockPrice?.id
                        )

                        if index < sortedPrices.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding()
                .peptideCard()
            }
        }
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

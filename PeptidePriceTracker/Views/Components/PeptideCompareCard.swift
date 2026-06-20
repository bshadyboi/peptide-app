import SwiftUI

struct PeptideCompareCard: View {
  let peptide: Peptide
  let displayMode: PriceDisplayMode

  @State private var selectedDoseID: UUID?

  private var selectedDose: Dose? {
    if let selectedDoseID, let match = peptide.sortedDoses.first(where: { $0.id == selectedDoseID }) {
      return match
    }
    return peptide.defaultDose
  }

  private var previewPrices: [Price] {
    guard let dose = selectedDose else { return [] }
    return peptide.topPrices(for: dose)
  }

  private var bestPriceID: UUID? {
    previewPrices.first(where: \.inStock)?.id
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      header

      if !peptide.sortedDoses.isEmpty {
        doseSelector
      }

      if previewPrices.isEmpty {
        Text("No prices yet for this dose.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 8)
      } else {
        VStack(spacing: 0) {
          ForEach(Array(previewPrices.enumerated()), id: \.element.id) { index, price in
            CompactVendorRow(
              price: price,
              displayMode: displayMode,
              isBest: price.id == bestPriceID
            )
            if index < previewPrices.count - 1 {
              Divider().padding(.leading, 46)
            }
          }
        }

        if let dose = selectedDose, peptide.remainingVendorCount(for: dose) > 0 {
          NavigationLink {
            PeptideDetailView(peptide: peptide)
          } label: {
            Text("+\(peptide.remainingVendorCount(for: dose)) more vendor\(peptide.remainingVendorCount(for: dose) == 1 ? "" : "s")")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(AppTheme.accent)
          }
          .padding(.top, 4)
        }
      }
    }
    .padding(16)
    .peptideCard()
    .onAppear {
      if selectedDoseID == nil {
        selectedDoseID = peptide.defaultDose?.id
      }
    }
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 6) {
        NavigationLink {
          PeptideDetailView(peptide: peptide)
        } label: {
          Text(peptide.name)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
        }
        .buttonStyle(.plain)

        HStack(spacing: 6) {
          if let category = PeptideCatalog.displayCategory(for: peptide.slug) {
            CategoryTag(label: category)
          }
          if peptide.category == .blend {
            CategoryTag(label: "Blend", tint: .purple)
          }
        }

        if peptide.category == .blend, !peptide.blendComponents.isEmpty {
          Text(
            peptide.blendComponents
              .sorted { $0.componentName < $1.componentName }
              .map(\.componentName)
              .joined(separator: " · ")
          )
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
        }
      }

      Spacer()

      if let best = previewPrices.first(where: \.inStock) {
        VStack(alignment: .trailing, spacing: 2) {
          Text("from")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(
            displayMode == .perMg
              ? (best.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—")
              : CurrencyFormatter.format(best.effectivePrice)
          )
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(AppTheme.inStock)
        }
      }
    }
  }

  private var doseSelector: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Dosage")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(peptide.sortedDoses, id: \.id) { dose in
            let isSelected = selectedDose?.id == dose.id
            Button {
              selectedDoseID = dose.id
            } label: {
              HStack(spacing: 4) {
                if dose.id == peptide.defaultDose?.id {
                  Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .yellow)
                }
                Text(dose.displayName)
                  .font(.caption)
                  .fontWeight(.semibold)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 7)
              .background(isSelected ? AppTheme.accent : Color(.tertiarySystemFill))
              .foregroundStyle(isSelected ? .white : .primary)
              .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

import SwiftUI

struct PeptideListRow: View {
  let peptide: Peptide
  let displayMode: PriceDisplayMode

  private var dose: Dose? { peptide.defaultDose }

  private var best: Price? {
    guard let dose else { return nil }
    return Price.sortedForCompare(dose.prices).first(where: \.inStock)
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(peptide.name)
          .font(.body.weight(.semibold))
        if let dose, let best {
          Text("\(dose.displayName) · \(best.vendor?.name ?? "—")")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      Spacer()
      if let best {
        Text(displayMode == .perMg
          ? (best.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—")
          : CurrencyFormatter.format(best.effectivePrice))
          .font(.subheadline.weight(.bold))
          .foregroundStyle(AppTheme.inStock)
          .monospacedDigit()
      }
    }
    .padding(.vertical, 4)
  }
}

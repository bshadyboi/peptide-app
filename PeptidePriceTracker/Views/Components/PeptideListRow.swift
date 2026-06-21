import SwiftUI

struct PeptideListRow: View {
  let peptide: Peptide
  let displayMode: PriceDisplayMode
  var trend: PriceTrend?

  private var summaryDose: Dose? { peptide.defaultDose }

  private var bestPrice: Price? {
    guard let dose = summaryDose else { return nil }
    return Price.sortedForCompare(dose.prices).first(where: \.inStock)
  }

  private var vendorCount: Int {
    guard let dose = summaryDose else { return 0 }
    let ids = Price.sortedForCompare(dose.prices)
      .filter(\.inStock)
      .compactMap { $0.vendor?.id }
    return Set(ids).count
  }

  var body: some View {
    HStack(spacing: 12) {
      PeptideArtwork(slug: peptide.slug, size: 46, cornerRadius: 13)

      VStack(alignment: .leading, spacing: 3) {
        Text(peptide.name)
          .font(.body)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .lineLimit(1)

        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        HStack(spacing: 6) {
          if PeptideDeals.hasActiveDeal(peptide) {
            DealBadge()
          }
          if let trend {
            PriceDropBadge(trend: trend)
          }
        }
      }

      Spacer(minLength: 8)

      if let best = bestPrice {
        VStack(alignment: .trailing, spacing: 2) {
          Text(priceText(for: best))
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(AppTheme.inStock)
            .monospacedDigit()

          if displayMode == .perMg, best.isOnSale {
            Text(CurrencyFormatter.format(best.effectivePrice))
              .font(.caption2)
              .foregroundStyle(AppTheme.sale)
          }
        }
      } else {
        Text("—")
          .font(.subheadline)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.vertical, 8)
    .contentShape(Rectangle())
  }

  private var subtitle: String {
    guard let dose = summaryDose else { return "No prices yet" }
    if vendorCount == 0 {
      return "\(dose.displayName) · no stock"
    }
    let vendorLabel = vendorCount == 1 ? "1 vendor" : "\(vendorCount) vendors"
    return "\(vendorLabel) · \(dose.displayName)"
  }

  private func priceText(for price: Price) -> String {
    switch displayMode {
    case .perMg:
      return price.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—"
    case .total:
      return CurrencyFormatter.format(price.effectivePrice)
    }
  }
}

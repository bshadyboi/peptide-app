import Foundation
import SwiftData

struct HomeHighlight {
  let peptide: Peptide
  let title: String
  let subtitle: String
  let detail: String

  static func load(from peptides: [Peptide], context: ModelContext) -> HomeHighlight? {
    if let drop = biggestDrop(among: peptides, context: context) { return drop }
    return bestDeal(among: peptides)
  }

  private static func biggestDrop(among peptides: [Peptide], context: ModelContext) -> HomeHighlight? {
    let since = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    let descriptor = FetchDescriptor<PricePoint>(
      predicate: #Predicate { $0.capturedAt >= since }
    )
    guard let points = try? context.fetch(descriptor), !points.isEmpty else { return nil }
    let byDose = Dictionary(grouping: points, by: \.doseId)

    var winner: (Peptide, PriceTrend)?
    for slug in PeptideCatalog.popularSlugs.prefix(12) {
      guard let peptide = peptides.first(where: { $0.slug == slug }),
            let dose = peptide.defaultDose,
            let dosePoints = byDose[dose.id] else { continue }
      let current = Price.sortedForCompare(dose.prices).first(where: \.inStock)?.pricePerMg
      let trend = PriceHistoryAnalytics.trend(
        for: dose.id,
        currentBestPerMg: current,
        points: dosePoints
      )
      guard trend.isDrop, let change = trend.changePercent else { continue }
      if let (_, existingTrend) = winner,
         let existingChange = existingTrend.changePercent,
         change >= existingChange {
        continue
      }
      winner = (peptide, trend)
    }

    guard let (peptide, trend) = winner, let change = trend.changePercent else { return nil }
    let pct = NSDecimalNumber(decimal: abs(change)).intValue
    let price = peptide.defaultDose.flatMap { dose in
      Price.sortedForCompare(dose.prices).first(where: \.inStock)?.pricePerMg
    }
    return HomeHighlight(
      peptide: peptide,
      title: "Biggest drop",
      subtitle: "\(peptide.name) ↓ \(pct)%",
      detail: price.map { "from \(CurrencyFormatter.formatPerMg($0))" } ?? "Tap to compare"
    )
  }

  private static func bestDeal(among peptides: [Peptide]) -> HomeHighlight? {
    var best: (Peptide, Price, Dose)?
    for slug in PeptideCatalog.popularSlugs.prefix(12) {
      guard let peptide = peptides.first(where: { $0.slug == slug }),
            let price = PeptideDeals.bestDealPrice(for: peptide),
            let dose = price.dose,
            let ppm = price.pricePerMg else { continue }
      if best == nil || ppm < (best!.1.pricePerMg ?? Decimal.greatestFiniteMagnitude) {
        best = (peptide, price, dose)
      }
    }
    guard let (peptide, price, dose) = best, let ppm = price.pricePerMg else { return nil }
    var detail = "\(price.vendor?.name ?? "Vendor") · \(CurrencyFormatter.formatPerMg(ppm))"
    if let code = price.discountCode { detail += " · \(code.uppercased())" }
    return HomeHighlight(
      peptide: peptide,
      title: "Best deal",
      subtitle: "\(peptide.name) · \(dose.displayName)",
      detail: detail
    )
  }
}

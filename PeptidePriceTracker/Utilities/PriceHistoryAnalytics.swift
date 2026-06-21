import Foundation

struct PriceTrend {
  let changePercent: Decimal?
  let isLowestEver: Bool
  let daysOfHistory: Int?
  let historicalLow: Decimal?

  var isDrop: Bool {
    guard let changePercent else { return false }
    return changePercent < 0
  }

  var isRise: Bool {
    guard let changePercent else { return false }
    return changePercent > 0
  }
}

enum PriceHistoryAnalytics {
  /// Best market $/mg per calendar day across all vendors.
  static func dailyBestPrices(from points: [PricePoint]) -> [(date: Date, pricePerMg: Decimal)] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: points) { point in
      calendar.startOfDay(for: point.capturedAt)
    }

    return grouped.compactMap { day, dayPoints in
      guard let min = dayPoints.compactMap(\.pricePerMg).min() else { return nil }
      return (day, min)
    }
    .sorted { $0.date < $1.date }
  }

  static func trend(
    for doseID: UUID,
    currentBestPerMg: Decimal?,
    points: [PricePoint],
    lookbackDays: Int = 30
  ) -> PriceTrend {
    let dosePoints = points.filter { $0.doseId == doseID && $0.pricePerMg != nil }
    guard !dosePoints.isEmpty else {
      return PriceTrend(changePercent: nil, isLowestEver: false, daysOfHistory: nil, historicalLow: nil)
    }

    let daily = dailyBestPrices(from: dosePoints)
    let historicalLow = daily.map(\.pricePerMg).min()
    let calendar = Calendar.current
    let firstDay = daily.first?.date
    let daysOfHistory: Int? = {
      guard let firstDay else { return nil }
      return calendar.dateComponents([.day], from: firstDay, to: .now).day
    }()

    guard let current = currentBestPerMg, current > 0 else {
      return PriceTrend(
        changePercent: nil,
        isLowestEver: false,
        daysOfHistory: daysOfHistory,
        historicalLow: historicalLow
      )
    }

    let isLowestEver: Bool = {
      guard let historicalLow else { return false }
      return current <= historicalLow
    }()

    let cutoff = calendar.date(byAdding: .day, value: -lookbackDays, to: .now) ?? .now
    let baseline = daily.last(where: { $0.date <= cutoff })?.pricePerMg ?? daily.first?.pricePerMg

    let changePercent: Decimal? = {
      guard let baseline, baseline > 0 else { return nil }
      return ((current - baseline) / baseline) * 100
    }()

    return PriceTrend(
      changePercent: changePercent,
      isLowestEver: isLowestEver,
      daysOfHistory: daysOfHistory,
      historicalLow: historicalLow
    )
  }
}

enum PeptideDeals {
  static func hasActiveDeal(_ peptide: Peptide) -> Bool {
    peptide.doses.flatMap(\.prices).contains { price in
      price.inStock && (price.isOnSale || price.discountCode != nil)
    }
  }

  static func bestDealPrice(for peptide: Peptide) -> Price? {
    let candidates = peptide.doses.flatMap(\.prices).filter { price in
      price.inStock && (price.isOnSale || price.discountCode != nil)
    }
    return Price.sortedForCompare(candidates).first
  }
}

enum ShareBestDeal {
  static func message(peptide: Peptide, dose: Dose, price: Price) -> String {
    var lines = [
      "\(peptide.name) · \(dose.displayName)",
      "Best: \(price.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—") at \(price.vendor?.name ?? "Unknown")",
      "Total: \(CurrencyFormatter.format(price.effectivePrice))",
    ]
    if let code = price.discountCode {
      lines.append("Code: \(code.uppercased())")
    }
    if let url = price.productUrl, !url.isEmpty {
      lines.append(url)
    }
    lines.append("via Peptide Prices")
    return lines.joined(separator: "\n")
  }
}

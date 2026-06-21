import SwiftUI

struct VendorCompareTable: View {
  let prices: [Price]
  let bestPriceID: UUID?

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(prices.enumerated()), id: \.element.id) { index, price in
        VendorCompareTableRow(
          price: price,
          isBest: price.inStock && price.id == bestPriceID
        )
        if index < prices.count - 1 { Divider() }
      }
    }
    .background(AppTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

struct VendorCompareTableRow: View {
  let price: Price
  let isBest: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(price.vendor?.name ?? "Unknown")
            .fontWeight(isBest ? .bold : .medium)
          if price.isOnSale {
            Text(CurrencyFormatter.format(price.price))
              .font(.caption2)
              .strikethrough()
              .foregroundStyle(.secondary)
          }
        }
        Spacer()
        Text(price.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—")
          .fontWeight(.semibold)
          .foregroundStyle(price.inStock ? AppTheme.inStock : .secondary)
          .monospacedDigit()
      }

      HStack(spacing: 8) {
        if isBest { Text("Best").font(.caption2.weight(.bold)).foregroundStyle(AppTheme.inStock) }
        if !price.inStock { Text("Out of stock").font(.caption2).foregroundStyle(.secondary) }
        if price.discountCode != nil || price.productUrl != nil {
          ShopButton(price: price, compact: true)
        }
        Spacer()
      }
    }
    .padding(12)
    .opacity(price.inStock ? 1 : 0.5)
  }
}

struct DetailBestPriceBanner: View {
  let price: Price
  var trend: PriceTrend?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        if let ppm = price.pricePerMg {
          Text(CurrencyFormatter.formatPerMg(ppm))
            .font(.title.weight(.bold))
            .foregroundStyle(AppTheme.inStock)
            .monospacedDigit()
        }
        Spacer()
        Text(CurrencyFormatter.format(price.effectivePrice))
          .foregroundStyle(.secondary)
      }
      Text(price.vendor?.name ?? "Unknown")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      if let trend { PriceDropBadge(trend: trend) }
      ShopButton(price: price)
    }
    .padding(14)
    .background(AppTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

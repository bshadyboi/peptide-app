import SwiftUI

struct VendorCompareTable: View {
  let prices: [Price]
  let bestPriceID: UUID?

  var body: some View {
    VStack(spacing: 0) {
      CompareTableHeader()

      ForEach(Array(prices.enumerated()), id: \.element.id) { index, price in
        VendorCompareTableRow(
          price: price,
          isBest: price.inStock && price.id == bestPriceID
        )

        if index < prices.count - 1 {
          Divider()
            .padding(.leading, 12)
        }
      }
    }
    .background(AppTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
    }
  }
}

private struct CompareTableHeader: View {
  var body: some View {
    HStack(spacing: 8) {
      Text("Supplier")
        .frame(maxWidth: .infinity, alignment: .leading)
      Text("Total")
        .frame(width: 52, alignment: .trailing)
      Text("$/mg")
        .frame(width: 58, alignment: .trailing)
      Color.clear.frame(width: 10)
    }
    .font(.caption2)
    .fontWeight(.semibold)
    .foregroundStyle(.secondary)
    .textCase(.uppercase)
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(Color(.tertiarySystemGroupedBackground))
  }
}

struct VendorCompareTableRow: View {
  let price: Price
  let isBest: Bool

  @State private var copied = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text(price.vendor?.name ?? "Unknown")
          .font(.subheadline)
          .fontWeight(isBest ? .bold : .medium)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)

        VStack(alignment: .trailing, spacing: 1) {
          Text(CurrencyFormatter.format(price.effectivePrice))
            .font(.subheadline)
            .monospacedDigit()
          if price.isOnSale {
            Text(CurrencyFormatter.format(price.price))
              .font(.caption2)
              .strikethrough()
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
        }
        .frame(width: 52, alignment: .trailing)

        Text(price.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—")
          .font(.subheadline)
          .fontWeight(isBest ? .bold : .semibold)
          .foregroundStyle(price.inStock ? (isBest ? AppTheme.inStock : .primary) : AppTheme.outOfStock)
          .monospacedDigit()
          .frame(width: 58, alignment: .trailing)

        Circle()
          .fill(price.inStock ? AppTheme.inStock : Color.secondary.opacity(0.35))
          .frame(width: 8, height: 8)
      }

      HStack(spacing: 8) {
        if isBest {
          Text("Best")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(AppTheme.inStock)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.inStock.opacity(0.12))
            .clipShape(Capsule())
        }

        if price.coaAvailable {
          COABadge()
        }

        if let code = price.discountCode {
          DiscountPill(code: code, copied: $copied)
        }

        ProductLinkButton(urlString: price.productUrl)

        Spacer()
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(isBest ? AppTheme.inStock.opacity(0.06) : Color.clear)
    .opacity(price.inStock ? 1 : 0.55)
  }
}

struct DetailBestPriceBanner: View {
  let price: Price
  let vendorCount: Int
  var trend: PriceTrend?

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Lowest $/mg")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .textCase(.uppercase)

        if let ppm = price.pricePerMg {
          Text(CurrencyFormatter.formatPerMg(ppm))
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.inStock)
            .monospacedDigit()
        }

        if let trend {
          PriceDropBadge(trend: trend)
        }

        Text("\(price.vendor?.name ?? "Unknown") · \(CurrencyFormatter.format(price.effectivePrice)) total")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        Text("\(vendorCount)")
          .font(.title2)
          .fontWeight(.bold)
          .monospacedDigit()
        Text(vendorCount == 1 ? "vendor" : "vendors")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding(16)
    .background(AppTheme.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(AppTheme.inStock.opacity(0.2), lineWidth: 1)
    }
  }
}

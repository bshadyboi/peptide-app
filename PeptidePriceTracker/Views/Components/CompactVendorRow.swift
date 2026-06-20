import SwiftUI

struct CompactVendorRow: View {
  let price: Price
  let displayMode: PriceDisplayMode
  let isBest: Bool

  @State private var copied = false

  var body: some View {
    HStack(spacing: 10) {
      VendorAvatar(name: price.vendor?.name ?? "?")

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(price.vendor?.name ?? "Unknown")
            .font(.subheadline)
            .fontWeight(.semibold)
            .lineLimit(1)

          if isBest {
            Text("Best")
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundStyle(AppTheme.inStock)
          }
        }

        HStack(spacing: 6) {
          StockBadge(inStock: price.inStock)
          if let code = price.discountCode {
            DiscountPill(code: code, copied: $copied)
          }
          ProductLinkButton(urlString: price.productUrl)
        }
      }

      Spacer(minLength: 8)

      VStack(alignment: .trailing, spacing: 2) {
        Text(primaryPriceText)
          .font(.subheadline)
          .fontWeight(.bold)
          .foregroundStyle(price.inStock ? .primary : AppTheme.outOfStock)

        if price.isOnSale {
          Text(CurrencyFormatter.format(price.price))
            .font(.caption2)
            .strikethrough()
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 6)
    .opacity(price.inStock ? 1 : 0.55)
  }

  private var primaryPriceText: String {
    switch displayMode {
    case .perMg:
      if let ppm = price.pricePerMg {
        return CurrencyFormatter.formatPerMg(ppm)
      }
      return "—"
    case .total:
      return CurrencyFormatter.format(price.effectivePrice)
    }
  }
}

struct VendorAvatar: View {
  let name: String

  private var initials: String {
    let parts = name.split(separator: " ").prefix(2)
    return parts.map { String($0.prefix(1)).uppercased() }.joined()
  }

  var body: some View {
    Text(initials.isEmpty ? "?" : initials)
      .font(.caption2)
      .fontWeight(.bold)
      .foregroundStyle(AppTheme.accent)
      .frame(width: 36, height: 36)
      .background(AppTheme.accentSoft)
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

struct StockBadge: View {
  let inStock: Bool

  var body: some View {
    Text(inStock ? "In stock" : "Out of stock")
      .font(.caption2)
      .fontWeight(.medium)
      .foregroundStyle(inStock ? AppTheme.inStock : AppTheme.outOfStock)
  }
}

struct DiscountPill: View {
  let code: String
  @Binding var copied: Bool

  var body: some View {
    Button {
      UIPasteboard.general.string = code
      copied = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
    } label: {
      Text(copied ? "Copied" : code.uppercased())
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundStyle(AppTheme.sale)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(AppTheme.sale.opacity(0.12))
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}

struct CategoryTag: View {
  let label: String
  var tint: Color = AppTheme.accent

  var body: some View {
    Text(label.uppercased())
      .font(.caption2)
      .fontWeight(.bold)
      .tracking(0.5)
      .foregroundStyle(tint)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(tint.opacity(0.12))
      .clipShape(Capsule())
  }
}

import SwiftUI

struct PriceDropBadge: View {
  let trend: PriceTrend

  var body: some View {
    if trend.isLowestEver {
      badge(text: "Lowest ever", icon: "arrow.down.to.line", color: AppTheme.inStock)
    } else if let change = trend.changePercent, abs(change) >= 1 {
      if change < 0 {
        badge(
          text: "↓ \(formatPercent(abs(change)))",
          icon: "arrow.down.right",
          color: AppTheme.inStock
        )
      } else {
        badge(
          text: "↑ \(formatPercent(change))",
          icon: "arrow.up.right",
          color: AppTheme.sale
        )
      }
    }
  }

  @ViewBuilder
  private func badge(text: String, icon: String, color: Color) -> some View {
    Label(text, systemImage: icon)
      .font(.caption2)
      .fontWeight(.bold)
      .foregroundStyle(color)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(color.opacity(0.12))
      .clipShape(Capsule())
  }

  private func formatPercent(_ value: Decimal) -> String {
    let number = NSDecimalNumber(decimal: value)
    return String(format: "%.0f%%", number.doubleValue)
  }
}

struct DealBadge: View {
  var body: some View {
    Text("Deal")
      .font(.caption2)
      .fontWeight(.bold)
      .foregroundStyle(AppTheme.sale)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(AppTheme.sale.opacity(0.12))
      .clipShape(Capsule())
  }
}

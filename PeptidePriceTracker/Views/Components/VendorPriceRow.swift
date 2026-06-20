import SwiftUI

struct VendorPriceRow: View {
    let price: Price
    let isBest: Bool

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(price.vendor?.name ?? "Unknown vendor")
                            .font(.headline)

                        if isBest {
                            Text("Best")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }

                    if !price.inStock {
                        Text("Out of stock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let ppm = price.pricePerMg {
                        Text(CurrencyFormatter.formatPerMg(ppm))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    HStack(spacing: 4) {
                        if price.isOnSale {
                            Text(CurrencyFormatter.format(price.price))
                                .strikethrough()
                                .foregroundStyle(.secondary)
                        }
                        Text(CurrencyFormatter.format(price.effectivePrice))
                            .font(.subheadline)
                    }
                }
            }

            HStack(spacing: 12) {
                if price.coaAvailable {
                    COABadge()
                }

                if let code = price.discountCode {
                    DiscountCodeChip(code: code, copied: $copied)
                }

                ProductLinkButton(urlString: price.productUrl)

                Spacer()
            }
        }
        .padding(.vertical, 4)
        .opacity(price.inStock ? 1 : 0.45)
    }
}

private struct DiscountCodeChip: View {
    let code: String
    @Binding var copied: Bool

    var body: some View {
        Button {
            UIPasteboard.general.string = code
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption2)
                Text(copied ? "Copied" : code)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Copy discount code \(code)")
    }
}

import SwiftUI

struct BestPriceCard: View {
    let price: Price

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best price")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(price.vendor?.name ?? "Unknown vendor")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        if let ppm = price.pricePerMg {
                            Text(CurrencyFormatter.formatPerMg(ppm))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }

                        HStack(spacing: 4) {
                            if price.isOnSale {
                                Text(CurrencyFormatter.format(price.price))
                                    .strikethrough()
                                    .foregroundStyle(.secondary)
                            }
                            Text(CurrencyFormatter.format(price.effectivePrice))
                                .foregroundStyle(price.isOnSale ? .primary : .secondary)
                        }
                        .font(.subheadline)
                    }
                }

                Spacer()

                if price.coaAvailable {
                    COABadge()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .peptideCard()
    }
}

struct COABadge: View {
    var body: some View {
        Label("COA", systemImage: "checkmark.seal.fill")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .clipShape(Capsule())
    }
}

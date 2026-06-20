import Foundation
import SwiftData

enum PriceSource: String, Codable {
    case scrape
    case manual
    case crowdsource
}

@Model
final class Price {
    @Attribute(.unique) var id: UUID
    var price: Decimal
    var salePrice: Decimal?
    var currency: String
    var inStock: Bool
    var discountCode: String?
    var coaAvailable: Bool
    var productUrl: String?
    var sourceRaw: String
    var lastSeenAt: Date
    var createdAt: Date

    var dose: Dose?
    var vendor: Vendor?

    var source: PriceSource {
        get { PriceSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    /// Mirrors Postgres generated column: coalesce(sale_price, price) / mg
    var pricePerMg: Decimal? {
        guard let dose, dose.mg > 0 else { return nil }
        let effective = salePrice ?? price
        return effective / dose.mg
    }

    var effectivePrice: Decimal {
        salePrice ?? price
    }

    var isOnSale: Bool {
        salePrice != nil
    }

    init(
        id: UUID = UUID(),
        price: Decimal,
        salePrice: Decimal? = nil,
        currency: String = "USD",
        inStock: Bool = true,
        discountCode: String? = nil,
        coaAvailable: Bool = false,
        productUrl: String? = nil,
        source: PriceSource = .manual,
        lastSeenAt: Date = .now,
        createdAt: Date = .now,
        dose: Dose? = nil,
        vendor: Vendor? = nil
    ) {
        self.id = id
        self.price = price
        self.salePrice = salePrice
        self.currency = currency
        self.inStock = inStock
        self.discountCode = discountCode
        self.coaAvailable = coaAvailable
        self.productUrl = productUrl
        self.sourceRaw = source.rawValue
        self.lastSeenAt = lastSeenAt
        self.createdAt = createdAt
        self.dose = dose
        self.vendor = vendor
    }
}

extension Price {
    var isVisibleInCompare: Bool {
        vendor?.isActive ?? true
    }

    /// Sort in-stock by price_per_mg ascending, then out-of-stock (also by price_per_mg).
    static func sortedForCompare(_ prices: [Price], inStockOnly: Bool = false) -> [Price] {
        prices
            .filter { $0.isVisibleInCompare && (!inStockOnly || $0.inStock) }
            .sorted { lhs, rhs in
            if lhs.inStock != rhs.inStock {
                return lhs.inStock && !rhs.inStock
            }
            let lhsPpm = lhs.pricePerMg ?? .sortSentinel
            let rhsPpm = rhs.pricePerMg ?? .sortSentinel
            return lhsPpm < rhsPpm
        }
    }
}

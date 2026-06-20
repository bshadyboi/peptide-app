import Foundation
import SwiftData

enum PeptideCategory: String, Codable, CaseIterable {
    case single
    case blend
}

@Model
final class Peptide {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(.unique) var slug: String
    var categoryRaw: String
    var aliases: [String]
    var peptideDescription: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Dose.peptide)
    var doses: [Dose] = []

    @Relationship(deleteRule: .cascade, inverse: \BlendComponent.peptide)
    var blendComponents: [BlendComponent] = []

    var category: PeptideCategory {
        get { PeptideCategory(rawValue: categoryRaw) ?? .single }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        slug: String,
        category: PeptideCategory,
        aliases: [String] = [],
        description: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.categoryRaw = category.rawValue
        self.aliases = aliases
        self.peptideDescription = description
        self.createdAt = createdAt
    }

    /// Lowest in-stock price_per_mg across all doses (for home list).
    var bestPricePerMg: Decimal? {
        let inStockPrices = doses.flatMap(\.prices).filter(\.inStock)
        return inStockPrices.compactMap(\.pricePerMg).min()
    }
}

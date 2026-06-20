import Foundation
import SwiftData

@Model
final class Dose {
    @Attribute(.unique) var id: UUID
    var mg: Decimal
    var label: String?

    var peptide: Peptide?

    @Relationship(deleteRule: .cascade, inverse: \Price.dose)
    var prices: [Price] = []

    @Relationship(deleteRule: .cascade, inverse: \PricePoint.dose)
    var pricePoints: [PricePoint] = []

    @Relationship(deleteRule: .cascade, inverse: \PriceAlert.dose)
    var alerts: [PriceAlert] = []

    init(id: UUID = UUID(), mg: Decimal, label: String? = nil, peptide: Peptide? = nil) {
        self.id = id
        self.mg = mg
        self.label = label
        self.peptide = peptide
    }

    var displayName: String {
        if let label, !label.isEmpty {
            return "\(Self.formatMg(mg)) · \(label)"
        }
        return Self.formatMg(mg)
    }

    static func formatMg(_ mg: Decimal) -> String {
        let number = NSDecimalNumber(decimal: mg)
        if number.doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(number.intValue)mg"
        }
        return "\(number)mg"
    }
}

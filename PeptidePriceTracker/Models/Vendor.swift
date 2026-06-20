import Foundation
import SwiftData

@Model
final class Vendor {
    @Attribute(.unique) var id: UUID
    var name: String
    var url: String?
    var shipsFrom: String?
    var notes: String?
    var isActive: Bool

    @Relationship(deleteRule: .nullify, inverse: \Price.vendor)
    var prices: [Price] = []

    init(
        id: UUID = UUID(),
        name: String,
        url: String? = nil,
        shipsFrom: String? = nil,
        notes: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.shipsFrom = shipsFrom
        self.notes = notes
        self.isActive = isActive
    }
}

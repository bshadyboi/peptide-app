import Foundation
import SwiftData

@Model
final class PricePoint {
  @Attribute(.unique) var id: UUID
  var doseId: UUID
  var vendorId: UUID
  var price: Decimal
  var pricePerMg: Decimal?
  var capturedAt: Date

  var dose: Dose?
  var vendor: Vendor?

  init(
    id: UUID = UUID(),
    doseId: UUID,
    vendorId: UUID,
    price: Decimal,
    pricePerMg: Decimal? = nil,
    capturedAt: Date = .now,
    dose: Dose? = nil,
    vendor: Vendor? = nil
  ) {
    self.id = id
    self.doseId = doseId
    self.vendorId = vendorId
    self.price = price
    self.pricePerMg = pricePerMg
    self.capturedAt = capturedAt
    self.dose = dose
    self.vendor = vendor
  }
}

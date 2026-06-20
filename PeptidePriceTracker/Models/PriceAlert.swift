import Foundation
import SwiftData

@Model
final class PriceAlert {
  @Attribute(.unique) var id: UUID
  var doseId: UUID
  var targetPerMg: Decimal
  var active: Bool
  var lastFiredAt: Date?
  var createdAt: Date

  var dose: Dose?

  init(
    id: UUID = UUID(),
    doseId: UUID,
    targetPerMg: Decimal,
    active: Bool = true,
    lastFiredAt: Date? = nil,
    createdAt: Date = .now,
    dose: Dose? = nil
  ) {
    self.id = id
    self.doseId = doseId
    self.targetPerMg = targetPerMg
    self.active = active
    self.lastFiredAt = lastFiredAt
    self.createdAt = createdAt
    self.dose = dose
  }

  /// True when the current best in-stock price meets the target.
  func isTriggered(bestPricePerMg: Decimal?) -> Bool {
    guard active, let bestPricePerMg else { return false }
    return bestPricePerMg <= targetPerMg
  }
}

import Foundation
import SwiftData

@Model
final class BlendComponent {
  @Attribute(.unique) var id: UUID
  var blendId: UUID
  var componentName: String
  var componentSlug: String
  var mg: Decimal

  var peptide: Peptide?

  init(
    id: UUID = UUID(),
    blendId: UUID,
    componentName: String,
    componentSlug: String,
    mg: Decimal,
    peptide: Peptide? = nil
  ) {
    self.id = id
    self.blendId = blendId
    self.componentName = componentName
    self.componentSlug = componentSlug
    self.mg = mg
    self.peptide = peptide
  }

  var displayLine: String {
    "\(componentName) · \(Dose.formatMg(mg))"
  }
}

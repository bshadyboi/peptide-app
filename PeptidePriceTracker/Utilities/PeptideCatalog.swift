import Foundation

enum PriceDisplayMode: String, CaseIterable {
  case perMg = "$/mg"
  case total = "Total"
}

enum PeptideSortOption: String, CaseIterable {
  case popularity = "Popular"
  case name = "Name"
  case price = "Price"
}

enum PeptideTopic: String, CaseIterable, Identifiable {
  case all = "All"
  case healing = "Healing"
  case growth = "Growth"
  case glp = "GLP-1"
  case cosmetic = "Cosmetic"
  case cognitive = "Cognitive"
  case longevity = "Longevity"

  var id: String { rawValue }
}

enum PeptideCatalog {
  /// Blend components and internal rows — hide from Home browse (still in DB for blends).
  static let hiddenFromBrowseSlugs: Set<String> = [
    "cjc-1295-no-dac",
  ]

  static let popularSlugs: [String] = [
    "bpc-157",
    "tb-500",
    "semaglutide",
    "tirzepatide",
    "retatrutide",
    "ipamorelin",
    "tesamorelin",
    "ghk-cu",
    "bpc-tb-blend",
    "cjc-ipa-blend",
    "ghrp-6",
    "sermorelin",
    "melanotan-ii",
    "semax",
    "epitalon",
  ]

  static func topic(for slug: String) -> PeptideTopic {
    switch slug {
    case "bpc-157", "tb-500", "bpc-tb-blend":
      return .healing
    case "ipamorelin", "tesamorelin", "sermorelin", "ghrp-6", "ghrp-2",
         "cjc-1295-dac", "cjc-1295-no-dac", "hexarelin", "cjc-ipa-blend":
      return .growth
    case "semaglutide", "tirzepatide", "retatrutide":
      return .glp
    case "melanotan-ii", "pt-141", "ghk-cu":
      return .cosmetic
    case "selank", "semax", "dsip":
      return .cognitive
    case "epitalon", "mots-c", "aod-9604":
      return .longevity
    default:
      return .all
    }
  }

  static func displayCategory(for slug: String) -> String? {
    let topic = topic(for: slug)
    return topic == .all ? nil : topic.rawValue
  }

  static func popularityRank(for slug: String) -> Int {
    popularSlugs.firstIndex(of: slug) ?? Int.max
  }
}

extension Peptide {
  var sortedDoses: [Dose] {
    doses.sorted { $0.mg < $1.mg }
  }

  var defaultDose: Dose? {
    sortedDoses.first { $0.mg == 5 } ?? sortedDoses.first
  }

  func topPrices(for dose: Dose, limit: Int = 3) -> [Price] {
    Array(Price.sortedForCompare(dose.prices).prefix(limit))
  }

  func remainingVendorCount(for dose: Dose, previewLimit: Int = 3) -> Int {
    max(0, Price.sortedForCompare(dose.prices).count - previewLimit)
  }
}

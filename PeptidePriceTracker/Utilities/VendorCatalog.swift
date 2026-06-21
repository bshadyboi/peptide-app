import Foundation

struct LiveVendorSummary: Identifiable, Hashable {
  let vendor: Vendor
  let inStockPriceCount: Int

  var id: UUID { vendor.id }
  var name: String { vendor.name }
}

enum VendorCatalog {
  static func liveVendors(from vendors: [Vendor], prices: [Price]) -> [LiveVendorSummary] {
    let activeVendorIDs = Set(vendors.filter(\.isActive).map(\.id))
    var counts: [UUID: Int] = [:]

    for price in prices where price.inStock {
      guard let vendorID = price.vendor?.id, activeVendorIDs.contains(vendorID) else { continue }
      counts[vendorID, default: 0] += 1
    }

    return vendors
      .filter { counts[$0.id, default: 0] > 0 }
      .map { LiveVendorSummary(vendor: $0, inStockPriceCount: counts[$0.id, default: 0]) }
      .sorted {
        if $0.inStockPriceCount != $1.inStockPriceCount {
          return $0.inStockPriceCount > $1.inStockPriceCount
        }
        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
      }
  }

  static func peptideHasInStockPrice(from vendorID: UUID, peptide: Peptide) -> Bool {
    peptide.doses.flatMap(\.prices).contains { price in
      price.inStock
        && price.vendor?.id == vendorID
        && (price.vendor?.isActive ?? true)
    }
  }
}

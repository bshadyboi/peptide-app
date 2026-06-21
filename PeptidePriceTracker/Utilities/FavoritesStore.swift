import Foundation
import SwiftUI

@MainActor
final class FavoritesStore: ObservableObject {
  @AppStorage("favoritePeptideSlugs") private var storedSlugs = ""

  private var slugSet: Set<String> {
    get {
      Set(
        storedSlugs
          .split(separator: ",")
          .map { $0.trimmingCharacters(in: .whitespaces) }
          .filter { !$0.isEmpty }
      )
    }
    set {
      storedSlugs = newValue.sorted().joined(separator: ",")
      objectWillChange.send()
    }
  }

  func isFavorite(_ slug: String) -> Bool {
    slugSet.contains(slug)
  }

  func toggle(_ slug: String) {
    var set = slugSet
    if set.contains(slug) {
      set.remove(slug)
    } else {
      set.insert(slug)
    }
    slugSet = set
  }

  func sortedPeptides(from all: [Peptide]) -> [Peptide] {
    let order = slugSet
    return all
      .filter { order.contains($0.slug) }
      .sorted { a, b in
        let ra = PeptideCatalog.popularityRank(for: a.slug)
        let rb = PeptideCatalog.popularityRank(for: b.slug)
        if ra != rb { return ra < rb }
        return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
      }
  }
}

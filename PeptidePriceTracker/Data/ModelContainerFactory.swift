import SwiftUI
import SwiftData

/// Bump when SwiftData models change incompatibly (forces a one-time local cache reset).
enum AppSchema {
  static let version = 2
}

enum ModelContainerFactory {
  static let shared: ModelContainer = {
    resetStoreIfNeeded()

    let schema = Schema([
      Peptide.self,
      Dose.self,
      Vendor.self,
      Price.self,
      PricePoint.self,
      PriceAlert.self,
      BlendComponent.self,
    ])

    do {
      return try ModelContainer(for: schema)
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  private static func resetStoreIfNeeded() {
    let defaults = UserDefaults.standard
    let key = "swiftdata_schema_version"
    guard defaults.integer(forKey: key) != AppSchema.version else { return }

    defaults.set(AppSchema.version, forKey: key)

    guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return
    }

    if let contents = try? FileManager.default.contentsOfDirectory(at: support, includingPropertiesForKeys: nil) {
      for url in contents where url.lastPathComponent.hasSuffix(".store") || url.pathExtension == "store" {
        try? FileManager.default.removeItem(at: url)
      }
    }
  }
}

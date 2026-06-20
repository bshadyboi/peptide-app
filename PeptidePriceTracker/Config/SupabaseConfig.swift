import Foundation

enum SupabaseConfig {
  static var url: URL? {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
      !raw.isEmpty,
      !raw.contains("your-project"),
      !raw.hasPrefix("$("),
      let url = URL(string: raw)
    else { return nil }
    return url
  }

  static var anonKey: String? {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
      !key.isEmpty,
      !key.contains("your-anon-key"),
      !key.contains("your-publishable-key"),
      !key.hasPrefix("$(")
    else { return nil }
    return key
  }

  static var isConfigured: Bool {
    url != nil && anonKey != nil
  }
}

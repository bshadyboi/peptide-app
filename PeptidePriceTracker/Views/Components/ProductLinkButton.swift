import SwiftUI

struct ShopButton: View {
  let price: Price
  var compact = false

  private var url: URL? {
    guard let raw = price.productUrl, !raw.isEmpty else { return nil }
    return URL(string: raw)
  }

  var body: some View {
    Button(action: shop) {
      Label(compact ? "Shop" : "Copy code & shop", systemImage: "cart")
        .font(.caption)
        .fontWeight(.semibold)
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    .disabled(url == nil)
  }

  private func shop() {
    if let code = price.discountCode {
      UIPasteboard.general.string = code
    }
    if let url { UIApplication.shared.open(url) }
  }
}

/// Legacy helper for unused card components.
struct ProductLinkButton: View {
  let urlString: String?

  var body: some View {
    if let urlString, let url = URL(string: urlString) {
      Link("Shop", destination: url).font(.caption)
    }
  }
}

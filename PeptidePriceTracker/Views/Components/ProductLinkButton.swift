import SwiftUI

struct ProductLinkButton: View {
  let urlString: String?

  private var url: URL? {
    guard let urlString, !urlString.isEmpty else { return nil }
    return URL(string: urlString)
  }

  var body: some View {
    if let url {
      Link(destination: url) {
        Label("Shop", systemImage: "arrow.up.right.square")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.accent)
      }
    }
  }
}

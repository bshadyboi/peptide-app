import SwiftUI

enum AppTheme {
  static let accent = Color(red: 0.08, green: 0.52, blue: 0.62)
  static let accentSoft = Color(red: 0.08, green: 0.52, blue: 0.62).opacity(0.12)
  static let cardBackground = Color(.secondarySystemGroupedBackground)
  static let pageBackground = Color(.systemGroupedBackground)
  static let inStock = Color(red: 0.13, green: 0.59, blue: 0.33)
  static let outOfStock = Color.secondary
  static let sale = Color(red: 0.85, green: 0.33, blue: 0.22)

  static func cardShadow() -> some View {
    EmptyView()
  }
}

struct CardStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(AppTheme.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
  }
}

extension View {
  func peptideCard() -> some View {
    modifier(CardStyle())
  }
}

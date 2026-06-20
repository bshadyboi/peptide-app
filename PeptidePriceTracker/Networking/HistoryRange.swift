import Foundation

enum HistoryRange: String, CaseIterable, Identifiable {
  case days30 = "30d"
  case days90 = "90d"
  case year1 = "1y"

  var id: String { rawValue }

  var label: String {
    switch self {
    case .days30: return "30d"
    case .days90: return "90d"
    case .year1: return "1y"
    }
  }

  var startDate: Date {
    let calendar = Calendar.current
    switch self {
    case .days30:
      return calendar.date(byAdding: .day, value: -30, to: .now) ?? .now
    case .days90:
      return calendar.date(byAdding: .day, value: -90, to: .now) ?? .now
    case .year1:
      return calendar.date(byAdding: .year, value: -1, to: .now) ?? .now
    }
  }

  var iso8601Since: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: startDate)
  }
}

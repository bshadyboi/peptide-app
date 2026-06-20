import Foundation

enum CurrencyFormatter {
    private static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let perMg: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = formatter.positivePrefix.map { $0 + "/mg" } ?? "$/mg"
        return formatter
    }()

    static func format(_ value: Decimal) -> String {
        currency.string(from: value as NSDecimalNumber) ?? "$\(value)"
    }

    static func formatPerMg(_ value: Decimal) -> String {
        let dollars = value as NSDecimalNumber
        let formatted = currency.string(from: dollars) ?? "$\(value)"
        return "\(formatted)/mg"
    }
}

extension Decimal {
    static let sortSentinel = Decimal(string: "999999999")!
}

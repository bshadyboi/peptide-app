import Foundation

// MARK: - Responses

struct PeptideDTO: Decodable {
  let id: UUID
  let name: String
  let slug: String
  let category: String
  let aliases: [String]?
  let description: String?
  let createdAt: Date?
  let doses: [DoseDTO]?
  let blendComponents: [BlendComponentDTO]?
}

struct BlendComponentDTO: Decodable {
  let id: UUID
  let blendId: UUID?
  let componentId: UUID?
  let mg: JSONDecimal
  let component: BlendComponentPeptideDTO?
}

struct BlendComponentPeptideDTO: Decodable {
  let name: String
  let slug: String
}

struct DoseDTO: Decodable {
  let id: UUID
  let peptideId: UUID?
  let mg: JSONDecimal
  let label: String?
}

struct VendorDTO: Decodable {
  let id: UUID
  let name: String
  let url: String?
  let shipsFrom: String?
  let notes: String?
  let isActive: Bool?
}

struct PriceDTO: Decodable {
  let id: UUID
  let doseId: UUID
  let vendorId: UUID
  let price: JSONDecimal
  let salePrice: JSONDecimal?
  let pricePerMg: JSONDecimal?
  let currency: String?
  let inStock: Bool?
  let discountCode: String?
  let coaAvailable: Bool?
  let productUrl: String?
  let source: String
  let lastSeenAt: Date?
  let createdAt: Date?
  let vendors: VendorDTO?
}

struct PriceHistoryDTO: Decodable {
  let id: UUID
  let doseId: UUID
  let vendorId: UUID
  let price: JSONDecimal
  let pricePerMg: JSONDecimal?
  let capturedAt: Date
  let vendors: VendorNameDTO?
}

struct VendorNameDTO: Decodable {
  let name: String
}

struct AlertDTO: Decodable {
  let id: UUID
  let userId: UUID
  let doseId: UUID
  let targetPerMg: JSONDecimal
  let active: Bool?
  let lastFiredAt: Date?
  let createdAt: Date?
}

struct AlertWriteDTO: Encodable {
  let userId: UUID
  let doseId: UUID
  let targetPerMg: Double
  let active: Bool

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case doseId = "dose_id"
    case targetPerMg = "target_per_mg"
    case active
  }
}

struct SubmissionWriteDTO: Encodable {
  let userId: UUID
  let doseId: UUID
  let vendorName: String
  let price: Double
  let discountCode: String?

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case doseId = "dose_id"
    case vendorName = "vendor_name"
    case price
    case discountCode = "discount_code"
  }
}

struct DeviceWriteDTO: Encodable {
  let userId: UUID
  let apnsToken: String

  enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case apnsToken = "apns_token"
  }
}

/// Postgres `numeric` may decode as a JSON string or number.
struct JSONDecimal: Decodable {
  let value: Decimal

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let string = try? container.decode(String.self) {
      guard let decimal = Decimal(string: string) else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid decimal: \(string)")
      }
      value = decimal
    } else if let double = try? container.decode(Double.self) {
      value = Decimal(double)
    } else if let int = try? container.decode(Int.self) {
      value = Decimal(int)
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected decimal")
    }
  }
}

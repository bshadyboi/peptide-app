import Foundation

enum APIError: LocalizedError {
  case notConfigured
  case invalidURL
  case httpStatus(Int, String?)
  case decodingFailed(Error)

  var errorDescription: String? {
    switch self {
    case .notConfigured:
      return "Supabase is not configured. Copy Secrets.xcconfig.example to Secrets.xcconfig and add your project URL and anon key."
    case .invalidURL:
      return "Invalid API URL."
    case let .httpStatus(code, body):
      if let body, !body.isEmpty { return "Server error (\(code)): \(body)" }
      return "Server error (\(code))."
    case let .decodingFailed(error):
      return "Failed to decode response: \(error.localizedDescription)"
    }
  }
}

struct APIClient {
  private let baseURL: URL
  private let anonKey: String
  private let session: URLSession
  private let decoder: JSONDecoder

  init?() {
    guard let baseURL = SupabaseConfig.url,
      let anonKey = SupabaseConfig.anonKey
    else { return nil }

    self.baseURL = baseURL.appendingPathComponent("rest/v1")
    self.anonKey = anonKey
    self.session = .shared

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let raw = try container.decode(String.self)
      let formatters: [ISO8601DateFormatter] = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]
        return [withFraction, withoutFraction]
      }()
      for formatter in formatters {
        if let date = formatter.date(from: raw) { return date }
      }
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unrecognized date: \(raw)"
      )
    }
    self.decoder = decoder
  }

  private static let peptideSelect =
    "*,doses(*),blend_components!blend_components_blend_id_fkey(id,mg,component:peptides!blend_components_component_id_fkey(name,slug))"

  // GET /peptides?category=single|blend
  func fetchPeptides(category: PeptideCategory?) async throws -> [PeptideDTO] {
    var query: [URLQueryItem] = [
      URLQueryItem(name: "select", value: Self.peptideSelect),
      URLQueryItem(name: "order", value: "name.asc"),
    ]
    if let category {
      query.append(URLQueryItem(name: "category", value: "eq.\(category.rawValue)"))
    }
    return try await get("peptides", query: query)
  }

  // GET /peptides/:slug — peptide + doses
  func fetchPeptide(slug: String) async throws -> PeptideDTO {
    let query = [
      URLQueryItem(name: "slug", value: "eq.\(slug)"),
      URLQueryItem(name: "select", value: Self.peptideSelect),
    ]
    let rows: [PeptideDTO] = try await get("peptides", query: query)
    guard let peptide = rows.first else {
      throw APIError.httpStatus(404, "Peptide not found")
    }
    return peptide
  }

  // GET /doses/:id/prices — ordered by price_per_mg asc, out-of-stock last
  func fetchPrices(forDose doseID: UUID) async throws -> [PriceDTO] {
    let query = [
      URLQueryItem(name: "dose_id", value: "eq.\(doseID.uuidString.lowercased())"),
      URLQueryItem(name: "select", value: "*,vendors(*)"),
      URLQueryItem(name: "order", value: "in_stock.desc,price_per_mg.asc"),
    ]
    let rows: [PriceDTO] = try await get("prices", query: query)
    return rows.filter { $0.vendors?.isActive ?? true }
  }

  func fetchAllPrices() async throws -> [PriceDTO] {
    let query = [
      URLQueryItem(name: "select", value: "*,vendors(*)"),
      URLQueryItem(name: "order", value: "dose_id.asc,in_stock.desc,price_per_mg.asc"),
    ]
    let rows: [PriceDTO] = try await get("prices", query: query)
    return rows.filter { $0.vendors?.isActive ?? true }
  }

  func fetchAllVendors() async throws -> [VendorDTO] {
    let query = [URLQueryItem(name: "order", value: "name.asc")]
    return try await get("vendors", query: query)
  }

  // GET /doses/:id/history?range=30d|90d|1y
  func fetchPriceHistory(forDose doseID: UUID, range: HistoryRange) async throws -> [PriceHistoryDTO] {
    let query = [
      URLQueryItem(name: "dose_id", value: "eq.\(doseID.uuidString.lowercased())"),
      URLQueryItem(name: "captured_at", value: "gte.\(range.iso8601Since)"),
      URLQueryItem(name: "select", value: "*,vendors(name)"),
      URLQueryItem(name: "order", value: "captured_at.asc"),
    ]
    return try await get("price_history", query: query)
  }

  func fetchAlerts(accessToken: String) async throws -> [AlertDTO] {
    let query = [
      URLQueryItem(name: "select", value: "*"),
      URLQueryItem(name: "order", value: "created_at.desc"),
    ]
    return try await get("alerts", query: query, accessToken: accessToken)
  }

  func createAlert(doseID: UUID, targetPerMg: Decimal, accessToken: String) async throws -> AlertDTO {
    guard let userId = decodeUserId(from: accessToken) else {
      throw APIError.httpStatus(401, "Invalid session")
    }
    let payload = AlertWriteDTO(
      userId: userId,
      doseId: doseID,
      targetPerMg: NSDecimalNumber(decimal: targetPerMg).doubleValue,
      active: true
    )
    let rows: [AlertDTO] = try await post("alerts", body: payload, accessToken: accessToken)
    guard let alert = rows.first else {
      throw APIError.httpStatus(500, "No alert returned")
    }
    return alert
  }

  func deleteAlert(id: UUID, accessToken: String) async throws {
    try await delete("alerts", query: [
      URLQueryItem(name: "id", value: "eq.\(id.uuidString.lowercased())"),
    ], accessToken: accessToken)
  }

  func submitPrice(
    doseID: UUID,
    vendorName: String,
    price: Decimal,
    discountCode: String?,
    accessToken: String
  ) async throws {
    guard let userId = decodeUserId(from: accessToken) else {
      throw APIError.httpStatus(401, "Invalid session")
    }
    let payload = SubmissionWriteDTO(
      userId: userId,
      doseId: doseID,
      vendorName: vendorName,
      price: NSDecimalNumber(decimal: price).doubleValue,
      discountCode: discountCode?.isEmpty == true ? nil : discountCode
    )
    let _: [EmptyDTO] = try await post("price_submissions", body: payload, accessToken: accessToken)
  }

  func registerDevice(apnsToken: String, accessToken: String?) async throws {
    guard let accessToken,
      let userId = decodeUserId(from: accessToken)
    else { return }

    let payload = DeviceWriteDTO(userId: userId, apnsToken: apnsToken)
    let _: [EmptyDTO] = try await post(
      "user_devices",
      body: payload,
      accessToken: accessToken,
      prefer: "resolution=merge-duplicates"
    )
  }

  // MARK: - Private

  private struct EmptyDTO: Decodable {}

  private func decodeUserId(from accessToken: String) -> UUID? {
    let parts = accessToken.split(separator: ".")
    guard parts.count >= 2 else { return nil }
    var base64 = String(parts[1])
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    while base64.count % 4 != 0 { base64.append("=") }
    guard let data = Data(base64Encoded: base64),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let sub = json["sub"] as? String
    else { return nil }
    return UUID(uuidString: sub)
  }

  private func get<T: Decodable>(
    _ path: String,
    query: [URLQueryItem],
    accessToken: String? = nil
  ) async throws -> T {
    guard var components = URLComponents(
      url: baseURL.appendingPathComponent(path),
      resolvingAgainstBaseURL: false
    ) else {
      throw APIError.invalidURL
    }
    components.queryItems = query
    guard let url = components.url else { throw APIError.invalidURL }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    applyHeaders(&request, accessToken: accessToken)
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    return try await perform(request)
  }

  private func post<T: Decodable, B: Encodable>(
    _ path: String,
    body: B,
    accessToken: String,
    prefer: String = "return=representation"
  ) async throws -> T {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    applyHeaders(&request, accessToken: accessToken)
    request.setValue(prefer, forHTTPHeaderField: "Prefer")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)
    return try await perform(request)
  }

  private func delete(
    _ path: String,
    query: [URLQueryItem],
    accessToken: String
  ) async throws {
    guard var components = URLComponents(
      url: baseURL.appendingPathComponent(path),
      resolvingAgainstBaseURL: false
    ) else {
      throw APIError.invalidURL
    }
    components.queryItems = query
    guard let url = components.url else { throw APIError.invalidURL }

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    applyHeaders(&request, accessToken: accessToken)
    let (_, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw APIError.httpStatus(-1, nil)
    }
    guard (200 ... 299).contains(http.statusCode) else {
      throw APIError.httpStatus(http.statusCode, nil)
    }
  }

  private func applyHeaders(_ request: inout URLRequest, accessToken: String?) {
    let token = accessToken ?? anonKey
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
  }

  private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw APIError.httpStatus(-1, nil)
    }
    guard (200 ... 299).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8)
      throw APIError.httpStatus(http.statusCode, body)
    }

    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw APIError.decodingFailed(error)
    }
  }
}

import Foundation

@MainActor
final class AuthSession: ObservableObject {
  @Published private(set) var accessToken: String?
  @Published private(set) var userId: UUID?
  @Published private(set) var lastError: String?

  private let defaults = UserDefaults.standard
  private let accessTokenKey = "supabase_access_token"
  private let refreshTokenKey = "supabase_refresh_token"
  private let userIdKey = "supabase_user_id"

  init() {
    accessToken = defaults.string(forKey: accessTokenKey)
    if let raw = defaults.string(forKey: userIdKey) {
      userId = UUID(uuidString: raw)
    }
  }

  var isSignedIn: Bool {
    accessToken != nil && userId != nil
  }

  func signInIfNeeded() async {
    guard SupabaseConfig.isConfigured else { return }
    if accessToken != nil, userId != nil { return }
    await signInAnonymously()
  }

  func signInAnonymously() async {
    guard let baseURL = SupabaseConfig.url,
      let anonKey = SupabaseConfig.anonKey
    else {
      lastError = APIError.notConfigured.errorDescription
      return
    }

    lastError = nil
    let url = baseURL.appendingPathComponent("auth/v1/signup")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data("{}".utf8)

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { return }

      if http.statusCode == 422 || http.statusCode == 400 {
        // Already signed up — try refresh if we have a refresh token
        if let refresh = defaults.string(forKey: refreshTokenKey) {
          await refreshSession(refreshToken: refresh)
          return
        }
      }

      guard (200 ... 299).contains(http.statusCode) else {
        let body = String(data: data, encoding: .utf8)
        lastError = "Sign-in failed (\(http.statusCode)): \(body ?? "")"
        return
      }

      let session = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
      persist(session: session)
    } catch {
      lastError = error.localizedDescription
    }
  }

  func refreshSession(refreshToken: String) async {
    guard let baseURL = SupabaseConfig.url,
      let anonKey = SupabaseConfig.anonKey
    else { return }

    var components = URLComponents(
      url: baseURL.appendingPathComponent("auth/v1/token"),
      resolvingAgainstBaseURL: false
    )
    components?.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]

    guard let url = components?.url else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONEncoder().encode(["refresh_token": refreshToken])

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
        await signInAnonymously()
        return
      }
      let session = try JSONDecoder().decode(SupabaseAuthResponse.self, from: data)
      persist(session: session)
    } catch {
      await signInAnonymously()
    }
  }

  private func persist(session: SupabaseAuthResponse) {
    accessToken = session.accessToken
    userId = session.user.id
    defaults.set(session.accessToken, forKey: accessTokenKey)
    defaults.set(session.refreshToken, forKey: refreshTokenKey)
    defaults.set(session.user.id.uuidString, forKey: userIdKey)
  }
}

private struct SupabaseAuthResponse: Decodable {
  let accessToken: String
  let refreshToken: String
  let user: SupabaseUser

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case user
  }
}

private struct SupabaseUser: Decodable {
  let id: UUID
}

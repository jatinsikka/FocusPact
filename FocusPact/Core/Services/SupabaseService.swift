import Foundation
import Security
import Combine

// MARK: - KeychainHelper

struct KeychainHelper {
    static let service = "com.yourname.focuspact"

    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - SupabaseService

@MainActor
final class SupabaseService: ObservableObject {
    @Published var currentUser: UserProfile? = nil
    @Published var isAuthenticated: Bool = false

    private var supabaseURL: String {
        Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
    }
    private var supabaseKey: String {
        Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
    }
    private var authToken: String? {
        get { KeychainHelper.load(key: "supabase_token") }
        set {
            if let value = newValue {
                KeychainHelper.save(key: "supabase_token", value: value)
            } else {
                KeychainHelper.delete(key: "supabase_token")
            }
        }
    }

    init() {
        checkSession()
    }

    private func checkSession() {
        if KeychainHelper.load(key: "supabase_token") != nil {
            isAuthenticated = true
        }
    }

    private func makeRequest(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        authRequired: Bool = false
    ) async throws -> Data {
        guard let url = URL(string: supabaseURL + path) else { throw SupabaseError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authRequired, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else { throw SupabaseError.requestFailed }
        return data
    }

    func signIn(email: String, password: String) async throws {
        let data = try await makeRequest(
            path: "/auth/v1/token?grant_type=password",
            method: "POST",
            body: ["email": email, "password": password]
        )
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String,
           let uid = (json["user"] as? [String: Any])?["id"] as? String {
            authToken = token
            isAuthenticated = true
            currentUser = try await fetchProfile(userId: uid)
        }
    }

    func signUp(email: String, password: String, username: String) async throws {
        let data = try await makeRequest(
            path: "/auth/v1/signup",
            method: "POST",
            body: ["email": email, "password": password, "data": ["username": username]]
        )
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["access_token"] as? String {
            authToken = token
            isAuthenticated = true
        }
    }

    func signOut() {
        authToken = nil
        currentUser = nil
        isAuthenticated = false
    }

    func fetchProfile(userId: String) async throws -> UserProfile {
        let data = try await makeRequest(
            path: "/rest/v1/profiles?id=eq.\(userId)&select=*",
            authRequired: true
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let profiles = try decoder.decode([UserProfile].self, from: data)
        guard let profile = profiles.first else { throw SupabaseError.notFound }
        return profile
    }

    func saveSession(_ session: SessionRecord) async throws {
        let body: [String: Any] = [
            "id":                  session.id.uuidString,
            "user_id":             currentUser?.id ?? "",
            "start_time":          ISO8601DateFormatter().string(from: session.startTime),
            "duration_minutes":    session.durationMinutes,
            "blocklist_name":      session.blocklistName,
            "distractions_blocked": session.distractionsBlocked,
            "was_locked":          session.wasLocked
        ]
        _ = try await makeRequest(
            path: "/rest/v1/sessions",
            method: "POST",
            body: body,
            authRequired: true
        )
    }

    func fetchActivePacts() async throws -> [Pact] {
        guard let uid = currentUser?.id else { return [] }
        let data = try await makeRequest(
            path: "/rest/v1/pacts?or=(creator_id.eq.\(uid),invitee_id.eq.\(uid))&status=neq.completed&select=*",
            authRequired: true
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Pact].self, from: data)
    }

    func createPact(friendId: String, durationMinutes: Int) async throws -> Pact {
        guard let uid = currentUser?.id else { throw SupabaseError.notAuthenticated }
        let body: [String: Any] = [
            "creator_id":       uid,
            "invitee_id":       friendId,
            "duration_minutes": durationMinutes,
            "status":           "pending"
        ]
        let data = try await makeRequest(
            path: "/rest/v1/pacts",
            method: "POST",
            body: body,
            authRequired: true
        )
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Pact.self, from: data)
    }

    func acceptPact(pactId: String) async throws {
        _ = try await makeRequest(
            path: "/rest/v1/pacts?id=eq.\(pactId)",
            method: "PATCH",
            body: ["status": "active"],
            authRequired: true
        )
    }
}

enum SupabaseError: LocalizedError {
    case invalidURL, requestFailed, notFound, notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Invalid URL."
        case .requestFailed:    return "Request failed."
        case .notFound:         return "Resource not found."
        case .notAuthenticated: return "Not authenticated."
        }
    }
}

import Foundation
import Combine

struct SessionRecommendation: Decodable {
    var recommendedDuration: Int
    var recommendedBlocklist: String
    var reason: String

    enum CodingKeys: String, CodingKey {
        case recommendedDuration = "recommended_duration"
        case recommendedBlocklist = "recommended_blocklist"
        case reason
    }
}

final class AICoachService: ObservableObject {
    @Published var isLoading: Bool = false

    private var apiKey: String {
        Bundle.main.infoDictionary?["CLAUDE_API_KEY"] as? String ?? ""
    }
    private let baseURL = "https://api.anthropic.com/v1/messages"

    func callClaude(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 200,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIError.requestFailed
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first = content.first,
            let text = first["text"] as? String
        else { throw AIError.parseError }

        return text
    }

    func getDailyTip(sessionsThisWeek: Int, totalHours: Double, mostBlockedSite: String) async throws -> String {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        let prompt = """
        You are a focus and productivity coach. The user has completed \(sessionsThisWeek) focus sessions this week, totaling \(String(format: "%.1f", totalHours)) hours. Their most blocked site is \(mostBlockedSite). Give one specific, actionable tip for today in 2 sentences max. Be direct and encouraging.
        """
        return try await callClaude(prompt: prompt)
    }

    func getSessionRecommendation(
        sessionsToday: Int,
        avgSessionLength: Int,
        minutesSinceLastSession: Int
    ) async throws -> SessionRecommendation {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeStr = formatter.string(from: Date())
        let dayStr = Calendar.current.weekdaySymbols[Calendar.current.component(.weekday, from: Date()) - 1]

        let prompt = """
        You are a focus coach AI. Based on this user data:
        - Current time: \(timeStr)
        - Day of week: \(dayStr)
        - Sessions completed today: \(sessionsToday)
        - Average session length: \(avgSessionLength) minutes
        - Last session ended: \(minutesSinceLastSession) minutes ago
        Recommend the ideal session duration (25, 45, 60, or 90 min) and which blocklist to use. Reply in JSON format ONLY, no other text: {"recommended_duration": number, "recommended_blocklist": string, "reason": string}
        """

        let responseText = try await callClaude(prompt: prompt)
        let cleanJSON = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = cleanJSON.data(using: .utf8) else { throw AIError.parseError }
        return try JSONDecoder().decode(SessionRecommendation.self, from: jsonData)
    }

    func getPostSessionDebrief(
        durationMinutes: Int,
        distractionsBlocked: Int,
        sessionName: String
    ) async throws -> String {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        let prompt = """
        You are a focus coach. The user just completed a \(durationMinutes)-minute focus session with \(distractionsBlocked) distractions blocked. Session name: \(sessionName.isEmpty ? "Untitled" : sessionName). Give a 2-sentence motivating debrief. Acknowledge their effort and hint at a next step.
        """
        return try await callClaude(prompt: prompt)
    }
}

enum AIError: LocalizedError {
    case missingAPIKey
    case requestFailed
    case parseError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Claude API key not configured."
        case .requestFailed: return "Request to Claude API failed."
        case .parseError:    return "Could not parse Claude API response."
        }
    }
}

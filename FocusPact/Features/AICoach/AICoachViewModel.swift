import Foundation
import Combine

enum MessageRole {
    case user
    case assistant
}

struct ChatMessage: Identifiable {
    var id: UUID = UUID()
    var role: MessageRole
    var content: String
    var timestamp: Date = Date()
}

@MainActor
final class AICoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isSending: Bool = false
    @Published var inputText: String = ""

    private let aiService: AICoachService
    private let contextSummary: String

    init(aiService: AICoachService, sessionsThisWeek: Int = 0, totalHoursThisWeek: Double = 0) {
        self.aiService = aiService
        self.contextSummary = """
        User context: \(sessionsThisWeek) focus sessions this week, \
        \(String(format: "%.1f", totalHoursThisWeek)) total hours focused.
        """

        messages.append(ChatMessage(
            role: .assistant,
            content: "Hi! I'm your FocusPact AI coach. I can help you optimize your focus sessions, analyze your productivity patterns, and keep you motivated. What would you like to explore today?"
        ))
    }

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        inputText = ""
        isSending = true

        let fullPrompt = """
        \(contextSummary)
        You are FocusPact AI coach. Be concise, encouraging, and actionable. Max 3 sentences.
        User: \(trimmed)
        """

        do {
            let response = try await aiService.callClaude(prompt: fullPrompt)
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            messages.append(ChatMessage(
                role: .assistant,
                content: "I'm having trouble connecting right now. Please check your internet connection and try again."
            ))
        }

        isSending = false
    }

    func sendPrebuiltPrompt(_ prompt: PrebuiltPrompt) async {
        await sendMessage(prompt.text)
    }
}

enum PrebuiltPrompt: String, CaseIterable {
    case analyzeWeek = "Analyze my week"
    case suggestSession = "Suggest a session"
    case helpFocus = "Help me focus now"

    var text: String {
        switch self {
        case .analyzeWeek:
            return "Please analyze my focus patterns this week and tell me what I can improve."
        case .suggestSession:
            return "Based on my usage, what kind of focus session should I do right now?"
        case .helpFocus:
            return "I'm struggling to focus right now. Give me a quick technique to get into the zone."
        }
    }

    var icon: String {
        switch self {
        case .analyzeWeek:   return "chart.bar.fill"
        case .suggestSession: return "clock.fill"
        case .helpFocus:     return "bolt.fill"
        }
    }
}

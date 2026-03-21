import Foundation
import SwiftData

@MainActor
final class PactsViewModel: ObservableObject {
    @Published var myCode: String = ""
    @Published var showingAddSheet: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        loadOrCreateCode()
    }

    private func loadOrCreateCode() {
        if let existing = UserDefaults.standard.string(forKey: "myFocusCode") {
            myCode = existing
        } else {
            let code = generateCode()
            UserDefaults.standard.set(code, forKey: "myFocusCode")
            myCode = code
        }
    }

    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    func createPact(partnerCode: String, partnerName: String, durationMinutes: Int, context: ModelContext) {
        let trimmedCode = partnerCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            errorMessage = "Partner code cannot be empty."
            return
        }
        guard trimmedCode != myCode else {
            errorMessage = "You can't create a pact with yourself!"
            return
        }
        let name = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let pact = LocalPact(
            partnerCode: trimmedCode,
            partnerName: name.isEmpty ? "Friend" : name,
            durationMinutes: durationMinutes
        )
        context.insert(pact)
        do {
            try context.save()
            showingAddSheet = false
        } catch {
            errorMessage = "Failed to save pact: \(error.localizedDescription)"
        }
    }

    func completePact(_ pact: LocalPact, context: ModelContext) {
        pact.statusRaw = "completed"
        pact.completedAt = Date()
        try? context.save()
    }

    func deletePact(_ pact: LocalPact, context: ModelContext) {
        context.delete(pact)
        try? context.save()
    }

    func shareText() -> String {
        "Hey! Let's focus together on FocusPact.\nMy Focus Code is: \(myCode)\n\nEnter it in the Friends tab to start a focus pact with me! 🎯"
    }
}

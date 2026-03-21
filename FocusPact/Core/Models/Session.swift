import Foundation
import SwiftData

@Model
final class SessionRecord {
    var id: UUID = UUID()
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int
    var blocklistName: String
    var sessionName: String
    var distractionsBlocked: Int
    var wasLocked: Bool

    var focusScore: Double {
        min(100, Double(durationMinutes) / 90.0 * 100)
    }

    init(
        startTime: Date,
        endTime: Date? = nil,
        durationMinutes: Int,
        blocklistName: String,
        sessionName: String,
        distractionsBlocked: Int,
        wasLocked: Bool
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.blocklistName = blocklistName
        self.sessionName = sessionName
        self.distractionsBlocked = distractionsBlocked
        self.wasLocked = wasLocked
    }
}

struct FocusSession: Identifiable {
    var id: UUID = UUID()
    var name: String
    var durationMinutes: Int
    var blocklistName: String
    var blockedDomains: [String]
    var isLocked: Bool
    var startTime: Date = Date()
    var pactFriendId: String?
}

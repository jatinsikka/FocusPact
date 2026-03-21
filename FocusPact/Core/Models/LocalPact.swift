import Foundation
import SwiftData

@Model
final class LocalPact {
    var id: UUID = UUID()
    var partnerCode: String
    var partnerName: String
    var durationMinutes: Int
    var statusRaw: String = "active"
    var createdAt: Date = Date()
    var completedAt: Date? = nil

    init(partnerCode: String, partnerName: String, durationMinutes: Int) {
        self.partnerCode = partnerCode
        self.partnerName = partnerName
        self.durationMinutes = durationMinutes
        self.statusRaw = "active"
    }

    var isActive: Bool { statusRaw == "active" }
    var isCompleted: Bool { statusRaw == "completed" }
}

import Foundation

enum PactStatus: String, Codable {
    case pending, active, completed, broken
}

struct Pact: Codable, Identifiable {
    var id: String
    var creatorId: String
    var inviteeId: String
    var status: PactStatus
    var durationMinutes: Int
    var startTime: Date?
    var endTime: Date?
}

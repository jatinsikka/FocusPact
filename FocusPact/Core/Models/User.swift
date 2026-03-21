import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String
    var username: String
    var avatarURL: String?
    var timezone: String
    var createdAt: Date
}

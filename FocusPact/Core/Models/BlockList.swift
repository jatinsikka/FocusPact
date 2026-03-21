import Foundation
import SwiftData

@Model
final class BlockList {
    var id: UUID = UUID()
    var name: String
    var domains: [String]
    var isPreset: Bool
    var createdAt: Date = Date()

    init(name: String, domains: [String], isPreset: Bool) {
        self.name = name
        self.domains = domains
        self.isPreset = isPreset
    }

    static var presets: [BlockList] {
        [
            BlockList(
                name: "Social Media",
                domains: [
                    "instagram.com", "twitter.com", "x.com", "tiktok.com",
                    "facebook.com", "snapchat.com", "reddit.com", "linkedin.com"
                ],
                isPreset: true
            ),
            BlockList(
                name: "News",
                domains: [
                    "cnn.com", "bbc.com", "nytimes.com",
                    "theguardian.com", "ndtv.com", "timesofindia.com"
                ],
                isPreset: true
            ),
            BlockList(
                name: "Entertainment",
                domains: [
                    "youtube.com", "netflix.com", "twitch.tv",
                    "primevideo.com", "hotstar.com", "spotify.com"
                ],
                isPreset: true
            ),
            BlockList(
                name: "Custom",
                domains: [],
                isPreset: false
            )
        ]
    }
}

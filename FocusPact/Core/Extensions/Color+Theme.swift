import SwiftUI

extension Color {
    static let fpBackground    = Color(hex: "#0A0A0F") ?? Color.black
    static let fpSurface       = Color(hex: "#13131A") ?? Color(white: 0.075)
    static let fpPrimary       = Color(hex: "#6C63FF") ?? Color.purple
    static let fpAccent        = Color(hex: "#00D4AA") ?? Color.teal
    static let fpTextPrimary   = Color(hex: "#FFFFFF") ?? Color.white
    static let fpTextSecondary = Color(hex: "#8A8A9A") ?? Color.gray
    static let fpDanger        = Color(hex: "#FF4757") ?? Color.red
    static let fpBorder        = Color(hex: "#1E1E2E") ?? Color(white: 0.12)

    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }
        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16)
        else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >>  8) & 0xFF) / 255.0
        let b = Double( value        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension LinearGradient {
    static let fpPrimaryGradient = LinearGradient(
        colors: [Color.fpPrimary, Color.fpAccent],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let fpTimerGradient = LinearGradient(
        colors: [Color.fpPrimary, Color.fpAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

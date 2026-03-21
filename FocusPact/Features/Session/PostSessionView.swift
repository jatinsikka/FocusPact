import SwiftUI
import SwiftUI

struct PostSessionView: View {
    let record: SessionRecord

    @EnvironmentObject private var aiService: AICoachService
    @Environment(\.dismiss) private var dismiss

    @State private var aiDebrief:       String = ""
    @State private var isLoadingDebrief: Bool  = true
    @State private var showConfetti:    Bool  = false
    @State private var navigateToSetup: Bool  = false

    private var focusScoreText: String {
        String(format: "%.0f", record.focusScore)
    }

    var body: some View {
        ZStack {
            Color.fpBackground.ignoresSafeArea()

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.fpAccent)
                            .padding(.top, 40)

                        Text("Session Complete!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.fpTextPrimary)

                        Text(record.sessionName.isEmpty ? "Great work!" : record.sessionName)
                            .font(.system(size: 16))
                            .foregroundColor(.fpTextSecondary)
                    }

                    // Stats Grid
                    HStack(spacing: 12) {
                        statCard(title: "Duration",     value: "\(record.durationMinutes)m", icon: "clock.fill",            color: .fpPrimary)
                        statCard(title: "Blocked",      value: "\(record.distractionsBlocked)", icon: "shield.fill",        color: .fpAccent)
                        statCard(title: "Focus Score",  value: "\(focusScoreText)%", icon: "chart.bar.fill",               color: .fpPrimary)
                    }

                    // AI Debrief
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.fpPrimary)
                            Text("Coach Feedback")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.fpTextPrimary)
                        }

                        if isLoadingDebrief {
                            HStack {
                                ProgressView()
                                    .tint(.fpPrimary)
                                Text("Getting your feedback...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.fpTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(aiDebrief)
                                .font(.system(size: 15))
                                .foregroundColor(.fpTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .background(Color.fpSurface)
                    .cornerRadius(16)

                    // Buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: SessionSetupView(preset: nil)) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Start Another Session")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(LinearGradient.fpPrimaryGradient)
                            .cornerRadius(22)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.fpTextSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.fpSurface)
                                .cornerRadius(22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.fpBorder, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Trigger confetti
            withAnimation { showConfetti = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showConfetti = false }
            }

            // Fetch debrief
            do {
                aiDebrief = try await aiService.getPostSessionDebrief(
                    durationMinutes:     record.durationMinutes,
                    distractionsBlocked: record.distractionsBlocked,
                    sessionName:         record.sessionName
                )
            } catch {
                aiDebrief = "Great work completing your session! Every focused minute builds the habit. Keep showing up and your concentration will compound over time."
            }
            isLoadingDebrief = false
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.fpTextPrimary)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.fpTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.fpSurface)
        .cornerRadius(16)
    }
}

// MARK: - ConfettiView

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    private let colors: [Color] = [
        .fpPrimary, .fpAccent, Color(hex: "#FFD700") ?? .yellow,
        Color(hex: "#FF6B6B") ?? .red, Color(hex: "#4ECDC4") ?? .teal,
        Color(hex: "#45B7D1") ?? .blue, Color(hex: "#96CEB4") ?? .green
    ]

    var body: some View {
        Canvas { context, size in
            for p in particles {
                let rect = CGRect(
                    x: p.x * size.width,
                    y: p.y * size.height,
                    width: p.size,
                    height: p.size * 0.5
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(p.color.opacity(p.opacity))
                )
            }
        }
        .onAppear {
            particles = (0..<80).map { _ in
                ConfettiParticle(
                    x:       Double.random(in: 0...1),
                    y:       Double.random(in: -0.3...0),
                    size:    Double.random(in: 6...14),
                    color:   colors.randomElement() ?? .fpPrimary,
                    opacity: Double.random(in: 0.7...1.0),
                    speed:   Double.random(in: 0.003...0.008)
                )
            }
            withAnimation(.linear(duration: 3).repeatCount(1, autoreverses: false)) {
                particles = particles.map { p in
                    var updated = p
                    updated.y = Double.random(in: 1.0...1.4)
                    updated.opacity = 0
                    return updated
                }
            }
        }
    }
}

struct ConfettiParticle {
    var x:       Double
    var y:       Double
    var size:    Double
    var color:   Color
    var opacity: Double
    var speed:   Double
}

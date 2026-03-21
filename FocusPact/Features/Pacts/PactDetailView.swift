import SwiftUI
import SwiftData

struct LocalPactDetailView: View {
    let pact: LocalPact
    @Environment(\.modelContext) private var modelContext
    @StateObject private var timerVM = PactTimerViewModel()

    var body: some View {
        ZStack {
            Color.fpBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    statusBadge
                    timerSection
                    detailsCard
                    if pact.isActive {
                        completeButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(pact.partnerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if pact.isActive {
                timerVM.start(total: pact.durationMinutes * 60)
            }
        }
        .onDisappear { timerVM.stop() }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack {
            Spacer()
            Text(pact.statusRaw.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(statusColor.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(statusColor.opacity(0.3), lineWidth: 1))
            Spacer()
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 12) {
            Text("Focus Together")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.fpTextSecondary)

            ZStack {
                Circle()
                    .stroke(Color.fpBorder, lineWidth: 10)
                    .frame(width: 180, height: 180)
                Circle()
                    .trim(from: 0, to: timerVM.progress(total: pact.durationMinutes * 60))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerVM.elapsed)
                VStack(spacing: 4) {
                    Text(timerVM.formattedRemaining(total: pact.durationMinutes * 60))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.fpTextPrimary)
                    Text(pact.isCompleted ? "completed" : "remaining")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fpTextSecondary)
                }
            }
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 14) {
            detailRow("Partner", value: pact.partnerName)
            Divider().background(Color.fpBorder)
            detailRow("Partner Code", value: pact.partnerCode)
            Divider().background(Color.fpBorder)
            detailRow("Duration", value: "\(pact.durationMinutes) minutes")
            Divider().background(Color.fpBorder)
            detailRow("Created", value: pact.createdAt.formatted(.dateTime.month().day().hour().minute()))
            if let completed = pact.completedAt {
                Divider().background(Color.fpBorder)
                detailRow("Completed", value: completed.formatted(.dateTime.month().day().hour().minute()))
            }
        }
        .padding(16)
        .background(Color.fpSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.fpBorder, lineWidth: 1))
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(Color.fpTextSecondary)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.fpTextPrimary)
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            pact.statusRaw = "completed"
            pact.completedAt = Date()
            try? modelContext.save()
            timerVM.stop()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Mark as Complete").fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(LinearGradient(colors: [Color.fpAccent, Color.fpAccent.opacity(0.8)],
                                       startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var statusColor: Color {
        pact.isCompleted ? Color.fpAccent : Color.fpPrimary
    }
}

// MARK: - PactTimerViewModel

@MainActor
private final class PactTimerViewModel: ObservableObject {
    @Published var elapsed: Int = 0
    private var timer: Timer?

    func start(total: Int) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.elapsed < total {
                    self.elapsed += 1
                } else {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func progress(total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(Double(elapsed) / Double(total), 1.0)
    }

    func formattedRemaining(total: Int) -> String {
        let remaining = max(total - elapsed, 0)
        return String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }
}

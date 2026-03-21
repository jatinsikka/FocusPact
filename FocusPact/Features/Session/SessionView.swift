import SwiftUI
import SwiftUI
import SwiftData

struct SessionView: View {
    let session: FocusSession

    @StateObject private var vm = SessionViewModel()

    @EnvironmentObject private var blockingService: BlockingService
    @EnvironmentObject private var aiService:       AICoachService

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var showEndAlert:     Bool = false
    @State private var showCloseAlert:   Bool = false
    @State private var quoteOpacity:     Double = 1.0

    var body: some View {
        ZStack {
            Color.fpBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                circularTimer
                    .frame(width: 280, height: 280)

                controlButtons
                    .padding(.horizontal, 40)

                Spacer()

                quoteCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            vm.startSession(session, blockingService: blockingService)
        }
        .alert("End Session?", isPresented: $showEndAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Session", role: .destructive) {
                vm.endSession(modelContext: modelContext, blockingService: blockingService)
            }
        } message: {
            Text(session.isLocked
                 ? "Locked mode is active. Are you sure you want to end this session early?"
                 : "End this focus session now?")
        }
        .alert("Leave Session?", isPresented: $showCloseAlert) {
            Button("Stay", role: .cancel) {}
            Button("Leave", role: .destructive) {
                vm.endSession(modelContext: modelContext, blockingService: blockingService)
                dismiss()
            }
        } message: {
            Text("Your session is still running. If you leave, it will be ended.")
        }
        .fullScreenCover(isPresented: $vm.sessionComplete) {
            if let record = vm.postSessionRecord {
                PostSessionView(record: record)
                    .environmentObject(aiService)
            }
        }
        .onChange(of: vm.currentQuote) { _, _ in
            withAnimation(.easeOut(duration: 0.3)) { quoteOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.5)) { quoteOpacity = 1 }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name.isEmpty ? "Focus Session" : session.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.fpTextPrimary)
                if session.isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                        Text("Locked Mode")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.fpDanger)
                }
            }
            Spacer()
            Button {
                if session.isLocked || vm.isSessionActive {
                    showCloseAlert = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.fpTextSecondary)
            }
        }
    }

    // MARK: - Circular Timer

    private var circularTimer: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.fpBorder, lineWidth: 12)

            // Progress arc
            Circle()
                .trim(from: 0, to: vm.progress)
                .stroke(
                    LinearGradient.fpTimerGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: vm.progress)

            // Center content
            VStack(spacing: 8) {
                Text(vm.formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundColor(.fpTextPrimary)

                Text(session.blocklistName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.fpPrimary.opacity(0.3))
                    .cornerRadius(8)

                if vm.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.fpDanger)
                        .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        VStack(spacing: 14) {
            // Pause / Resume
            Button {
                if vm.isPaused {
                    vm.resumeSession()
                } else {
                    vm.pauseSession()
                }
            } label: {
                HStack {
                    Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                    Text(vm.isPaused ? "Resume" : "Pause")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.fpSurface)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.fpBorder, lineWidth: 1)
                )
            }
            .disabled(session.isLocked)
            .opacity(session.isLocked ? 0.4 : 1.0)

            // End Session
            Button {
                showEndAlert = true
            } label: {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("End Session")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.fpDanger)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.fpDanger.opacity(0.12))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.fpDanger.opacity(0.4), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.fpAccent)
                .frame(width: 3)
                .cornerRadius(2)

            Text(vm.currentQuote.isEmpty ? " " : "\u{201C}\(vm.currentQuote)\u{201D}")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.fpTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(quoteOpacity)
        }
        .padding(16)
        .background(Color.fpSurface)
        .cornerRadius(14)
    }
}

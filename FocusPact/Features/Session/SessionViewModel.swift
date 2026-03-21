import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var session:           FocusSession?   = nil
    @Published var timeRemaining:     Int             = 0
    @Published var isPaused:          Bool            = false
    @Published var isSessionActive:   Bool            = false
    @Published var currentQuote:      String          = ""
    @Published var postSessionRecord: SessionRecord?  = nil
    @Published var distractionsBlocked: Int           = 0
    @Published var sessionComplete:   Bool            = false

    private var timer:      Timer?
    private var quoteTimer: Timer?
    private var quoteIndex: Int = 0

    let motivationalQuotes: [String] = [
        "The secret of getting ahead is getting started.",
        "Focus on being productive instead of busy.",
        "Your future is created by what you do today, not tomorrow.",
        "Done is better than perfect.",
        "Concentrate all your thoughts upon the work at hand.",
        "It's not about having time, it's about making time.",
        "Deep work is the ability to focus without distraction.",
        "What you do today can improve all your tomorrows.",
        "Success is the sum of small efforts, repeated day in and day out.",
        "The key to success is to focus on goals, not obstacles."
    ]

    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard let session else { return 0 }
        let total = session.durationMinutes * 60
        guard total > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(total))
    }

    func startSession(_ session: FocusSession, blockingService: BlockingService) {
        self.session          = session
        self.timeRemaining    = session.durationMinutes * 60
        self.isSessionActive  = true
        self.distractionsBlocked = 0
        self.currentQuote     = motivationalQuotes.randomElement() ?? ""

        if !session.blockedDomains.isEmpty {
            blockingService.startBlocking(name: session.blocklistName, domains: session.blockedDomains)
        }

        startTimer()
        startQuoteTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func startQuoteTimer() {
        quoteTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.quoteIndex = (self.quoteIndex + 1) % self.motivationalQuotes.count
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.currentQuote = self.motivationalQuotes[self.quoteIndex]
                }
            }
        }
    }

    func tick() {
        guard isSessionActive, !isPaused else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            completeSession()
        }
    }

    func pauseSession() {
        isPaused = true
    }

    func resumeSession() {
        isPaused = false
    }

    func endSession(modelContext: ModelContext, blockingService: BlockingService) {
        guard let session else { return }
        let elapsed = session.durationMinutes - (timeRemaining / 60)
        let record = SessionRecord(
            startTime:           session.startTime,
            endTime:             Date(),
            durationMinutes:     max(1, elapsed),
            blocklistName:       session.blocklistName,
            sessionName:         session.name,
            distractionsBlocked: distractionsBlocked,
            wasLocked:           session.isLocked
        )
        modelContext.insert(record)
        postSessionRecord = record
        cleanup(blockingService: blockingService)
        sessionComplete = true
    }

    private func completeSession() {
        timer?.invalidate()
        quoteTimer?.invalidate()
        isSessionActive = false
        sessionComplete = true
    }

    private func cleanup(blockingService: BlockingService) {
        timer?.invalidate()
        quoteTimer?.invalidate()
        isSessionActive = false
        blockingService.stopBlocking()
    }
}

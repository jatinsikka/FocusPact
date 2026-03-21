import UserNotifications
import Foundation
import Combine

final class NotificationService: ObservableObject {
    private let center = UNUserNotificationCenter.current()

    func requestPermission() async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func scheduleDailyFocusReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Focus"
        content.body = "Your peak focus time is now. Start a session!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_focus_reminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func scheduleSessionEndingWarning(in minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Almost There!"
        content.body = "Your focus session ends in 5 minutes. Keep going!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, minutes - 5) * 60),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "session_ending_warning",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func scheduleStreakCelebration(streakDays: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\u{1F525} \(streakDays)-Day Streak!"
        content.body = "Incredible! You've focused for \(streakDays) days in a row. Keep the momentum going!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(streakDays)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelAllPending() {
        center.removeAllPendingNotificationRequests()
    }

    func notifyPactInvite(from friendName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Pact Invite"
        content.body = "\(friendName) wants to focus with you. Accept the pact!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        center.add(UNNotificationRequest(
            identifier: "pact_invite_\(UUID())",
            content: content,
            trigger: trigger
        ))
    }

    func notifyPactBroken(by friendName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pact Broken"
        content.body = "\(friendName) ended their session early."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        center.add(UNNotificationRequest(
            identifier: "pact_broken_\(UUID())",
            content: content,
            trigger: trigger
        ))
    }
}

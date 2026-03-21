import Foundation
import SwiftData
import Combine

struct DayData: Identifiable {
    var id: String { day }
    var day: String
    var hours: Double
    var date: Date
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var weeklyData: [DayData] = []
    @Published var thisWeekMinutes: Int = 0
    @Published var lastWeekMinutes: Int = 0
    @Published var longestStreak: Int = 0
    @Published var mostProductiveHour: Int = 0
    @Published var topBlockedDomains: [(domain: String, count: Int)] = []
    @Published var totalSessionsAllTime: Int = 0

    var weeklyChangePercent: Double {
        guard lastWeekMinutes > 0 else { return 0 }
        return Double(thisWeekMinutes - lastWeekMinutes) / Double(lastWeekMinutes) * 100
    }

    func loadAnalytics(context: ModelContext) {
        let descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let sessions = (try? context.fetch(descriptor)) ?? []
        totalSessionsAllTime = sessions.count

        let calendar = Calendar.current
        let now = Date()
        let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) ?? now

        let thisWeekSessions = sessions.filter { $0.startTime >= startOfThisWeek }
        let lastWeekSessions = sessions.filter { $0.startTime >= startOfLastWeek && $0.startTime < startOfThisWeek }

        thisWeekMinutes = thisWeekSessions.reduce(0) { $0 + $1.durationMinutes }
        lastWeekMinutes = lastWeekSessions.reduce(0) { $0 + $1.durationMinutes }

        weeklyData = (0..<7).map { daysAgo -> DayData in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: calendar.startOfDay(for: now))!
            let dayLabel = Self.shortDayLabel(for: date)
            let daySessions = sessions.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
            let hours = Double(daySessions.reduce(0) { $0 + $1.durationMinutes }) / 60.0
            return DayData(day: dayLabel, hours: hours, date: date)
        }

        longestStreak = computeLongestStreak(sessions: sessions)

        let hourCounts = Dictionary(grouping: sessions, by: { calendar.component(.hour, from: $0.startTime) })
        mostProductiveHour = hourCounts.max(by: { $0.value.count < $1.value.count })?.key ?? 9

        let domainCounts = Dictionary(grouping: sessions, by: { $0.blocklistName })
        topBlockedDomains = domainCounts
            .map { (domain: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    private func computeLongestStreak(sessions: [SessionRecord]) -> Int {
        let calendar = Calendar.current
        let days = Set(sessions.map { calendar.startOfDay(for: $0.startTime) }).sorted()
        var longest = 0, current = 0
        var prev: Date? = nil
        for day in days {
            if let p = prev, let diff = calendar.dateComponents([.day], from: p, to: day).day, diff == 1 {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            prev = day
        }
        return longest
    }

    private static func shortDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    func formattedHours(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    func formattedHour(_ hour: Int) -> String {
        let components = DateComponents(hour: hour)
        guard let date = Calendar.current.date(from: components) else { return "\(hour):00" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}

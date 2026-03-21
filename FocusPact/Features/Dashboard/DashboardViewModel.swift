import Foundation
import SwiftData
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var greeting: String = ""
    @Published var todayFocusMinutes: Int = 0
    @Published var todaySessionCount: Int = 0
    @Published var currentStreak: Int = 0
    @Published var dailyTip: String = ""
    @Published var recentSessions: [SessionRecord] = []
    @Published var isLoadingTip: Bool = false
    @Published var userName: String = ""

    private let aiService: AICoachService
    private let supabaseService: SupabaseService
    private let tipCacheKey = "dailyTip_cache"
    private let tipDateKey  = "dailyTip_date"

    init(aiService: AICoachService, supabaseService: SupabaseService) {
        self.aiService = aiService
        self.supabaseService = supabaseService
        self.userName = supabaseService.currentUser?.username ?? "there"
        self.greeting = computeGreeting()
    }

    func loadData(modelContext: ModelContext) async {
        userName = supabaseService.currentUser?.username ?? "there"
        greeting = computeGreeting()

        let descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let allSessions = (try? modelContext.fetch(descriptor)) ?? []
        recentSessions = Array(allSessions.prefix(5))

        let calendar = Calendar.current
        let todaySessions = allSessions.filter { calendar.isDateInToday($0.startTime) }
        todaySessionCount  = todaySessions.count
        todayFocusMinutes  = todaySessions.reduce(0) { $0 + $1.durationMinutes }
        currentStreak      = computeStreak(from: allSessions)

        await refreshDailyTipIfNeeded(sessions: allSessions)
    }

    func refreshDailyTip(sessions: [SessionRecord]) async {
        isLoadingTip = true
        defer { isLoadingTip = false }

        let weekSessions = sessions.filter {
            Calendar.current.isDate($0.startTime, equalTo: Date(), toGranularity: .weekOfYear)
        }
        let hours = Double(weekSessions.reduce(0) { $0 + $1.durationMinutes }) / 60.0

        do {
            let tip = try await aiService.getDailyTip(
                sessionsThisWeek: weekSessions.count,
                totalHours: hours,
                mostBlockedSite: mostBlockedDomain(from: sessions)
            )
            dailyTip = tip
            UserDefaults.standard.set(tip,  forKey: tipCacheKey)
            UserDefaults.standard.set(Date(), forKey: tipDateKey)
        } catch {
            dailyTip = "Take short breaks every 45-90 minutes to maintain peak focus and avoid burnout."
        }
    }

    private func refreshDailyTipIfNeeded(sessions: [SessionRecord]) async {
        if let lastDate = UserDefaults.standard.object(forKey: tipDateKey) as? Date,
           Calendar.current.isDateInToday(lastDate),
           let cached = UserDefaults.standard.string(forKey: tipCacheKey) {
            dailyTip = cached
            return
        }
        await refreshDailyTip(sessions: sessions)
    }

    func computeGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 0..<12:  timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        default:      timeGreeting = "Good evening"
        }
        return "\(timeGreeting), \(userName.isEmpty ? "there" : userName)!"
    }

    func computeStreak(from sessions: [SessionRecord]) -> Int {
        let calendar  = Calendar.current
        let sortedDays = Set(sessions.map { calendar.startOfDay(for: $0.startTime) }).sorted(by: >)
        guard let first = sortedDays.first,
              calendar.isDateInToday(first) || calendar.isDateInYesterday(first)
        else { return 0 }

        var streak  = 1
        var current = first
        for day in sortedDays.dropFirst() {
            let diff = calendar.dateComponents([.day], from: day, to: current).day ?? 0
            if diff == 1 {
                streak  += 1
                current  = day
            } else {
                break
            }
        }
        return streak
    }

    private func mostBlockedDomain(from sessions: [SessionRecord]) -> String {
        let names  = sessions.map { $0.blocklistName }
        let counts = Dictionary(grouping: names, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "social media"
    }
}

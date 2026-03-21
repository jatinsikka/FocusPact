import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    @EnvironmentObject private var aiService: AICoachService
    @EnvironmentObject private var blockingService: BlockingService

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            blockingService.loadActiveState()
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @EnvironmentObject private var supabaseService: SupabaseService
    @EnvironmentObject private var aiService: AICoachService
    @EnvironmentObject private var blockingService: BlockingService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            DashboardView(
                aiService: aiService,
                supabaseService: supabaseService
            )
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }

            BlocklistView()
                .tabItem {
                    Label("Blocklists", systemImage: "shield.fill")
                }

            PactsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            AICoachView(aiService: aiService)
                .tabItem {
                    Label("AI Coach", systemImage: "sparkles")
                }
        }
        .tint(Color.fpPrimary)
        .preferredColorScheme(.dark)
    }
}

import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject private var aiService:       AICoachService
    @EnvironmentObject private var supabaseService: SupabaseService
    @EnvironmentObject private var blockingService: BlockingService

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<LocalPact> { $0.statusRaw == "active" })
    private var localActivePacts: [LocalPact]

    @StateObject private var vm: DashboardViewModel

    @State private var showSettings: Bool = false
    @State private var sessionSetupPreset: QuickPreset? = nil
    @State private var navigateToSetup: Bool = false

    init(aiService: AICoachService, supabaseService: SupabaseService) {
        _vm = StateObject(wrappedValue: DashboardViewModel(
            aiService: aiService,
            supabaseService: supabaseService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                    greetingSection
                    statsRow
                    startFocusButton
                    quickStartRow
                    aiTipCard
                    activePactsSection
                    recentSessionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.fpBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $navigateToSetup) {
                SessionSetupView(preset: sessionSetupPreset)
            }
            .sheet(isPresented: $showSettings) {
                SettingsPlaceholderView()
            }
            .task {
                await vm.loadData(modelContext: modelContext)
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("FocusPact")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.fpPrimary)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.fpTextSecondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        Text(vm.greeting)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.fpTextPrimary)
            .lineLimit(2)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Focus Time",
                value: "\(vm.todayFocusMinutes)m",
                icon: "clock.fill"
            )
            StatCard(
                title: "Sessions",
                value: "\(vm.todaySessionCount)",
                icon: "checkmark.circle.fill"
            )
            StatCard(
                title: "Streak",
                value: "\u{1F525}\(vm.currentStreak)d",
                icon: "flame.fill"
            )
        }
    }

    // MARK: - Start Focus Button

    private var startFocusButton: some View {
        NavigationLink {
            SessionSetupView(preset: nil)
        } label: {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Start Focus Session")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient.fpPrimaryGradient)
            .cornerRadius(24)
        }
    }

    // MARK: - Quick Start Row

    private var quickStartRow: some View {
        HStack(spacing: 10) {
            quickChip(label: "Work 45m",  preset: QuickPreset(name: "Work",  duration: 45, blocklist: "Social Media"))
            quickChip(label: "Study 25m", preset: QuickPreset(name: "Study", duration: 25, blocklist: "Entertainment"))
            quickChip(label: "Sleep 60m", preset: QuickPreset(name: "Sleep", duration: 60, blocklist: "News"))
        }
    }

    private func quickChip(label: String, preset: QuickPreset) -> some View {
        Button {
            sessionSetupPreset = preset
            navigateToSetup    = true
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.fpTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.fpSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.fpBorder, lineWidth: 1)
                )
                .cornerRadius(20)
        }
    }

    // MARK: - AI Tip Card

    private var aiTipCard: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.fpPrimary)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.fpPrimary)
                    Text("Today's Tip")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.fpTextSecondary)
                    Spacer()
                    Button {
                        Task { await vm.refreshDailyTip(sessions: vm.recentSessions) }
                    } label: {
                        if vm.isLoadingTip {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.fpPrimary)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13))
                                .foregroundColor(.fpPrimary)
                        }
                    }
                    .disabled(vm.isLoadingTip)
                }

                if vm.dailyTip.isEmpty {
                    ProgressView()
                        .tint(.fpPrimary)
                } else {
                    Text(vm.dailyTip)
                        .font(.system(size: 14))
                        .foregroundColor(.fpTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .background(Color.fpSurface)
        .cornerRadius(16)
    }

    // MARK: - Active Pacts

    private var activePactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Pacts")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.fpTextPrimary)

            if localActivePacts.isEmpty {
                Text("No active pacts. Go to Friends tab to add one.")
                    .font(.system(size: 14))
                    .foregroundColor(.fpTextSecondary)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(localActivePacts) { pact in
                            PactMiniCard(pact: pact)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.fpTextPrimary)

            if vm.recentSessions.isEmpty {
                Text("No sessions yet. Start your first focus session!")
                    .font(.system(size: 14))
                    .foregroundColor(.fpTextSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.recentSessions) { session in
                        SessionRowView(session: session)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Preset helper

struct QuickPreset {
    var name: String
    var duration: Int
    var blocklist: String
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String
    let icon:  String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.fpPrimary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.fpTextPrimary)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.fpTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.fpSurface)
        .cornerRadius(16)
    }
}

// MARK: - SessionRowView

private struct SessionRowView: View {
    let session: SessionRecord

    private var dateString: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: session.startTime, relativeTo: Date())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionName.isEmpty ? "Untitled" : session.sessionName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.fpTextPrimary)
                Text(dateString)
                    .font(.system(size: 12))
                    .foregroundColor(.fpTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.durationMinutes)m")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.fpAccent)
                Text(session.blocklistName)
                    .font(.system(size: 11))
                    .foregroundColor(.fpTextSecondary)
            }
        }
        .padding(14)
        .background(Color.fpSurface)
        .cornerRadius(14)
    }
}

// MARK: - PactMiniCard

private struct PactMiniCard: View {
    let pact: LocalPact

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.fpPrimary)
                    .frame(width: 8, height: 8)
                Text("Active")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.fpPrimary)
            }
            Text("\(pact.durationMinutes)m pact")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.fpTextPrimary)
            Text("with \(pact.partnerName)")
                .font(.system(size: 11))
                .foregroundColor(.fpTextSecondary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(width: 140)
        .background(Color.fpSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.fpPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Settings Placeholder

private struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fpBackground.ignoresSafeArea()
                
                List {
                    Section {
                        NavigationLink {
                            BlocklistView()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient.fpPrimaryGradient)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }
                                Text("Manage Blocklists")
                                    .foregroundStyle(Color.fpTextPrimary)
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.fpSurface)
                    } header: {
                        Text("Content Filtering")
                            .foregroundStyle(Color.fpTextSecondary)
                    }
                    
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(Color.fpTextSecondary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(Color.fpTextPrimary)
                        }
                        .listRowBackground(Color.fpSurface)
                    } header: {
                        Text("About")
                            .foregroundStyle(Color.fpTextSecondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.fpPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

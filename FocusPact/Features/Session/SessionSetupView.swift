import SwiftUI
import SwiftUI
import SwiftData

struct SessionSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @EnvironmentObject private var blockingService: BlockingService

    @Query private var blocklists: [BlockList]

    // Form state
    @State private var sessionName:       String    = ""
    @State private var selectedDuration:  Int       = 25
    @State private var customDuration:    Double    = 30
    @State private var isCustom:          Bool      = false
    @State private var selectedBlocklist: BlockList? = nil
    @State private var isLockedMode:      Bool      = false
    @State private var inviteFriend:      Bool      = false

    @State private var navigateToSession: Bool        = false
    @State private var pendingSession:    FocusSession? = nil

    let preset: QuickPreset?

    private let durations = [25, 45, 60, 90]

    var effectiveDuration: Int {
        isCustom ? Int(customDuration) : selectedDuration
    }

    var body: some View {
        ZStack {
            Color.fpBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    sessionNameField
                    durationPicker
                    if isCustom { customDurationSlider }
                    blocklistSelector
                    optionToggles
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("New Session")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .navigationDestination(isPresented: $navigateToSession) {
            if let session = pendingSession {
                SessionView(session: session)
            }
        }
        .onAppear {
            insertPresetsIfNeeded()
            applyPreset()
        }
    }

    // MARK: - Session Name

    private var sessionNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Session Name")
            TextField("e.g. Deep Work, Study, Writing", text: $sessionName)
                .textFieldStyle(.plain)
                .foregroundColor(.fpTextPrimary)
                .padding(14)
                .background(Color.fpSurface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.fpBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Duration")
            HStack(spacing: 10) {
                ForEach(durations, id: \.self) { d in
                    durationButton("\(d)m", isSelected: !isCustom && selectedDuration == d) {
                        selectedDuration = d
                        isCustom = false
                    }
                }
                durationButton("Custom", isSelected: isCustom) {
                    isCustom = true
                }
            }
        }
    }

    private func durationButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .fpTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.fpPrimary : Color.fpSurface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.fpBorder, lineWidth: 1)
                )
        }
    }

    // MARK: - Custom Duration Slider

    private var customDurationSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Custom Duration")
                    .font(.system(size: 14))
                    .foregroundColor(.fpTextSecondary)
                Spacer()
                Text("\(Int(customDuration)) min")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.fpPrimary)
            }
            Slider(value: $customDuration, in: 5...120, step: 5)
                .tint(.fpPrimary)
        }
        .padding(16)
        .background(Color.fpSurface)
        .cornerRadius(14)
    }

    // MARK: - Blocklist Selector

    private var blocklistSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Block List")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(blocklists) { bl in
                        blocklistChip(bl)
                    }
                }
            }
            if selectedBlocklist == nil {
                Text("Select a blocklist to continue")
                    .font(.system(size: 12))
                    .foregroundColor(.fpDanger)
            }
        }
    }

    private func blocklistChip(_ bl: BlockList) -> some View {
        let isSelected = selectedBlocklist?.id == bl.id
        return Button {
            selectedBlocklist = bl
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(bl.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .fpTextPrimary)
                Text("\(bl.domains.count) domains")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .fpTextSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fpPrimary : Color.fpSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.fpBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Option Toggles

    private var optionToggles: some View {
        VStack(spacing: 12) {
            toggleCard(
                icon: "lock.fill",
                title: "Locked Mode",
                description: "Cannot end session early once started.",
                binding: $isLockedMode
            )
            toggleCard(
                icon: "person.2.fill",
                title: "Invite Friend",
                description: "Create a pact — you focus together.",
                binding: $inviteFriend
            )
        }
    }

    private func toggleCard(icon: String, title: String, description: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.fpPrimary)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.fpTextPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.fpTextSecondary)
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(.fpPrimary)
        }
        .padding(16)
        .background(Color.fpSurface)
        .cornerRadius(14)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            beginSession()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Session")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                selectedBlocklist != nil
                    ? LinearGradient.fpPrimaryGradient
                    : LinearGradient(colors: [Color.fpBorder], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(24)
        }
        .disabled(selectedBlocklist == nil)
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.fpTextPrimary)
    }

    private func insertPresetsIfNeeded() {
        guard blocklists.isEmpty else { return }
        for preset in BlockList.presets {
            modelContext.insert(preset)
        }
        try? modelContext.save()
    }

    private func applyPreset() {
        guard let p = preset else { return }
        sessionName      = p.name
        selectedDuration = p.duration
        isCustom         = false
        if let match = blocklists.first(where: { $0.name == p.blocklist }) {
            selectedBlocklist = match
        }
    }

    private func beginSession() {
        guard let bl = selectedBlocklist else { return }
        let session = FocusSession(
            name:            sessionName.isEmpty ? "Focus Session" : sessionName,
            durationMinutes: effectiveDuration,
            blocklistName:   bl.name,
            blockedDomains:  bl.domains,
            isLocked:        isLockedMode,
            pactFriendId:    inviteFriend ? "pending" : nil
        )
        pendingSession   = session
        navigateToSession = true
    }
}

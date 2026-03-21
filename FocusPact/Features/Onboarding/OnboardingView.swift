import SwiftUI
import SwiftData
import NetworkExtension

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = OnboardingViewModel()
    @State private var showMainApp = false

    var body: some View {
        if showMainApp {
            MainTabView()
        } else {
            TabView(selection: $vm.currentPage) {
                WelcomeScreen(onNext: { vm.currentPage = 1 })
                    .tag(0)
                GoalsScreen(vm: vm, onNext: { vm.currentPage = 2 })
                    .tag(1)
                BlocklistScreen(vm: vm, onNext: { vm.currentPage = 3 })
                    .tag(2)
                EnableFilterScreen(onComplete: {
                    vm.completeOnboarding(modelContext: modelContext)
                    showMainApp = true
                })
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.fpBackground.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .overlay(alignment: .bottom) {
                pageIndicator
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(vm.currentPage == index ? Color.fpPrimary : Color.fpBorder)
                    .frame(width: vm.currentPage == index ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: vm.currentPage)
            }
        }
        .padding(.bottom, 32)
    }
}

// MARK: - WelcomeScreen

private struct WelcomeScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.fpPrimaryGradient)
                        .frame(width: 100, height: 100)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("FocusPact")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(Color.fpTextPrimary)
                Text("Focus deeper.\nAchieve more.\nTogether.")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.fpTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
            VStack(spacing: 12) {
                FeatureRow(icon: "shield.fill", text: "Block distracting websites automatically")
                FeatureRow(icon: "person.2.fill", text: "Focus with friends via Pacts")
                FeatureRow(icon: "sparkles", text: "AI coach to optimize your focus")
            }
            .padding(.horizontal, 20)
            Spacer()
            Button(action: onNext) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.fpPrimaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .background(Color.fpBackground)
    }
}

// MARK: - GoalsScreen

private struct GoalsScreen: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Text("What are your goals?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.fpTextPrimary)
                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fpTextSecondary)
            }
            .padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(vm.goals, id: \.self) { goal in
                    GoalChip(
                        title: goal,
                        isSelected: vm.selectedGoals.contains(goal),
                        onTap: { vm.toggleGoal(goal) }
                    )
                }
            }
            .padding(.horizontal, 20)
            Spacer()
            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        vm.selectedGoals.isEmpty
                        ? LinearGradient(colors: [Color.fpTextSecondary.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient.fpPrimaryGradient
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .disabled(vm.selectedGoals.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .background(Color.fpBackground)
    }
}

// MARK: - BlocklistScreen

private struct BlocklistScreen: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Text("Choose a block list")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.fpTextPrimary)
                Text("You can customize this later")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fpTextSecondary)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(BlockList.presets, id: \.id) { preset in
                    BlocklistPresetRow(
                        blocklist: preset,
                        isSelected: vm.selectedBlocklist?.name == preset.name,
                        onSelect: { vm.selectedBlocklist = preset }
                    )
                }
            }
            .padding(.horizontal, 20)

            if let selected = vm.selectedBlocklist, !selected.domains.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Blocked sites:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.fpTextSecondary)
                    Text(selected.domains.prefix(5).joined(separator: ", ") + (selected.domains.count > 5 ? "..." : ""))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fpTextSecondary)
                }
                .padding(12)
                .background(Color.fpSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fpBorder, lineWidth: 1))
                .padding(.horizontal, 20)
            }

            Spacer()

            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        vm.selectedBlocklist == nil
                        ? LinearGradient(colors: [Color.fpTextSecondary.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient.fpPrimaryGradient
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .disabled(vm.selectedBlocklist == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .background(Color.fpBackground)
    }
}

// MARK: - EnableFilterScreen

private struct EnableFilterScreen: View {
    let onComplete: () -> Void
    @State private var isEnabling: Bool = false
    @State private var isEnabled: Bool = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.fpAccent.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.fpAccent)
                }
                Text("Enable Website Blocker")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.fpTextPrimary)
                    .multilineTextAlignment(.center)
                Text("FocusPact uses iOS Network Extension to block distracting websites during focus sessions. Your traffic is never sent to our servers.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.fpTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                PrivacyRow(icon: "lock.fill", text: "All filtering happens on-device")
                PrivacyRow(icon: "eye.slash.fill", text: "No browsing data is collected")
                PrivacyRow(icon: "checkmark.shield.fill", text: "You can disable at any time")
            }
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    isEnabling = true
                    enableFilter()
                } label: {
                    HStack(spacing: 10) {
                        if isEnabling {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isEnabled ? "checkmark.circle.fill" : "shield.fill")
                        }
                        Text(isEnabled ? "Blocker Enabled!" : "Enable Blocker")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isEnabled ? LinearGradient(colors: [Color.fpAccent], startPoint: .leading, endPoint: .trailing) : LinearGradient.fpPrimaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .disabled(isEnabling || isEnabled)

                Button(action: onComplete) {
                    Text("Skip for now")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.fpTextSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .background(Color.fpBackground)
    }

    private func enableFilter() {
        NEFilterManager.shared().loadFromPreferences { error in
            if error == nil {
                if NEFilterManager.shared().providerConfiguration == nil {
                    let config = NEFilterProviderConfiguration()
                    config.filterSockets = true
                    // Note: filterPackets is not available on iOS, only filterSockets
                    NEFilterManager.shared().providerConfiguration = config
                }
                NEFilterManager.shared().isEnabled = true
                NEFilterManager.shared().saveToPreferences { _ in
                    DispatchQueue.main.async {
                        isEnabling = false
                        isEnabled = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onComplete()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isEnabling = false
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Reusable Onboarding Subviews

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.fpPrimary)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(Color.fpTextSecondary)
            Spacer()
        }
    }
}

private struct GoalChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color.fpTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isSelected
                    ? LinearGradient.fpPrimaryGradient
                    : LinearGradient(colors: [Color.fpSurface], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.clear : Color.fpBorder, lineWidth: 1)
                )
        }
    }
}

private struct BlocklistPresetRow: View {
    let blocklist: BlockList
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(blocklist.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.fpTextPrimary)
                    Text("\(blocklist.domains.count) sites blocked")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fpTextSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.fpPrimary : Color.fpBorder)
            }
            .padding(14)
            .background(isSelected ? Color.fpPrimary.opacity(0.1) : Color.fpSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.fpPrimary : Color.fpBorder, lineWidth: 1)
            )
        }
    }
}

private struct PrivacyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.fpAccent)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.fpTextSecondary)
            Spacer()
        }
        .padding(12)
        .background(Color.fpSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fpBorder, lineWidth: 1))
    }
}

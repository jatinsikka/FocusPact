import Foundation
import SwiftData
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var selectedGoals: Set<String> = []
    @Published var selectedBlocklist: BlockList? = nil

    let goals: [String] = ["Deep Work", "Study", "Sleep Hygiene", "Social Media Detox"]

    func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func completeOnboarding(modelContext: ModelContext) {
        if let blocklist = selectedBlocklist {
            let saved = BlockList(name: blocklist.name, domains: blocklist.domains, isPreset: true)
            modelContext.insert(saved)
        } else {
            for preset in BlockList.presets {
                let saved = BlockList(name: preset.name, domains: preset.domains, isPreset: true)
                modelContext.insert(saved)
            }
        }
        try? modelContext.save()
        UserDefaults.standard.set(Array(selectedGoals), forKey: "userGoals")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

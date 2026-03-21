import Foundation
import SwiftData
import Combine

@MainActor
final class BlocklistViewModel: ObservableObject {
    @Published var showingAddSheet: Bool = false
    @Published var newBlocklistName: String = ""
    @Published var newDomain: String = ""
    @Published var errorMessage: String? = nil

    func loadPresetsIfNeeded(context: ModelContext) {
        print("🔍 BlocklistViewModel: Loading presets...")
        let descriptor = FetchDescriptor<BlockList>(predicate: #Predicate { $0.isPreset == true })
        let existing = (try? context.fetch(descriptor)) ?? []
        
        print("📊 Found \(existing.count) existing presets")
        
        if existing.isEmpty {
            print("➕ Adding preset blocklists...")
            for preset in BlockList.presets {
                let bl = BlockList(name: preset.name, domains: preset.domains, isPreset: true)
                context.insert(bl)
                print("  - Added preset: \(preset.name) with \(preset.domains.count) domains")
            }
            do {
                try context.save()
                print("✅ Presets saved successfully")
            } catch {
                print("❌ Error saving presets: \(error)")
                errorMessage = "Failed to load presets: \(error.localizedDescription)"
            }
        } else {
            print("✅ Presets already loaded")
        }
    }

    func createBlocklist(name: String, domains: [String], context: ModelContext) {
        print("🆕 Creating blocklist: '\(name)' with \(domains.count) domains")
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { 
            print("❌ Name is empty")
            errorMessage = "Name cannot be empty."
            return 
        }
        
        let bl = BlockList(name: trimmedName, domains: domains, isPreset: false)
        context.insert(bl)
        print("  - Inserted into context")
        
        do {
            try context.save()
            print("✅ Blocklist created successfully!")
            showingAddSheet = false
            newBlocklistName = ""
            newDomain = ""
            errorMessage = nil
        } catch {
            print("❌ Error saving blocklist: \(error)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func deleteBlocklist(_ blocklist: BlockList, context: ModelContext) {
        print("🗑️ Deleting blocklist: \(blocklist.name)")
        context.delete(blocklist)
        do {
            try context.save()
            print("✅ Blocklist deleted successfully")
        } catch {
            print("❌ Error deleting: \(error)")
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }

    func addDomain(_ domain: String, to blocklist: BlockList, context: ModelContext, service: BlockingService) {
        print("➕ Adding domain '\(domain)' to '\(blocklist.name)'")
        let cleaned = domain.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        
        guard !cleaned.isEmpty else {
            print("❌ Domain is empty after cleaning")
            return
        }
        guard !blocklist.domains.contains(cleaned) else { 
            print("⚠️ Domain already exists: \(cleaned)")
            return 
        }
        
        blocklist.domains.append(cleaned)
        service.updateActiveDomainsIfNeeded(for: blocklist)
        print("  - Added to array")
        
        do {
            try context.save()
            print("✅ Domain added successfully")
        } catch {
            print("❌ Error saving domain: \(error)")
            errorMessage = "Failed to add domain: \(error.localizedDescription)"
        }
    }

    func removeDomain(_ domain: String, from blocklist: BlockList, context: ModelContext) {
        print("➖ Removing domain '\(domain)' from '\(blocklist.name)'")
        blocklist.domains.removeAll { $0 == domain }
        do {
            try context.save()
            print("✅ Domain removed successfully")
        } catch {
            print("❌ Error removing: \(error)")
            errorMessage = "Failed to remove domain: \(error.localizedDescription)"
        }
    }
}

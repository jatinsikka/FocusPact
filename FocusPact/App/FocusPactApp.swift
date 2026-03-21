import SwiftUI
import SwiftData

@main
struct FocusPactApp: App {
    @StateObject private var blockingService = BlockingService()
    @StateObject private var aiService = AICoachService()
    @StateObject private var supabaseService = SupabaseService()
    @StateObject private var notificationService = NotificationService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SessionRecord.self, BlockList.self, LocalPact.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blockingService)
                .environmentObject(aiService)
                .environmentObject(supabaseService)
                .environmentObject(notificationService)
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

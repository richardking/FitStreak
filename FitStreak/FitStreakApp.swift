// FitStreak/FitStreakApp.swift
import SwiftUI
import SwiftData

@main
struct FitStreakApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ActivityEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // UI-test escape hatch: when launched with `-resetData`, wipe entries on startup
            // so tests start from a known empty state. No-op in normal runs.
            if ProcessInfo.processInfo.arguments.contains("-resetData") {
                let context = container.mainContext
                if let all = try? context.fetch(FetchDescriptor<ActivityEntry>()) {
                    for entry in all { context.delete(entry) }
                    try? context.save()
                }
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

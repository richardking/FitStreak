// FitStreak/FitStreakApp.swift
import SwiftUI
import SwiftData

@main
struct FitStreakApp: App {
    init() {
        // UI-test escape hatch: when launched with `-resetData`, wipe entries on
        // startup so tests start from a known empty state. No-op in normal runs.
        if ProcessInfo.processInfo.arguments.contains("-resetData") {
            let context = SharedModelContainer.shared.mainContext
            if let all = try? context.fetch(FetchDescriptor<ActivityEntry>()) {
                for entry in all { context.delete(entry) }
                try? context.save()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(SharedModelContainer.shared)
    }
}

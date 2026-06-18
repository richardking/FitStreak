// Shared/SharedModelContainer.swift
//
// Single source of truth for the ModelContainer. Both the app target and the
// widget extension target import this file and read `SharedModelContainer.shared`
// so they read/write the same SQLite store, located in the App Group container.

import Foundation
import SwiftData

enum AppGroup {
    static let identifier = "group.com.richardking.FitStreak"
}

enum SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([ActivityEntry.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppGroup.identifier)
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}

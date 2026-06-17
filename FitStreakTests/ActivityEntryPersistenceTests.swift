// FitStreakTests/ActivityEntryPersistenceTests.swift
import Foundation
import SwiftData
import Testing
@testable import FitStreak

@MainActor
struct ActivityEntryPersistenceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ActivityEntry.self, configurations: config)
    }

    @Test func insertedEntryRoundTripsAllFields() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let id = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = ActivityEntry(
            id: id,
            loggedAt: when,
            timezone: TimeZone(identifier: "America/New_York")!,
            kind: .running
        )
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ActivityEntry>())
        #expect(fetched.count == 1)
        let first = try #require(fetched.first)
        #expect(first.id == id)
        #expect(first.loggedAt == when)
        #expect(first.timezoneIdentifier == "America/New_York")
        #expect(first.kind == .running)
        #expect(first.timezone.identifier == "America/New_York")
    }

    @Test func deletingEntryRemovesItFromFetchResults() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let entry = ActivityEntry(
            loggedAt: Date(timeIntervalSince1970: 0),
            timezone: .gmt,
            kind: .other
        )
        context.insert(entry)
        try context.save()

        context.delete(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ActivityEntry>())
        #expect(fetched.isEmpty)
    }
}

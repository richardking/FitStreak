// FitStreakTests/ActivityLoggerTests.swift
import Foundation
import SwiftData
import Testing
@testable import FitStreak

@MainActor
struct ActivityLoggerTests {
    // Note: return the container (not just its context) so the caller keeps it
    // alive. Letting the container drop while the context lives crashes
    // SwiftData on the next fetch.
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ActivityEntry.self, configurations: config)
    }

    private func dayKey(_ offsetDays: Int) -> DayKey {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offsetDays, to: .now) ?? .now
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }

    @Test func togglingABackfillDayInsertsThenDeletes() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let yesterday = dayKey(-1)

        let logged = try ActivityLogger.toggleEntry(of: .weights, onDay: yesterday, in: context)
        #expect(logged)
        #expect(try context.fetch(FetchDescriptor<ActivityEntry>()).count == 1)

        let unlogged = try ActivityLogger.toggleEntry(of: .weights, onDay: yesterday, in: context)
        #expect(!unlogged)
        #expect(try context.fetch(FetchDescriptor<ActivityEntry>()).isEmpty)
    }

    @Test func insertedEntryRoundTripsThroughLoggedDayKey() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let twoDaysAgo = dayKey(-2)

        _ = try ActivityLogger.toggleEntry(of: .running, onDay: twoDaysAgo, in: context)

        let entries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let entry = try #require(entries.first)
        let calculator = StreakCalculator(calendar: .current, now: .now)
        #expect(calculator.loggedDayKey(for: entry) == twoDaysAgo)
    }

    @Test func togglingDifferentKindsOnTheSameDayCoexist() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let today = dayKey(0)

        _ = try ActivityLogger.toggleEntry(of: .weights, onDay: today, in: context)
        _ = try ActivityLogger.toggleEntry(of: .running, onDay: today, in: context)

        let entries = try context.fetch(FetchDescriptor<ActivityEntry>())
        #expect(entries.count == 2)
        #expect(Set(entries.map(\.kind)) == [.weights, .running])

        _ = try ActivityLogger.toggleEntry(of: .weights, onDay: today, in: context)
        let remaining = try context.fetch(FetchDescriptor<ActivityEntry>())
        #expect(remaining.map(\.kind) == [.running])
    }

    @Test func togglingTodayConvenienceMatchesGeneralForm() throws {
        let container = try makeContainer()
        let context = container.mainContext

        _ = try ActivityLogger.toggleTodaysEntry(of: .pickleball, in: context)

        let entries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let entry = try #require(entries.first)
        #expect(entry.kind == .pickleball)
        // Must map to today's DayKey.
        let calculator = StreakCalculator(calendar: .current, now: .now)
        #expect(calculator.loggedDayKey(for: entry) == dayKey(0))
    }
}

// FitStreakTests/StreakIntegrationTests.swift
import Foundation
import SwiftData
import Testing
@testable import FitStreak

@MainActor
struct StreakIntegrationTests {
    @Test func fetchedEntriesProduceCorrectStreak() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ActivityEntry.self, configurations: config)
        let context = container.mainContext

        let tz = "America/New_York"
        let zone = TimeZone(identifier: tz)!
        let dates = [
            "2026-06-15 09:00",  // Mon
            "2026-06-16 09:00",  // Tue
            "2026-06-17 09:00",  // Wed
        ]
        for s in dates {
            context.insert(ActivityEntry(
                loggedAt: StreakTestSupport.date(s, in: tz),
                timezone: zone,
                kind: .workout
            ))
        }
        try context.save()

        let entries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-17 20:00", in: tz)  // Wed eve
        )
        #expect(calculator.currentStreak(from: entries) == 3)
    }
}

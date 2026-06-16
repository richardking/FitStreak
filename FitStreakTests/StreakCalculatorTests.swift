// FitStreakTests/StreakCalculatorTests.swift
import Foundation
import Testing
@testable import FitStreak

struct StreakCalculatorTests {
    @Test func emptyEntriesReturnsZero() {
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: "America/New_York"),
            now: StreakTestSupport.date("2026-06-15 12:00", in: "America/New_York")
        )
        #expect(calculator.currentStreak(from: []) == 0)
    }

    @Test func loggedDayKeyUsesEntryTimezone() {
        // Calculator is in Tokyo, entry was logged at 11pm NY time.
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: "Asia/Tokyo"),
            now: StreakTestSupport.date("2026-06-15 12:00", in: "Asia/Tokyo")
        )
        let entry = StreakTestSupport.entry(at: "2026-06-10 23:00", in: "America/New_York")
        // 11pm NY on Jun 10 is 12pm Tokyo on Jun 11. Entry's day must remain Jun 10.
        #expect(calculator.loggedDayKey(for: entry) == DayKey(year: 2026, month: 6, day: 10))
    }

    @Test func singleEntryTodayReturnsOne() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-15 20:00", in: tz)   // Mon
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz)]
        #expect(calculator.currentStreak(from: entries) == 1)
    }
}

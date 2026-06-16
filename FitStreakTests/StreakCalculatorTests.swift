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

    @Test func consecutiveWeekdaysReturnFive() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-19 20:00", in: tz)   // Fri
        )
        let entries = [
            StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz),  // Mon
            StreakTestSupport.entry(at: "2026-06-16 09:00", in: tz),  // Tue
            StreakTestSupport.entry(at: "2026-06-17 09:00", in: tz),  // Wed
            StreakTestSupport.entry(at: "2026-06-18 09:00", in: tz),  // Thu
            StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz),  // Fri
        ]
        #expect(calculator.currentStreak(from: entries) == 5)
    }

    @Test func weekdayMissBreaksStreak() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-23 20:00", in: tz)   // Tue (next week)
        )
        // Logged the prior Friday; nothing since. Mon was a weekday with no log.
        let entries = [StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz)]
        #expect(calculator.currentStreak(from: entries) == 0)
    }

    @Test func weekendIsFreeWhenWeekdayBeforeWasLogged() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-22 09:00", in: tz)   // Mon, no log yet
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz)]   // Fri
        #expect(calculator.currentStreak(from: entries) == 1)
    }

    @Test func weekendLogsExtendCount() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-22 20:00", in: tz)   // Mon
        )
        let entries = [
            "2026-06-15", "2026-06-16", "2026-06-17", "2026-06-18", "2026-06-19", // Mon-Fri
            "2026-06-20", "2026-06-21",                                            // Sat-Sun
            "2026-06-22",                                                          // Mon
        ].map { StreakTestSupport.entry(at: "\($0) 09:00", in: tz) }
        #expect(calculator.currentStreak(from: entries) == 8)
    }

    @Test func todayUnloggedYesterdayWeekdayLogged() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-16 09:00", in: tz)   // Tue, no log yet
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz)] // Mon
        #expect(calculator.currentStreak(from: entries) == 1)
    }

    @Test func todayUnloggedSaturdayFridayLogged() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-20 09:00", in: tz)   // Sat, no log yet
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz)] // Fri
        #expect(calculator.currentStreak(from: entries) == 1)
    }

    @Test func duplicateSameDayEntriesCountOnce() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-15 22:00", in: tz)
        )
        let entries = [
            StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz),
            StreakTestSupport.entry(at: "2026-06-15 18:00", in: tz),
        ]
        #expect(calculator.currentStreak(from: entries) == 1)
    }
}

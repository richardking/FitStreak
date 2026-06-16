// FitStreakTests/DayKeyTests.swift
import Testing
@testable import FitStreak

struct DayKeyTests {
    @Test func equalKeysAreEqual() {
        #expect(DayKey(year: 2026, month: 6, day: 15) == DayKey(year: 2026, month: 6, day: 15))
    }

    @Test func differentKeysAreNotEqual() {
        #expect(DayKey(year: 2026, month: 6, day: 15) != DayKey(year: 2026, month: 6, day: 16))
        #expect(DayKey(year: 2026, month: 6, day: 15) != DayKey(year: 2026, month: 7, day: 15))
        #expect(DayKey(year: 2026, month: 6, day: 15) != DayKey(year: 2027, month: 6, day: 15))
    }

    @Test func keysAreHashable() {
        let set: Set<DayKey> = [
            DayKey(year: 2026, month: 6, day: 15),
            DayKey(year: 2026, month: 6, day: 15),
            DayKey(year: 2026, month: 6, day: 16),
        ]
        #expect(set.count == 2)
    }
}

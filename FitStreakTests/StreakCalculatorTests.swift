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
}

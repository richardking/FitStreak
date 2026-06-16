// FitStreakTests/ActivityKindTests.swift
import Testing
@testable import FitStreak

struct ActivityKindTests {
    @Test func rawValuesAreStable() {
        #expect(ActivityKind.workout.rawValue == "workout")
        #expect(ActivityKind.walk.rawValue == "walk")
        #expect(ActivityKind.other.rawValue == "other")
    }

    @Test func roundTripsThroughRawValue() {
        for kind in ActivityKind.allCases {
            #expect(ActivityKind(rawValue: kind.rawValue) == kind)
        }
    }
}

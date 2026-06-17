// FitStreakTests/ActivityKindTests.swift
import Testing
@testable import FitStreak

struct ActivityKindTests {
    @Test func rawValuesAreStable() {
        #expect(ActivityKind.weights.rawValue == "weights")
        #expect(ActivityKind.running.rawValue == "running")
        #expect(ActivityKind.pickleball.rawValue == "pickleball")
        #expect(ActivityKind.other.rawValue == "other")
    }

    @Test func roundTripsThroughRawValue() {
        for kind in ActivityKind.allCases {
            #expect(ActivityKind(rawValue: kind.rawValue) == kind)
        }
    }
}

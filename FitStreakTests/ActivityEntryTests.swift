// FitStreakTests/ActivityEntryTests.swift
import Foundation
import Testing
@testable import FitStreak

struct ActivityEntryTests {
    @Test func initializerSetsAllFields() {
        let id = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let tz = TimeZone(identifier: "America/New_York")!
        let entry = ActivityEntry(id: id, loggedAt: when, timezone: tz, kind: .running)

        #expect(entry.id == id)
        #expect(entry.loggedAt == when)
        #expect(entry.timezoneIdentifier == "America/New_York")
        #expect(entry.kindRaw == "running")
    }

    @Test func kindAccessorRoundTripsThroughRawString() {
        let entry = ActivityEntry(
            loggedAt: Date(timeIntervalSince1970: 0),
            timezone: .gmt,
            kind: .weights
        )
        #expect(entry.kind == .weights)
        entry.kind = .other
        #expect(entry.kindRaw == "other")
    }

    @Test func timezoneAccessorRoundTripsThroughIdentifier() {
        let entry = ActivityEntry(
            loggedAt: Date(timeIntervalSince1970: 0),
            timezone: TimeZone(identifier: "Asia/Tokyo")!,
            kind: .weights
        )
        #expect(entry.timezone.identifier == "Asia/Tokyo")
    }
}

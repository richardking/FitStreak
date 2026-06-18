// FitStreak/ActivityEntry.swift
import Foundation
import SwiftData

@Model
final class ActivityEntry {
    var id: UUID
    var loggedAt: Date
    var timezoneIdentifier: String
    var kindRaw: String

    var kind: ActivityKind {
        get { ActivityKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }

    init(id: UUID = UUID(),
         loggedAt: Date,
         timezone: TimeZone,
         kind: ActivityKind) {
        self.id = id
        self.loggedAt = loggedAt
        self.timezoneIdentifier = timezone.identifier
        self.kindRaw = kind.rawValue
    }
}

// FitStreakTests/StreakTestSupport.swift
import Foundation
@testable import FitStreak

enum StreakTestSupport {
    static func calendar(timezone: String) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: timezone) ?? .gmt
        return cal
    }

    /// Parse "YYYY-MM-DD HH:mm" as a wall-clock time in the given IANA timezone.
    static func date(_ string: String, in timezone: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: timezone)
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.date(from: string)!
    }

    static func entry(at string: String,
                      in timezone: String,
                      kind: ActivityKind = .weights) -> ActivityEntry {
        ActivityEntry(
            loggedAt: date(string, in: timezone),
            timezone: TimeZone(identifier: timezone) ?? .gmt,
            kind: kind
        )
    }
}

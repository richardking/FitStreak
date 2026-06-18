// Shared/ActivityLogger.swift
//
// The single place that translates "tap an activity card" into SwiftData
// writes. Used by HomeView, the day-detail sheet, and LogActivityIntent so
// no surface can drift from another.

import Foundation
import SwiftData
import WidgetKit

@MainActor
enum ActivityLogger {
    /// Toggle entries of `kind` on `targetDay`: insert one if none exist for
    /// that day + kind, delete all of them if any do. Saves the context.
    /// Returns true if the activity ended up logged after the call.
    ///
    /// New entries are anchored at noon local time on `targetDay` so that
    /// `loggedDayKey(for:)` always round-trips back to the same `targetDay`
    /// regardless of DST oddities.
    @discardableResult
    static func toggleEntry(of kind: ActivityKind, onDay targetDay: DayKey, in context: ModelContext) throws -> Bool {
        let calendar = Calendar.current
        let calculator = StreakCalculator(calendar: calendar, now: .now)

        let allEntries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let existing = allEntries.filter {
            $0.kind == kind && calculator.loggedDayKey(for: $0) == targetDay
        }

        defer { WidgetCenter.shared.reloadAllTimelines() }
        if existing.isEmpty {
            var comps = DateComponents()
            comps.year = targetDay.year
            comps.month = targetDay.month
            comps.day = targetDay.day
            comps.hour = 12
            let loggedAt = calendar.date(from: comps) ?? .now
            context.insert(ActivityEntry(loggedAt: loggedAt, timezone: .current, kind: kind))
            try context.save()
            return true
        } else {
            for entry in existing {
                context.delete(entry)
            }
            try context.save()
            return false
        }
    }

    /// Convenience for the most common case: log/unlog today.
    @discardableResult
    static func toggleTodaysEntry(of kind: ActivityKind, in context: ModelContext) throws -> Bool {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: .now)
        let todayKey = DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
        return try toggleEntry(of: kind, onDay: todayKey, in: context)
    }
}

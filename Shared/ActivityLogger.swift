// Shared/ActivityLogger.swift
//
// The single place that translates "tap an activity card" into SwiftData
// writes. Used by HomeView and by LogActivityIntent so the widget can't
// drift from in-app behavior.

import Foundation
import SwiftData

@MainActor
enum ActivityLogger {
    /// Toggle today's entries of `kind` in the given context: insert one if
    /// none exist for today, delete all of them if any do. Saves the context.
    /// Returns true if the activity ended up logged after the call, false if unlogged.
    @discardableResult
    static func toggleTodaysEntry(of kind: ActivityKind, in context: ModelContext) throws -> Bool {
        let calendar = Calendar.current
        let calculator = StreakCalculator(calendar: calendar, now: .now)
        let comps = calendar.dateComponents([.year, .month, .day], from: .now)
        let todayKey = DayKey(year: comps.year!, month: comps.month!, day: comps.day!)

        let allEntries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let existing = allEntries.filter {
            $0.kind == kind && calculator.loggedDayKey(for: $0) == todayKey
        }

        if existing.isEmpty {
            context.insert(ActivityEntry(loggedAt: .now, timezone: .current, kind: kind))
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
}

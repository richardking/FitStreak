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
            context.insert(ActivityEntry(
                loggedAt: newEntryLoggedAt(for: targetDay, calendar: calendar),
                timezone: .current,
                kind: kind
            ))
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

    /// Convenience for the most common case: toggle today.
    @discardableResult
    static func toggleTodaysEntry(of kind: ActivityKind, in context: ModelContext) throws -> Bool {
        try toggleEntry(of: kind, onDay: todaysKey(), in: context)
    }

    /// Insert one additional entry for `kind` on `targetDay`, regardless of
    /// how many already exist. Used by the "Log again" long-press action so a
    /// user can record a second/third workout in the same day. Returns the
    /// new total count of entries for (kind, targetDay) after the insert.
    @discardableResult
    static func addEntry(of kind: ActivityKind, onDay targetDay: DayKey, in context: ModelContext) throws -> Int {
        let calendar = Calendar.current
        let calculator = StreakCalculator(calendar: calendar, now: .now)
        let allEntries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let existingCount = allEntries.filter {
            $0.kind == kind && calculator.loggedDayKey(for: $0) == targetDay
        }.count

        defer { WidgetCenter.shared.reloadAllTimelines() }
        context.insert(ActivityEntry(
            loggedAt: newEntryLoggedAt(for: targetDay, calendar: calendar),
            timezone: .current,
            kind: kind
        ))
        try context.save()
        return existingCount + 1
    }

    /// Delete the most recent single entry for `kind` on `targetDay`. Used by
    /// the "Remove last log" long-press action. No-op if there's nothing
    /// logged. Returns the count remaining after the delete.
    @discardableResult
    static func removeOneEntry(of kind: ActivityKind, onDay targetDay: DayKey, in context: ModelContext) throws -> Int {
        let calendar = Calendar.current
        let calculator = StreakCalculator(calendar: calendar, now: .now)
        let allEntries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let candidates = allEntries
            .filter { $0.kind == kind && calculator.loggedDayKey(for: $0) == targetDay }
            .sorted {
                if $0.loggedAt != $1.loggedAt { return $0.loggedAt > $1.loggedAt }
                return $0.id.uuidString > $1.id.uuidString   // stable tiebreaker
            }

        defer { WidgetCenter.shared.reloadAllTimelines() }
        guard let mostRecent = candidates.first else { return 0 }
        context.delete(mostRecent)
        try context.save()
        return candidates.count - 1
    }

    // MARK: - Helpers

    private static func todaysKey(calendar: Calendar = .current) -> DayKey {
        let comps = calendar.dateComponents([.year, .month, .day], from: .now)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }

    /// New entries on today are stamped with `.now` so multi-logs throughout
    /// the day are distinguishable. New entries on past days are stamped at
    /// noon-local — any time-of-day on the same DayKey behaves the same for
    /// the streak, and noon is comfortably away from day-boundary DST edges.
    private static func newEntryLoggedAt(for targetDay: DayKey, calendar: Calendar) -> Date {
        let nowComps = calendar.dateComponents([.year, .month, .day], from: .now)
        if nowComps.year == targetDay.year
            && nowComps.month == targetDay.month
            && nowComps.day == targetDay.day {
            return .now
        }
        var comps = DateComponents()
        comps.year = targetDay.year
        comps.month = targetDay.month
        comps.day = targetDay.day
        comps.hour = 12
        return calendar.date(from: comps) ?? .now
    }
}

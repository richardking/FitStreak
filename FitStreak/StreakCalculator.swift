// FitStreak/StreakCalculator.swift
import Foundation

struct DayKey: Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int
}

struct StreakCalculator {
    let calendar: Calendar
    let now: Date

    func currentStreak(from entries: [ActivityEntry]) -> Int {
        let loggedDays = Set(entries.map { loggedDayKey(for: $0) })
        var count = 0
        var cursor = calendar.startOfDay(for: now)
        while loggedDays.contains(dayKey(of: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return count
    }

    func loggedDayKey(for entry: ActivityEntry) -> DayKey {
        var entryCalendar = Calendar(identifier: .gregorian)
        entryCalendar.timeZone = entry.timezone
        let comps = entryCalendar.dateComponents([.year, .month, .day], from: entry.loggedAt)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }

    private func dayKey(of date: Date) -> DayKey {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }
}

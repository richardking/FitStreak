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
        var isFirstDay = true

        while true {
            let key = dayKey(of: cursor)
            let weekday = calendar.component(.weekday, from: cursor)
            let isWeekend = (weekday == 1 || weekday == 7)   // Sun = 1, Sat = 7 (gregorian)

            if loggedDays.contains(key) {
                count += 1
            } else if isFirstDay {
                // Today, not yet logged — pending, not a break.
            } else if isWeekend {
                // Skipped weekend, streak continues.
            } else {
                break   // Missed weekday — streak ends.
            }

            isFirstDay = false
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

# Streak Tracking — Core Logic & Data Model

**Date:** 2026-06-15
**Scope:** Domain model and streak calculation engine for FitStreak. No UI in this task.

## Goal

Implement the persistence model for logged activity and the derivation of a "current streak" number, test-driven, so a later UI task can simply read computed values.

## Resolved design decisions

| Question | Decision |
|---|---|
| What counts as a logged day | A day has ≥1 `ActivityEntry` whose logged day matches |
| Day boundary | Local calendar midnight, no grace period |
| Weekday miss | Streak resets to 0 |
| Weekend miss | Free — streak continues |
| Weekend log | Counts toward the streak length number |
| Retroactive log window | Allowed if `now − endOfDay(targetDay) ≤ 48h` |
| Per-entry stored fields | `id`, `loggedAt`, `timezoneIdentifier`, `kind` |
| Streak storage | Derived from entries; not cached |
| Timezone semantics | Each entry frozen to the timezone it was logged in |
| Same-day duplicate logs | Both stored; the day still counts once |
| DST / leap day handling | Delegated to `Calendar` arithmetic (no special cases in code) |

## Architecture

Three units, each with a single responsibility:

### 1. `ActivityKind`

```swift
enum ActivityKind: String, Codable, CaseIterable {
    case workout, walk, other
}
```

Stable string raw values so SwiftData round-trips are stable across renames.

### 2. `ActivityEntry` (SwiftData `@Model`)

```swift
@Model
final class ActivityEntry {
    var id: UUID
    var loggedAt: Date              // wall-clock instant
    var timezoneIdentifier: String  // IANA, e.g. "America/New_York"
    var kindRaw: String             // ActivityKind.rawValue

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
```

Raw-stringly storage for the enum and timezone; typed computed accessors for the rest of the codebase. No streak fields — derived everywhere.

### 3. `StreakCalculator` (pure value type)

```swift
struct DayKey: Hashable {
    let year: Int
    let month: Int
    let day: Int
}

struct StreakCalculator {
    let calendar: Calendar   // carries the device's current timezone
    let now: Date            // injected; never reads system clock directly

    func currentStreak(from entries: [ActivityEntry]) -> Int
    func loggedDayKey(for entry: ActivityEntry) -> DayKey
    func canBackfill(targetDay: DayKey) -> Bool
}
```

- No SwiftData dependency — operates on plain `[ActivityEntry]`.
- `calendar` and `now` injected so tests can pin time and timezone.
- All calendar math goes through `Calendar`, which handles DST and leap days correctly.

## Streak algorithm

Walk backward day-by-day from today in the device's current timezone:

```
let S: Set<DayKey> = Set(entries.map { loggedDayKey(for: $0) })
var count = 0
var cursor = calendar.startOfDay(for: now)
var isFirstDay = true

loop:
    let key = dayKey(of: cursor)                // in device tz
    let isWeekend = (calendar.component(.weekday, from: cursor) is Sat or Sun)

    if S.contains(key) {
        count += 1
    } else if isFirstDay {
        // Today, not yet logged — pending, not a break, not counted
    } else if isWeekend {
        // Free skip
    } else {
        break    // Missed weekday → streak ends
    }

    isFirstDay = false
    cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!

return count
```

Helper bodies:

- **`loggedDayKey(for entry:)`** — builds a Calendar with `entry.timezone`, extracts `(year, month, day)` of `entry.loggedAt`. The result is permanent for that entry.
- **`dayKey(of cursor:)`** — extracts `(year, month, day)` of `cursor` in the calculator's own (device) calendar.
- **`canBackfill(targetDay:)`** — let `start = startOfDay(targetDay)` and `end = start + 1 day` in device tz; return `now − end ≤ 48 * 3600`. Today is always backfillable (`end > now`, so the gap is negative — within window). Future days return `false` via an explicit guard.

### Behavioral invariants the algorithm produces

| Scenario | Expected result |
|---|---|
| Zero entries | streak = 0 |
| Logged Mon, asked Mon evening | 1 |
| Logged Fri, asked the following Mon (no Mon log yet) | 1 — Mon pending, Sat/Sun free, Fri logged |
| Logged Fri, asked the following Tue | 0 — Mon was a weekday with no log |
| Logged Sat + Sun + Mon, asked Mon evening | 3 — weekend logs count |
| Multiple entries same day | day counted once |
| Entry logged 11pm NYC, viewer in Tokyo | entry's day stays the NYC date (consequence: a late-evening NYC log may appear "shifted" on a Tokyo viewer's grid — accepted; documented; no UI yet) |
| DST spring-forward day | one calendar day, handled by `Calendar` |
| Leap day (Feb 29) | one calendar day, handled by `Calendar` |

## Test plan (TDD)

Three layers; each task = one failing Swift Testing test, then implementation to make it pass.

### Layer A — `StreakCalculator` (pure, no SwiftData)

Inject `now` and a pinned-timezone `Calendar`. Build `ActivityEntry` instances directly (no `ModelContext` needed for in-memory math).

Required cases:

- Empty entries → 0.
- One entry today → 1.
- Consecutive Mon–Fri logs ending today (Fri) → 5.
- Logged Fri, today is the next Mon, no log today → 1 (weekend skip).
- Logged Fri, today is the next Tue → 0 (Mon weekday miss).
- Logged Sat + Sun + Mon, today is that Mon → 3 (weekend logs count).
- Today not yet logged, but yesterday (a weekday) is logged → 1.
- Today is Saturday, no log yet, Friday is logged → 1 (today-pending works for weekend days too).
- Two entries on the same day → counts as 1.
- DST spring-forward window crossed mid-streak → still correct count.
- Leap day Feb 29 spans correctly.
- Entry with timezone different from device timezone keeps its original day.
- `canBackfill`: today → true, yesterday → true, 3 days ago → false, tomorrow → false.

### Layer B — `ActivityEntry` persistence

`ModelContainer` with `ModelConfiguration(isStoredInMemoryOnly: true)`.

- Insert → fetch round-trip preserves all fields.
- `kind` computed accessor round-trips through `kindRaw`.
- `timezone` accessor round-trips through `timezoneIdentifier`.
- Delete removes the entry from fetch results.

### Layer C — Integration

One end-to-end test: insert entries through a `ModelContext`, fetch them, hand the array to `StreakCalculator`, assert the streak count.

### Tooling note

Per CLAUDE.md: use `BuildProject` for builds, `RunAllTests`/`RunSomeTests` for tests, and `DocumentationSearch` plus the swiftui-skills local docs for any SwiftData API question (e.g., `ModelConfiguration` flags, predicate syntax) — not memory.

## Out of scope

- UI of any kind (no SwiftUI views, no previews).
- Cached `StreakState` model (deferred until performance requires it).
- Configurable goals or activity quotas (current rule: any entry counts).
- Notifications, sync, HealthKit, widgets.
- Streak Freeze / pause / vacation mode.

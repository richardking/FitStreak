# Streak Tracking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the SwiftData model and pure streak-calculation engine for FitStreak's daily logging streak, test-driven, no UI.

**Architecture:** Three units. `ActivityKind` (enum), `ActivityEntry` (SwiftData `@Model` with stored timezone), `StreakCalculator` (pure value type that derives current streak from `[ActivityEntry]` via a backward day-walk). Streak math is fully derived — no cached streak fields. See `docs/superpowers/specs/2026-06-15-streak-tracking-design.md` for the design rationale.

**Tech Stack:** Swift (latest stable), SwiftData (`@Model`, `ModelContainer`), Swift Testing (`@Test`, `#expect`), Xcode MCP (`BuildProject`, `RunSomeTests`, `RunAllTests`). iOS target.

**Project layout note:** The `.xcodeproj` uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+). New `.swift` files inside `FitStreak/` and `FitStreakTests/` are auto-included in their target — no pbxproj edits required.

---

## File Structure

**Source (target: FitStreak):**
- Create `FitStreak/ActivityKind.swift` — the enum.
- Create `FitStreak/ActivityEntry.swift` — the SwiftData `@Model`.
- Create `FitStreak/StreakCalculator.swift` — contains `DayKey` and `StreakCalculator`.
- Modify `FitStreak/FitStreakApp.swift` — swap `Item.self` → `ActivityEntry.self` in the schema.
- Modify `FitStreak/ContentView.swift` — gut to a one-line placeholder (no UI in this task).
- Delete `FitStreak/Item.swift` — superseded by `ActivityEntry`.

**Tests (target: FitStreakTests):**
- Create `FitStreakTests/StreakTestSupport.swift` — shared test helpers.
- Create `FitStreakTests/ActivityKindTests.swift` — enum raw-value round-trip.
- Create `FitStreakTests/DayKeyTests.swift` — equality/hash.
- Create `FitStreakTests/ActivityEntryTests.swift` — initializer + accessor round-trips (no SwiftData container).
- Create `FitStreakTests/StreakCalculatorTests.swift` — Layer A; grows over many tasks.
- Create `FitStreakTests/ActivityEntryPersistenceTests.swift` — Layer B; in-memory `ModelContainer`.
- Create `FitStreakTests/StreakIntegrationTests.swift` — Layer C; end-to-end.
- Delete `FitStreakTests/FitStreakTests.swift` — placeholder template stub.

---

## Conventions used in this plan

**Xcode MCP commands.** "Build" = `BuildProject` (scheme `FitStreak`, destination an iOS simulator the user has available, e.g. iPhone 15). "Run all tests" = `RunAllTests` (same scheme/destination). "Run one test" = `RunSomeTests` with the test identifier in Swift Testing form: `FitStreakTests/SuiteName/testName()`.

**Commit messages.** Conventional Commits style (`feat:`, `test:`, `chore:`). Subject ≤72 chars.

**File header.** Each new file starts with one comment line — `// FitStreak/Path/File.swift` — for orientation. No template Xcode banner.

---

## Task 1: ActivityKind enum

**Files:**
- Create: `FitStreak/ActivityKind.swift`
- Create: `FitStreakTests/ActivityKindTests.swift`
- Delete: `FitStreakTests/FitStreakTests.swift`

- [ ] **Step 1: Write the failing test**

Create `FitStreakTests/ActivityKindTests.swift`:

```swift
// FitStreakTests/ActivityKindTests.swift
import Testing
@testable import FitStreak

struct ActivityKindTests {
    @Test func rawValuesAreStable() {
        #expect(ActivityKind.workout.rawValue == "workout")
        #expect(ActivityKind.walk.rawValue == "walk")
        #expect(ActivityKind.other.rawValue == "other")
    }

    @Test func roundTripsThroughRawValue() {
        for kind in ActivityKind.allCases {
            #expect(ActivityKind(rawValue: kind.rawValue) == kind)
        }
    }
}
```

Delete `FitStreakTests/FitStreakTests.swift` (the template stub).

- [ ] **Step 2: Build to verify the test fails to compile**

Run `BuildProject` (scheme `FitStreak`).
Expected: build fails with "cannot find 'ActivityKind' in scope".

- [ ] **Step 3: Implement `ActivityKind`**

Create `FitStreak/ActivityKind.swift`:

```swift
// FitStreak/ActivityKind.swift
import Foundation

enum ActivityKind: String, Codable, CaseIterable, Sendable {
    case workout
    case walk
    case other
}
```

- [ ] **Step 4: Run the tests and verify they pass**

Run `RunSomeTests` with identifiers `FitStreakTests/ActivityKindTests/rawValuesAreStable()` and `FitStreakTests/ActivityKindTests/roundTripsThroughRawValue()`.
Expected: both PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/ActivityKind.swift FitStreakTests/ActivityKindTests.swift
git rm FitStreakTests/FitStreakTests.swift
git commit -m "feat: add ActivityKind enum with raw-value round-trip tests"
```

---

## Task 2: ActivityEntry @Model and scaffolding cutover

This task creates `ActivityEntry`, removes `Item`, and updates the app scaffolding so the project still builds. The failing test exercises the initializer and the `kind` / `timezone` computed accessors — no SwiftData container yet (that's Task 17).

**Files:**
- Create: `FitStreak/ActivityEntry.swift`
- Create: `FitStreakTests/ActivityEntryTests.swift`
- Modify: `FitStreak/FitStreakApp.swift` (one line in the schema)
- Modify: `FitStreak/ContentView.swift` (gut to placeholder; no UI in this task)
- Delete: `FitStreak/Item.swift`

- [ ] **Step 1: Write the failing test**

Create `FitStreakTests/ActivityEntryTests.swift`:

```swift
// FitStreakTests/ActivityEntryTests.swift
import Foundation
import Testing
@testable import FitStreak

struct ActivityEntryTests {
    @Test func initializerSetsAllFields() {
        let id = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let tz = TimeZone(identifier: "America/New_York")!
        let entry = ActivityEntry(id: id, loggedAt: when, timezone: tz, kind: .walk)

        #expect(entry.id == id)
        #expect(entry.loggedAt == when)
        #expect(entry.timezoneIdentifier == "America/New_York")
        #expect(entry.kindRaw == "walk")
    }

    @Test func kindAccessorRoundTripsThroughRawString() {
        let entry = ActivityEntry(
            loggedAt: Date(timeIntervalSince1970: 0),
            timezone: .gmt,
            kind: .workout
        )
        #expect(entry.kind == .workout)
        entry.kind = .other
        #expect(entry.kindRaw == "other")
    }

    @Test func timezoneAccessorRoundTripsThroughIdentifier() {
        let entry = ActivityEntry(
            loggedAt: Date(timeIntervalSince1970: 0),
            timezone: TimeZone(identifier: "Asia/Tokyo")!,
            kind: .workout
        )
        #expect(entry.timezone.identifier == "Asia/Tokyo")
    }
}
```

- [ ] **Step 2: Build to verify the test fails to compile**

Run `BuildProject`.
Expected: build fails with "cannot find 'ActivityEntry' in scope" (and existing `Item` references still compile).

- [ ] **Step 3: Implement `ActivityEntry` and cut over scaffolding**

Create `FitStreak/ActivityEntry.swift`:

```swift
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
```

Replace `FitStreak/FitStreakApp.swift` entirely with:

```swift
// FitStreak/FitStreakApp.swift
import SwiftUI
import SwiftData

@main
struct FitStreakApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ActivityEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

Replace `FitStreak/ContentView.swift` entirely with:

```swift
// FitStreak/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("FitStreak")
    }
}

#Preview {
    ContentView()
}
```

Delete `FitStreak/Item.swift`.

- [ ] **Step 4: Build and run the tests; verify pass**

Run `BuildProject`. Expected: build succeeds.
Run `RunSomeTests` for `FitStreakTests/ActivityEntryTests/initializerSetsAllFields()`, `.../kindAccessorRoundTripsThroughRawString()`, `.../timezoneAccessorRoundTripsThroughIdentifier()`.
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/ActivityEntry.swift FitStreak/FitStreakApp.swift FitStreak/ContentView.swift FitStreakTests/ActivityEntryTests.swift
git rm FitStreak/Item.swift
git commit -m "feat: add ActivityEntry @Model and remove Item placeholder"
```

---

## Task 3: DayKey value type

`DayKey` is a calendar-and-timezone-free `(year, month, day)` triple used as the comparison key in streak math.

**Files:**
- Create: `FitStreak/StreakCalculator.swift` (this file will grow over Tasks 4–16; in this task it contains only `DayKey`)
- Create: `FitStreakTests/DayKeyTests.swift`

- [ ] **Step 1: Write the failing test**

Create `FitStreakTests/DayKeyTests.swift`:

```swift
// FitStreakTests/DayKeyTests.swift
import Testing
@testable import FitStreak

struct DayKeyTests {
    @Test func equalKeysAreEqual() {
        #expect(DayKey(year: 2026, month: 6, day: 15) == DayKey(year: 2026, month: 6, day: 15))
    }

    @Test func differentKeysAreNotEqual() {
        #expect(DayKey(year: 2026, month: 6, day: 15) != DayKey(year: 2026, month: 6, day: 16))
        #expect(DayKey(year: 2026, month: 6, day: 15) != DayKey(year: 2026, month: 7, day: 15))
        #expect(DayKey(year: 2026, month: 6, day: 15) != DayKey(year: 2027, month: 6, day: 15))
    }

    @Test func keysAreHashable() {
        let set: Set<DayKey> = [
            DayKey(year: 2026, month: 6, day: 15),
            DayKey(year: 2026, month: 6, day: 15),
            DayKey(year: 2026, month: 6, day: 16),
        ]
        #expect(set.count == 2)
    }
}
```

- [ ] **Step 2: Build to verify the test fails to compile**

Run `BuildProject`.
Expected: build fails with "cannot find 'DayKey' in scope".

- [ ] **Step 3: Implement `DayKey`**

Create `FitStreak/StreakCalculator.swift`:

```swift
// FitStreak/StreakCalculator.swift
import Foundation

struct DayKey: Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int
}
```

- [ ] **Step 4: Run the tests and verify they pass**

Run `RunSomeTests` for the three `FitStreakTests/DayKeyTests` tests.
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/StreakCalculator.swift FitStreakTests/DayKeyTests.swift
git commit -m "feat: add DayKey value type"
```

---

## Task 4: StreakCalculator skeleton + empty entries returns 0

Establishes the `StreakCalculator` type with injected `calendar` and `now`, and the shared test-support helpers used by every subsequent task.

**Files:**
- Modify: `FitStreak/StreakCalculator.swift` (add `StreakCalculator`)
- Create: `FitStreakTests/StreakTestSupport.swift`
- Create: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the failing test and test helpers**

Create `FitStreakTests/StreakTestSupport.swift`:

```swift
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
                      kind: ActivityKind = .workout) -> ActivityEntry {
        ActivityEntry(
            loggedAt: date(string, in: timezone),
            timezone: TimeZone(identifier: timezone) ?? .gmt,
            kind: kind
        )
    }
}
```

Create `FitStreakTests/StreakCalculatorTests.swift`:

```swift
// FitStreakTests/StreakCalculatorTests.swift
import Foundation
import Testing
@testable import FitStreak

struct StreakCalculatorTests {
    @Test func emptyEntriesReturnsZero() {
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: "America/New_York"),
            now: StreakTestSupport.date("2026-06-15 12:00", in: "America/New_York")
        )
        #expect(calculator.currentStreak(from: []) == 0)
    }
}
```

- [ ] **Step 2: Build to verify the test fails to compile**

Run `BuildProject`.
Expected: build fails with "cannot find 'StreakCalculator' in scope".

- [ ] **Step 3: Implement skeleton**

Modify `FitStreak/StreakCalculator.swift` — append below `DayKey`:

```swift
struct StreakCalculator {
    let calendar: Calendar
    let now: Date

    func currentStreak(from entries: [ActivityEntry]) -> Int {
        return 0
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/emptyEntriesReturnsZero()`.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/StreakCalculator.swift FitStreakTests/StreakTestSupport.swift FitStreakTests/StreakCalculatorTests.swift
git commit -m "feat: add StreakCalculator skeleton; empty entries return 0"
```

---

## Task 5: loggedDayKey(for:) uses the entry's stored timezone

Tests the `loggedDayKey(for:)` helper directly. This freezes an entry's calendar day in its origin timezone, independently of the calculator's calendar.

**Files:**
- Modify: `FitStreak/StreakCalculator.swift` (add method)
- Modify: `FitStreakTests/StreakCalculatorTests.swift` (add test)

- [ ] **Step 1: Write the failing test**

Append inside `struct StreakCalculatorTests { ... }`:

```swift
    @Test func loggedDayKeyUsesEntryTimezone() {
        // Calculator is in Tokyo, entry was logged at 11pm NY time.
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: "Asia/Tokyo"),
            now: StreakTestSupport.date("2026-06-15 12:00", in: "Asia/Tokyo")
        )
        let entry = StreakTestSupport.entry(at: "2026-06-10 23:00", in: "America/New_York")
        // 11pm NY on Jun 10 is 12pm Tokyo on Jun 11. Entry's day must remain Jun 10.
        #expect(calculator.loggedDayKey(for: entry) == DayKey(year: 2026, month: 6, day: 10))
    }
```

- [ ] **Step 2: Build to verify the test fails to compile**

Run `BuildProject`.
Expected: build fails with "value of type 'StreakCalculator' has no member 'loggedDayKey'".

- [ ] **Step 3: Implement `loggedDayKey(for:)`**

Inside `struct StreakCalculator { ... }`, add:

```swift
    func loggedDayKey(for entry: ActivityEntry) -> DayKey {
        var entryCalendar = Calendar(identifier: .gregorian)
        entryCalendar.timeZone = entry.timezone
        let comps = entryCalendar.dateComponents([.year, .month, .day], from: entry.loggedAt)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }
```

(Force-unwraps are acceptable here — `.year`, `.month`, `.day` are always populated when requested via `dateComponents(_:from:)`.)

- [ ] **Step 4: Run the test and verify it passes**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/loggedDayKeyUsesEntryTimezone()`.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/StreakCalculator.swift FitStreakTests/StreakCalculatorTests.swift
git commit -m "feat: derive loggedDayKey from entry's stored timezone"
```

---

## Task 6: One entry today → streak of 1

Drives the first real implementation of `currentStreak`. After this task, a single-day walk works.

**Files:**
- Modify: `FitStreak/StreakCalculator.swift`
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the failing test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func singleEntryTodayReturnsOne() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-15 20:00", in: tz)   // Mon
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz)]
        #expect(calculator.currentStreak(from: entries) == 1)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/singleEntryTodayReturnsOne()`.
Expected: FAIL ("expected 1, got 0").

- [ ] **Step 3: Implement minimal day-walk**

Replace the body of `currentStreak(from:)` in `FitStreak/StreakCalculator.swift`:

```swift
    func currentStreak(from entries: [ActivityEntry]) -> Int {
        let loggedDays = Set(entries.map { loggedDayKey(for: $0) })
        let todayKey = dayKey(of: calendar.startOfDay(for: now))
        return loggedDays.contains(todayKey) ? 1 : 0
    }

    private func dayKey(of date: Date) -> DayKey {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run `RunSomeTests` for the test above.
Expected: PASS. Also re-run the previous calculator tests (`emptyEntriesReturnsZero`, `loggedDayKeyUsesEntryTimezone`) — both still PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/StreakCalculator.swift FitStreakTests/StreakCalculatorTests.swift
git commit -m "feat: detect today's entry as streak of 1"
```

---

## Task 7: Consecutive Mon–Fri logs → streak of 5

Drives the full backward walk (no weekend skip logic yet — five weekdays in a row don't exercise weekends).

**Files:**
- Modify: `FitStreak/StreakCalculator.swift`
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the failing test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func consecutiveWeekdaysReturnFive() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-19 20:00", in: tz)   // Fri
        )
        let entries = [
            StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz),  // Mon
            StreakTestSupport.entry(at: "2026-06-16 09:00", in: tz),  // Tue
            StreakTestSupport.entry(at: "2026-06-17 09:00", in: tz),  // Wed
            StreakTestSupport.entry(at: "2026-06-18 09:00", in: tz),  // Thu
            StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz),  // Fri
        ]
        #expect(calculator.currentStreak(from: entries) == 5)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/consecutiveWeekdaysReturnFive()`.
Expected: FAIL ("expected 5, got 1").

- [ ] **Step 3: Implement backward walk**

Replace `currentStreak(from:)` in `FitStreak/StreakCalculator.swift`:

```swift
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
```

- [ ] **Step 4: Run test to verify it passes**

Run `RunSomeTests` for the test above and the prior calculator tests.
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/StreakCalculator.swift FitStreakTests/StreakCalculatorTests.swift
git commit -m "feat: walk backward for consecutive logged days"
```

---

## Task 8: Weekday miss breaks the streak (regression-guard test)

Today is the next Tuesday after a Friday log. Monday was a weekday with no log → expected streak is 0. The Task 7 impl already produces 0 here (the simple `while` loop exits as soon as today isn't logged), so this test passes on the current impl. It's recorded now as a regression guard that will keep producing 0 after the algorithm grows in Task 9.

**Files:**
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func weekdayMissBreaksStreak() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-23 20:00", in: tz)   // Tue (next week)
        )
        // Logged the prior Friday; nothing since. Mon was a weekday with no log.
        let entries = [StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz)]
        #expect(calculator.currentStreak(from: entries) == 0)
    }
```

- [ ] **Step 2: Run test**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/weekdayMissBreaksStreak()`.
Expected: PASS. The test will continue passing after Task 9 introduces the weekend-skip branch because today (Tue) is unlogged → pending, Mon is an unlogged weekday → break.

- [ ] **Step 3-4: (No impl needed.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/StreakCalculatorTests.swift
git commit -m "test: weekday miss after a Friday log returns 0"
```

---

## Task 9: Weekend skip — logged Fri, today is the following Mon (no Mon log)

This forces the implementation to grow weekend-skip logic. Walking back from Mon: Mon is today and unlogged, Sun is weekend-no-log (skip), Sat is weekend-no-log (skip), Fri is logged → count 1.

**Files:**
- Modify: `FitStreak/StreakCalculator.swift`
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the failing test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func weekendIsFreeWhenWeekdayBeforeWasLogged() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-22 09:00", in: tz)   // Mon, no log yet
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz)]   // Fri
        #expect(calculator.currentStreak(from: entries) == 1)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/weekendIsFreeWhenWeekdayBeforeWasLogged()`.
Expected: FAIL ("expected 1, got 0") — current loop exits as soon as today is unlogged.

- [ ] **Step 3: Implement weekend-skip + today-pending logic**

Replace `currentStreak(from:)` with the full algorithm:

```swift
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
```

(The loop terminates at the first unlogged weekday — no further upper bound needed.)

- [ ] **Step 4: Run all calculator tests**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests` (whole suite).
Expected: all PASS, including `weekdayMissBreaksStreak()` (now testing the loop's break branch deliberately).

- [ ] **Step 5: Commit**

```bash
git add FitStreak/StreakCalculator.swift FitStreakTests/StreakCalculatorTests.swift
git commit -m "feat: weekend miss is free; today-not-logged is pending"
```

---

## Task 10: Weekend logs extend the streak count

`M–F + Sat + Sun + Mon` = 8. Verifies the algorithm increments on weekend logs without special-casing.

**Files:**
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the failing test (expected to pass — verification only)**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func weekendLogsExtendCount() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-22 20:00", in: tz)   // Mon
        )
        let entries = [
            "2026-06-15", "2026-06-16", "2026-06-17", "2026-06-18", "2026-06-19", // Mon-Fri
            "2026-06-20", "2026-06-21",                                            // Sat-Sun
            "2026-06-22",                                                          // Mon
        ].map { StreakTestSupport.entry(at: "\($0) 09:00", in: tz) }
        #expect(calculator.currentStreak(from: entries) == 8)
    }
```

- [ ] **Step 2: Run test**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/weekendLogsExtendCount()`.
Expected: PASS (the algorithm already supports this — this is a regression-guard test, not a TDD red-step).

- [ ] **Step 3: (No impl needed.)**

- [ ] **Step 4: (Already verified in Step 2.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/StreakCalculatorTests.swift
git commit -m "test: weekend logs contribute to streak count"
```

---

## Task 11: Today-pending on a weekday with yesterday logged

Today is Tuesday 9am, no log yet. Yesterday (Mon) was logged. Expected: 1.

**Files:**
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the (regression-guard) test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func todayUnloggedYesterdayWeekdayLogged() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-16 09:00", in: tz)   // Tue, no log yet
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz)] // Mon
        #expect(calculator.currentStreak(from: entries) == 1)
    }
```

- [ ] **Step 2: Run test**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/todayUnloggedYesterdayWeekdayLogged()`.
Expected: PASS (algorithm already supports this).

- [ ] **Step 3-4: (No impl needed.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/StreakCalculatorTests.swift
git commit -m "test: today-pending on weekday with prior log"
```

---

## Task 12: Today-pending on a Saturday with Friday logged

Today is Saturday morning, no log yet. Friday was logged. Expected: 1 (first-day pending applies regardless of weekday/weekend).

**Files:**
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func todayUnloggedSaturdayFridayLogged() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-20 09:00", in: tz)   // Sat, no log yet
        )
        let entries = [StreakTestSupport.entry(at: "2026-06-19 09:00", in: tz)] // Fri
        #expect(calculator.currentStreak(from: entries) == 1)
    }
```

- [ ] **Step 2: Run test**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/todayUnloggedSaturdayFridayLogged()`.
Expected: PASS.

- [ ] **Step 3-4: (No impl needed.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/StreakCalculatorTests.swift
git commit -m "test: today-pending works on weekend days too"
```

---

## Task 13: Duplicate entries on the same day count once

Two entries on the same Monday → streak of 1.

**Files:**
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func duplicateSameDayEntriesCountOnce() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-15 22:00", in: tz)   // Mon
        )
        let entries = [
            StreakTestSupport.entry(at: "2026-06-15 09:00", in: tz),
            StreakTestSupport.entry(at: "2026-06-15 18:00", in: tz),
        ]
        #expect(calculator.currentStreak(from: entries) == 1)
    }
```

- [ ] **Step 2: Run test**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/duplicateSameDayEntriesCountOnce()`.
Expected: PASS (`Set<DayKey>` collapses duplicates).

- [ ] **Step 3-4: (No impl needed.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/StreakCalculatorTests.swift
git commit -m "test: same-day duplicate entries collapse to one day"
```

---

## Task 14: DST spring-forward and leap day handled by Calendar

In `America/New_York`, March 8, 2026 is the spring-forward day (one 23-hour calendar day). Feb 29, 2024 was a leap day. Both must walk as one calendar day each.

**Files:**
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the tests**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func walksCorrectlyAcrossSpringForwardDST() {
        let tz = "America/New_York"
        // Mar 9, 2026 is Monday (the day after spring-forward Sun Mar 8).
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-03-09 20:00", in: tz)
        )
        let entries = [
            StreakTestSupport.entry(at: "2026-03-06 09:00", in: tz),  // Fri
            StreakTestSupport.entry(at: "2026-03-07 09:00", in: tz),  // Sat
            StreakTestSupport.entry(at: "2026-03-08 09:00", in: tz),  // Sun (DST day)
            StreakTestSupport.entry(at: "2026-03-09 09:00", in: tz),  // Mon
        ]
        #expect(calculator.currentStreak(from: entries) == 4)
    }

    @Test func walksCorrectlyAcrossLeapDay() {
        let tz = "America/New_York"
        // Feb 29, 2024 was a leap day. Mar 1 2024 was a Friday.
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2024-03-01 20:00", in: tz)
        )
        let entries = [
            StreakTestSupport.entry(at: "2024-02-28 09:00", in: tz),  // Wed
            StreakTestSupport.entry(at: "2024-02-29 09:00", in: tz),  // Leap Thu
            StreakTestSupport.entry(at: "2024-03-01 09:00", in: tz),  // Fri
        ]
        #expect(calculator.currentStreak(from: entries) == 3)
    }
```

- [ ] **Step 2: Run tests**

Run `RunSomeTests` for both new tests.
Expected: PASS — `Calendar.date(byAdding: .day, value: -1, ...)` handles DST and leap days transparently.

- [ ] **Step 3-4: (No impl needed.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/StreakCalculatorTests.swift
git commit -m "test: streak walks correctly across DST and leap day"
```

---

## Task 15: Entry timezone differs from device timezone — entry's day stays frozen

The calculator runs in Tokyo. The entry was logged at 11pm NY time. Spec says the entry's day is permanently the NY date (Jun 10). From Tokyo's vantage on Jun 11 noon, walking back, Jun 10 must register as logged.

**Files:**
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func entryTimezoneIsRespectedDuringStreakWalk() {
        let entry = StreakTestSupport.entry(at: "2026-06-10 23:00", in: "America/New_York")
        // Tokyo's "now" is 2026-06-11 16:00 (just after the NY 11pm = Tokyo 12pm logged moment).
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: "Asia/Tokyo"),
            now: StreakTestSupport.date("2026-06-11 16:00", in: "Asia/Tokyo")
        )
        // Today (Jun 11 Tokyo) has no log → pending; Jun 10 (NY) is logged → count 1.
        #expect(calculator.currentStreak(from: [entry]) == 1)
    }
```

- [ ] **Step 2: Run test**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/entryTimezoneIsRespectedDuringStreakWalk()`.
Expected: PASS — `loggedDayKey(for:)` uses the entry's stored tz, and DayKey comparison is purely (y, m, d).

- [ ] **Step 3-4: (No impl needed.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/StreakCalculatorTests.swift
git commit -m "test: cross-timezone entry retains its origin day"
```

---

## Task 16: canBackfill — today, yesterday, 3 days ago, tomorrow

Adds the retroactive-window method.

**Files:**
- Modify: `FitStreak/StreakCalculator.swift`
- Modify: `FitStreakTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write the failing test**

Append inside `struct StreakCalculatorTests`:

```swift
    @Test func canBackfillWithinFortyEightHourWindow() {
        let tz = "America/New_York"
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-15 10:00", in: tz)   // Mon 10am
        )
        // End-of-day for each target (in NY), relative to Mon 10am:
        // Mon  end = Tue 00:00 (+14h)   → diff = -14h  ≤ 48h → true
        // Sun  end = Mon 00:00 (-10h)   → diff =  10h  ≤ 48h → true
        // Sat  end = Sun 00:00 (-34h)   → diff =  34h  ≤ 48h → true
        // Fri  end = Sat 00:00 (-58h)   → diff =  58h  > 48h → false
        // Tue  end = Wed 00:00 (+38h)   → diff = -38h, but explicit future guard → false
        #expect(calculator.canBackfill(targetDay: DayKey(year: 2026, month: 6, day: 15)))  // today
        #expect(calculator.canBackfill(targetDay: DayKey(year: 2026, month: 6, day: 14)))  // yesterday
        #expect(calculator.canBackfill(targetDay: DayKey(year: 2026, month: 6, day: 13)))  // sat (34h ago end-of-day)
        #expect(!calculator.canBackfill(targetDay: DayKey(year: 2026, month: 6, day: 12))) // fri (58h)
        #expect(!calculator.canBackfill(targetDay: DayKey(year: 2026, month: 6, day: 16))) // tomorrow
    }
```

- [ ] **Step 2: Build to verify the test fails to compile**

Run `BuildProject`.
Expected: build fails — `canBackfill(targetDay:)` doesn't exist.

- [ ] **Step 3: Implement `canBackfill(targetDay:)`**

Inside `struct StreakCalculator { ... }`, add:

```swift
    func canBackfill(targetDay: DayKey) -> Bool {
        var components = DateComponents()
        components.year = targetDay.year
        components.month = targetDay.month
        components.day = targetDay.day
        guard let dayStart = calendar.date(from: components) else { return false }
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return false }

        // Reject days that haven't ended yet AND start after today's start-of-day.
        let todayStart = calendar.startOfDay(for: now)
        if dayStart > todayStart {
            return false   // strictly future day
        }

        let secondsSinceDayEnd = now.timeIntervalSince(dayEnd)
        return secondsSinceDayEnd <= 48 * 3600
    }
```

- [ ] **Step 4: Run test and verify it passes**

Run `RunSomeTests` for `FitStreakTests/StreakCalculatorTests/canBackfillWithinFortyEightHourWindow()`.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add FitStreak/StreakCalculator.swift FitStreakTests/StreakCalculatorTests.swift
git commit -m "feat: canBackfill within 48h of day-end; rejects future days"
```

---

## Task 17: Layer B — ActivityEntry persistence round-trip

Verifies that `ActivityEntry` survives `ModelContainer` insert/fetch/delete via in-memory storage.

**Files:**
- Create: `FitStreakTests/ActivityEntryPersistenceTests.swift`

- [ ] **Step 1: Write the failing test**

Create `FitStreakTests/ActivityEntryPersistenceTests.swift`:

```swift
// FitStreakTests/ActivityEntryPersistenceTests.swift
import Foundation
import SwiftData
import Testing
@testable import FitStreak

@MainActor
struct ActivityEntryPersistenceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ActivityEntry.self, configurations: config)
    }

    @Test func insertedEntryRoundTripsAllFields() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let id = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = ActivityEntry(
            id: id,
            loggedAt: when,
            timezone: TimeZone(identifier: "America/New_York")!,
            kind: .walk
        )
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ActivityEntry>())
        #expect(fetched.count == 1)
        let first = try #require(fetched.first)
        #expect(first.id == id)
        #expect(first.loggedAt == when)
        #expect(first.timezoneIdentifier == "America/New_York")
        #expect(first.kind == .walk)
        #expect(first.timezone.identifier == "America/New_York")
    }

    @Test func deletingEntryRemovesItFromFetchResults() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let entry = ActivityEntry(
            loggedAt: Date(timeIntervalSince1970: 0),
            timezone: .gmt,
            kind: .other
        )
        context.insert(entry)
        try context.save()

        context.delete(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ActivityEntry>())
        #expect(fetched.isEmpty)
    }
}
```

- [ ] **Step 2: Build and run tests; verify pass**

Run `BuildProject`. Expected: success.
Run `RunSomeTests` for both `FitStreakTests/ActivityEntryPersistenceTests` tests.
Expected: PASS.

- [ ] **Step 3: (No new impl — model exists from Task 2.)**

- [ ] **Step 4: (Already verified in Step 2.)**

- [ ] **Step 5: Commit**

```bash
git add FitStreakTests/ActivityEntryPersistenceTests.swift
git commit -m "test: ActivityEntry round-trips through in-memory ModelContainer"
```

---

## Task 18: Layer C — integration end-to-end

Inserts entries through a `ModelContext`, fetches them, hands them to `StreakCalculator`, asserts the streak.

**Files:**
- Create: `FitStreakTests/StreakIntegrationTests.swift`

- [ ] **Step 1: Write the failing test**

Create `FitStreakTests/StreakIntegrationTests.swift`:

```swift
// FitStreakTests/StreakIntegrationTests.swift
import Foundation
import SwiftData
import Testing
@testable import FitStreak

@MainActor
struct StreakIntegrationTests {
    @Test func fetchedEntriesProduceCorrectStreak() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ActivityEntry.self, configurations: config)
        let context = container.mainContext

        let tz = "America/New_York"
        let zone = TimeZone(identifier: tz)!
        let dates = [
            "2026-06-15 09:00",  // Mon
            "2026-06-16 09:00",  // Tue
            "2026-06-17 09:00",  // Wed
        ]
        for s in dates {
            context.insert(ActivityEntry(
                loggedAt: StreakTestSupport.date(s, in: tz),
                timezone: zone,
                kind: .workout
            ))
        }
        try context.save()

        let entries = try context.fetch(FetchDescriptor<ActivityEntry>())
        let calculator = StreakCalculator(
            calendar: StreakTestSupport.calendar(timezone: tz),
            now: StreakTestSupport.date("2026-06-17 20:00", in: tz)  // Wed eve
        )
        #expect(calculator.currentStreak(from: entries) == 3)
    }
}
```

- [ ] **Step 2: Build and run; verify pass**

Run `BuildProject`. Expected: success.
Run `RunSomeTests` for `FitStreakTests/StreakIntegrationTests/fetchedEntriesProduceCorrectStreak()`.
Expected: PASS.

- [ ] **Step 3: (No new impl.)**

- [ ] **Step 4: (Already verified in Step 2.)**

- [ ] **Step 5: Run full test suite as a final verification**

Run `RunAllTests`.
Expected: every test under `FitStreakTests` PASSES. Capture the count for the commit message.

- [ ] **Step 6: Commit**

```bash
git add FitStreakTests/StreakIntegrationTests.swift
git commit -m "test: end-to-end streak calculation via ModelContainer"
```

---

## Done criteria

- `BuildProject` succeeds with no warnings introduced by this work.
- `RunAllTests` shows every test under `FitStreakTests` PASSING.
- Streak math is fully derived (no `streakLength` field anywhere).
- `Item.swift` is gone; `ActivityEntry` is the only persisted model.
- ContentView is a one-line placeholder — no UI built in this work.
- All commits follow the Conventional Commits pattern used throughout.

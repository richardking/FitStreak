// FitStreak/HomeView.swift
import SwiftUI
import SwiftData

// MARK: - View-layer model
//
// `LogCardModel` (the catalog of activities shown in the grid) lives in
// `Shared/` so the widget can reuse the same source of truth.

private enum Palette {
    static let accent     = Color(red: 0.78, green: 0.96, blue: 0.32)
    static let background = Color.black
    static let cardFill   = Color.white.opacity(0.04)
    static let iconWell   = Color.white.opacity(0.06)
}

// MARK: - Home

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityEntry.loggedAt) private var entries: [ActivityEntry]
    @State private var selectedDay: DayKey?

    var body: some View {
        let calculator = StreakCalculator(calendar: .current, now: .now)
        let derived = Derived(entries: entries)

        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                StreakHero(current: derived.current, hasLoggedToday: derived.hasLoggedToday)
                StatsRow(best: derived.best, total: derived.total)
                LogTodaySection(
                    todayCounts: derived.todayCounts,
                    onTap: toggleActivity,
                    onLogAgain: addActivity,
                    onRemoveLast: removeOneActivity
                )
                HistorySection(history: derived.history, calculator: calculator) { day in
                    selectedDay = day
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Palette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(day: day)
                .presentationDetents([.medium, .large])
        }
    }

    private func toggleActivity(_ kind: ActivityKind) {
        _ = try? ActivityLogger.toggleTodaysEntry(of: kind, in: modelContext)
    }

    private func addActivity(_ kind: ActivityKind) {
        _ = try? ActivityLogger.addEntry(of: kind, onDay: todayKey, in: modelContext)
    }

    private func removeOneActivity(_ kind: ActivityKind) {
        _ = try? ActivityLogger.removeOneEntry(of: kind, onDay: todayKey, in: modelContext)
    }

    private var todayKey: DayKey {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }
}

// MARK: - Derivation
//
// Everything the screen displays is a pure function of the queried entries.
// Streak counts go through `StreakCalculator` (tested). Heatmap intensity is
// just the per-day entry count, clamped — a presentation detail.

private struct Derived {
    let current: Int
    let best: Int
    let total: Int
    let todayCounts: [ActivityKind: Int]
    let history: [Date: Int]

    var loggedToday: Set<ActivityKind> { Set(todayCounts.keys) }
    var hasLoggedToday: Bool { !todayCounts.isEmpty }

    init(entries: [ActivityEntry]) {
        let calendar = Calendar.current
        let now = Date.now
        let calculator = StreakCalculator(calendar: calendar, now: now)

        self.current = calculator.currentStreak(from: entries)
        self.best = calculator.longestStreak(from: entries)

        let allDayKeys = Set(entries.map { calculator.loggedDayKey(for: $0) })
        self.total = allDayKeys.count

        let todayKey = Self.dayKey(of: now, in: calendar)
        var todayCounts: [ActivityKind: Int] = [:]
        for entry in entries where calculator.loggedDayKey(for: entry) == todayKey {
            todayCounts[entry.kind, default: 0] += 1
        }
        self.todayCounts = todayCounts

        var counts: [DayKey: Int] = [:]
        for entry in entries {
            counts[calculator.loggedDayKey(for: entry), default: 0] += 1
        }
        var history: [Date: Int] = [:]
        for (key, count) in counts {
            var comps = DateComponents()
            comps.year = key.year
            comps.month = key.month
            comps.day = key.day
            if let date = calendar.date(from: comps) {
                history[calendar.startOfDay(for: date)] = min(4, count)
            }
        }
        self.history = history
    }

    private static func dayKey(of date: Date, in calendar: Calendar) -> DayKey {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
    }
}

// MARK: - Hero

private struct StreakHero: View {
    let current: Int
    let hasLoggedToday: Bool

    private var subtitle: String {
        hasLoggedToday ? "Logged today \u{2713}" : "Log today to continue"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel("CURRENT STREAK")

            HStack(alignment: .top, spacing: 14) {
                StreakNumberChip(number: current, filled: hasLoggedToday)
                VStack(alignment: .leading, spacing: 4) {
                    Text("days")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)
                Spacer(minLength: 0)
            }
        }
    }
}

private struct StreakNumberChip: View {
    let number: Int
    let filled: Bool

    var body: some View {
        Text("\(number)")
            .font(.system(size: 52, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(filled ? Color.black : Palette.accent)
            .frame(minWidth: 64, minHeight: 64)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(filled ? Palette.accent : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Palette.accent, lineWidth: filled ? 0 : 2)
                    )
            )
            .accessibilityLabel("\(number) day streak")
    }
}

// MARK: - Stats

private struct StatsRow: View {
    let best: Int
    let total: Int

    var body: some View {
        HStack(spacing: 20) {
            StatItem(symbol: "flame.fill", label: "Best", value: "\(best)d")
            StatItem(symbol: "checkmark",  label: "Total", value: "\(total)d")
            Spacer(minLength: 0)
        }
    }
}

private struct StatItem: View {
    let symbol: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
            Text(label + ":")
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .font(.footnote)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Log Today grid

private struct LogTodaySection: View {
    let todayCounts: [ActivityKind: Int]
    let onTap: (ActivityKind) -> Void
    let onLogAgain: (ActivityKind) -> Void
    let onRemoveLast: (ActivityKind) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("LOG TODAY")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(LogCardModel.all) { card in
                    ActivityCard(
                        card: card,
                        count: todayCounts[card.kind] ?? 0,
                        onTap: { onTap(card.kind) },
                        onLogAgain: { onLogAgain(card.kind) },
                        onRemoveLast: { onRemoveLast(card.kind) }
                    )
                }
            }
        }
    }
}

private struct ActivityCard: View {
    let card: LogCardModel
    let count: Int
    let onTap: () -> Void
    let onLogAgain: () -> Void
    let onRemoveLast: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 36) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(Palette.iconWell)
                            .frame(width: 36, height: 36)
                        Image(systemName: card.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    CountBadge(count: count)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(card.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.cardFill)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onLogAgain) {
                Label("Log again", systemImage: "plus")
            }
            Button(role: .destructive, action: onRemoveLast) {
                Label("Remove last log", systemImage: "minus")
            }
            .disabled(count == 0)
        }
        .accessibilityLabel(card.title)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityHint: String {
        switch count {
        case 0: return "Tap to log. Long-press for more options."
        case 1: return "Logged today. Tap to remove. Long-press for more options."
        default: return "Logged \(count) times today. Tap to remove all. Long-press for more options."
        }
    }
}

/// Badge in the top-right corner of an activity card. Source of truth for
/// how count states present visually. Self-contained accent color so this
/// view can be used from any file without leaking `Palette`.
struct CountBadge: View {
    let count: Int

    private static let accent = Color(red: 0.78, green: 0.96, blue: 0.32)

    var body: some View {
        switch count {
        case 0:
            EmptyView()
        case 1:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Self.accent)
        default:
            Text(displayText)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Self.accent))
                .accessibilityLabel("Logged \(count) times")
        }
    }

    private var displayText: String {
        // 5+× cap per design; hopefully unused.
        count >= 6 ? "5+×" : "\(count)×"
    }
}

// MARK: - History (year heatmap)

private struct HistorySection: View {
    let history: [Date: Int]
    let calculator: StreakCalculator
    let onTapDay: (DayKey) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("HISTORY")
            YearHeatmap(history: history, calculator: calculator, onTapDay: onTapDay)
            HeatmapLegend()
        }
    }
}

private struct YearHeatmap: View {
    let history: [Date: Int]
    let calculator: StreakCalculator
    let onTapDay: (DayKey) -> Void

    private let cell: CGFloat = 18
    private let cellSpacing: CGFloat = 5

    private var weeks: [HeatmapWeek] {
        HeatmapBuilder.buildYear(endingOn: .now, history: history, calculator: calculator)
    }

    var body: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            dayLabelColumn
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(weeks) { week in
                            weekColumn(week)
                                .id(week.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onAppear {
                    if let last = weeks.last {
                        proxy.scrollTo(last.id, anchor: .trailing)
                    }
                }
            }
        }
    }

    private func weekColumn(_ week: HeatmapWeek) -> some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            MonthLabel(text: week.monthLabel)
            ForEach(0..<7, id: \.self) { row in
                if let day = week.days[row] {
                    HeatmapCell(
                        intensity: day.intensity,
                        isToday: day.isToday,
                        isEditable: day.isEditable,
                        onTap: { onTapDay(day.dayKey) }
                    )
                    .frame(width: cell, height: cell)
                } else {
                    Color.clear.frame(width: cell, height: cell)
                }
            }
        }
    }

    private var dayLabelColumn: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            MonthLabel(text: " ")
            ForEach(0..<7, id: \.self) { row in
                Text(["M", "T", "W", "T", "F", "S", "S"][row])
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(row % 2 == 0 ? Color.secondary : Color.clear)
                    .frame(width: 12, height: cell, alignment: .leading)
            }
        }
        .padding(.trailing, 2)
    }
}

private struct MonthLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(height: 12, alignment: .leading)
    }
}

private struct HeatmapCell: View {
    let intensity: Int   // 0...4
    let isToday: Bool
    let isEditable: Bool
    let onTap: () -> Void

    private static let editableStroke = Color.white.opacity(0.40)

    private var fill: Color {
        switch intensity {
        case 0: return Palette.iconWell
        case 1: return Palette.accent.opacity(0.30)
        case 2: return Palette.accent.opacity(0.55)
        case 3: return Palette.accent.opacity(0.80)
        default: return Palette.accent
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        let cellBody = ZStack {
            if isToday && intensity == 0 {
                shape.strokeBorder(Palette.accent, lineWidth: 1.5)
            } else {
                shape.fill(fill)
                if isToday {
                    shape.strokeBorder(Palette.accent, lineWidth: 1.5)
                } else if isEditable {
                    shape.strokeBorder(Self.editableStroke, lineWidth: 1.2)
                }
            }
        }

        // Today is non-interactive — the main screen is the canonical surface
        // for logging today. Today still claims its own hit area + a no-op
        // gesture, otherwise a neighboring cell's extended hit area would
        // win the tap inside today's visual region.
        //
        // Non-today cells extend their hit area only slightly (-2pt). The 5pt
        // inter-cell gap absorbs the full extension on both sides without any
        // gesture spilling into the next cell.
        if isToday {
            cellBody
                .contentShape(Rectangle())
                .onTapGesture { /* swallow taps on today */ }
        } else {
            cellBody
                .contentShape(Rectangle().inset(by: -2))
                .onTapGesture(perform: onTap)
        }
    }
}

private struct HeatmapLegend: View {
    var body: some View {
        HStack(spacing: 4) {
            Spacer(minLength: 0)
            Text("less")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.trailing, 2)
            ForEach(legendSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(legendColor(step))
                    .frame(width: 10, height: 10)
            }
            Text("more")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.leading, 2)
        }
    }

    private var legendSteps: [Int] { [0, 1, 2, 3, 4] }

    private func legendColor(_ step: Int) -> Color {
        switch step {
        case 0: return Palette.iconWell
        case 1: return Palette.accent.opacity(0.30)
        case 2: return Palette.accent.opacity(0.55)
        case 3: return Palette.accent.opacity(0.80)
        default: return Palette.accent
        }
    }
}

// MARK: - Helpers

private struct SectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Heatmap data

private struct HeatmapDay: Hashable {
    let dayKey: DayKey
    let intensity: Int
    let isToday: Bool
    let isEditable: Bool
}

private struct HeatmapWeek: Identifiable {
    let id: Int
    let days: [HeatmapDay?]   // 7 entries, Mon..Sun; nil for future days
    let monthLabel: String    // non-empty when the week introduces a new month
}

private enum HeatmapBuilder {
    static func buildYear(endingOn endDate: Date, history: [Date: Int], calculator: StreakCalculator) -> [HeatmapWeek] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        let today = calendar.startOfDay(for: endDate)
        let weekday = calendar.component(.weekday, from: today) // Sun=1...Sat=7
        let mondayOffset = (weekday + 5) % 7 // Mon→0, Sun→6
        guard let mondayThisWeek = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return []
        }

        let weeksBack = 52
        var lastMonthYear = -1
        var result: [HeatmapWeek] = []

        for offset in (0...weeksBack).reversed() {
            guard let weekStart = calendar.date(byAdding: .day, value: -7 * offset, to: mondayThisWeek) else { continue }

            var days: [HeatmapDay?] = []
            for d in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: d, to: weekStart) else { days.append(nil); continue }
                if day > today { days.append(nil); continue }
                let comps = calendar.dateComponents([.year, .month, .day], from: day)
                let dayKey = DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
                let intensity = history[day] ?? 0
                let isToday = calendar.isDate(day, inSameDayAs: today)
                let isEditable = calculator.canBackfill(targetDay: dayKey) && !isToday
                days.append(HeatmapDay(dayKey: dayKey, intensity: intensity, isToday: isToday, isEditable: isEditable))
            }

            let month = calendar.component(.month, from: weekStart)
            let year  = calendar.component(.year,  from: weekStart)
            let key   = year * 100 + month

            var label = ""
            if key != lastMonthYear {
                label = monthFormatter.string(from: weekStart)
                lastMonthYear = key
            }

            result.append(HeatmapWeek(id: weeksBack - offset, days: days, monthLabel: label))
        }
        return result
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()
}

// MARK: - Previews
//
// Each preview spins up an in-memory ModelContainer and seeds it for its state.
// HomeView then reads the seeded entries via @Query just like in production.

@MainActor
private func previewContainer(_ seed: (ModelContext) -> Void = { _ in }) -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        let container = try ModelContainer(for: ActivityEntry.self, configurations: config)
        seed(container.mainContext)
        try container.mainContext.save()
        return container
    } catch {
        fatalError("Preview container failed: \(error)")
    }
}

private func seedActiveStreak(into context: ModelContext, includingToday: Bool) {
    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)

    if includingToday {
        context.insert(ActivityEntry(loggedAt: .now, timezone: .current, kind: .running))
    }
    // Current 6-day streak ending yesterday — varying counts per day for heatmap intensity.
    for i in 1...6 {
        guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
        let count = [3, 2, 4, 3, 2, 4][i - 1]
        for _ in 0..<count {
            context.insert(ActivityEntry(loggedAt: d, timezone: .current, kind: .weights))
        }
    }
    // Deterministic historical sprinkle so the heatmap looks lived-in.
    for i in 8...250 {
        guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
        let n = (i * 7 + 3) % 11
        guard n > 5 else { continue }
        let count = (n % 4) + 1
        for _ in 0..<count {
            context.insert(ActivityEntry(loggedAt: d, timezone: .current, kind: .other))
        }
    }
}

private struct PhoneFrame<Content: View>: View {
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .frame(width: 393, height: 852)
            .background(Palette.background)
    }
}

#Preview("Zero streak") {
    PhoneFrame { HomeView() }
        .modelContainer(previewContainer())
}

#Preview("Active 6-day streak") {
    PhoneFrame { HomeView() }
        .modelContainer(previewContainer { seedActiveStreak(into: $0, includingToday: false) })
}

#Preview("Today already logged") {
    PhoneFrame { HomeView() }
        .modelContainer(previewContainer { seedActiveStreak(into: $0, includingToday: true) })
}

#Preview("Multi-log today") {
    PhoneFrame { HomeView() }
        .modelContainer(previewContainer { context in
            seedActiveStreak(into: context, includingToday: false)
            // Log Running 2× and Pickleball 3× today so the badges show.
            context.insert(ActivityEntry(loggedAt: .now, timezone: .current, kind: .running))
            context.insert(ActivityEntry(loggedAt: .now.addingTimeInterval(60), timezone: .current, kind: .running))
            context.insert(ActivityEntry(loggedAt: .now, timezone: .current, kind: .pickleball))
            context.insert(ActivityEntry(loggedAt: .now.addingTimeInterval(60), timezone: .current, kind: .pickleball))
            context.insert(ActivityEntry(loggedAt: .now.addingTimeInterval(120), timezone: .current, kind: .pickleball))
        })
}

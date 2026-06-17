// FitStreakWidget/FitStreakWidget.swift
//
// FitStreak's home-screen widget. A read of the shared SwiftData store via
// FetchDescriptor (NOT @Query — widgets evaluate their bodies on the
// reload timeline, so SwiftUI's reactive querying doesn't fit).
// Each Button hosts LogActivityIntent so iOS runs the intent in-process on tap.

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Timeline entry

struct FitStreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let loggedToday: Set<ActivityKind>
}

// MARK: - Provider

struct FitStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> FitStreakEntry {
        FitStreakEntry(date: .now, currentStreak: 0, loggedToday: [])
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (FitStreakEntry) -> Void) {
        Task { @MainActor in
            completion(Self.makeEntry(at: .now))
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<FitStreakEntry>) -> Void) {
        Task { @MainActor in
            let entry = Self.makeEntry(at: .now)
            // Refresh at the next midnight so the "today" buckets stay current.
            // The intent calls WidgetCenter.reloadAllTimelines() on every tap,
            // so this is only a safety net for the day-rollover case.
            let nextRefresh = Calendar.current.nextDate(
                after: .now,
                matching: DateComponents(hour: 0, minute: 0),
                matchingPolicy: .nextTime
            ) ?? .now.addingTimeInterval(60 * 60 * 6)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    @MainActor
    private static func makeEntry(at date: Date) -> FitStreakEntry {
        let context = ModelContext(SharedModelContainer.shared)
        let entries = (try? context.fetch(FetchDescriptor<ActivityEntry>())) ?? []
        let calendar = Calendar.current
        let calculator = StreakCalculator(calendar: calendar, now: date)
        let currentStreak = calculator.currentStreak(from: entries)
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let todayKey = DayKey(year: comps.year!, month: comps.month!, day: comps.day!)
        let loggedToday = Set(
            entries
                .filter { calculator.loggedDayKey(for: $0) == todayKey }
                .map(\.kind)
        )
        return FitStreakEntry(date: date, currentStreak: currentStreak, loggedToday: loggedToday)
    }
}

// MARK: - Visuals

private enum WidgetPalette {
    static let accent  = Color(red: 0.78, green: 0.96, blue: 0.32)
    static let chip    = Color.white.opacity(0.08)
    static let dim     = Color.white.opacity(0.55)
    static let primary = Color.white
}

private struct StreakChip: View {
    let count: Int
    let logged: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetPalette.accent)
            Text("\(count)")
                .font(.system(.callout, design: .rounded, weight: .heavy))
                .foregroundStyle(WidgetPalette.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(WidgetPalette.chip)
        )
    }
}

private struct ActivityWidgetButton: View {
    let card: LogCardModel
    let isLogged: Bool
    let compact: Bool

    var body: some View {
        Button(intent: LogActivityIntent(kind: card.kind)) {
            VStack(spacing: compact ? 2 : 6) {
                Image(systemName: card.symbol)
                    .font(.system(size: compact ? 16 : 20, weight: .semibold))
                if !compact {
                    Text(card.title)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(isLogged ? Color.black : WidgetPalette.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isLogged ? WidgetPalette.accent : WidgetPalette.chip)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.title)
        .accessibilityHint(isLogged ? "Logged today; tap to unlog" : "Tap to log")
    }
}

// MARK: - Family layouts
//
// Source of truth for the list of buttons is `LogCardModel.all`. Each layout
// just decides how many of those to show.

private struct SmallLayout: View {
    let entry: FitStreakEntry
    var body: some View {
        let cards = LogCardModel.all.prefix(4)
        VStack(alignment: .leading, spacing: 6) {
            StreakChip(count: entry.currentStreak, logged: !entry.loggedToday.isEmpty)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                ForEach(cards) { card in
                    ActivityWidgetButton(card: card,
                                         isLogged: entry.loggedToday.contains(card.kind),
                                         compact: true)
                }
            }
        }
    }
}

private struct MediumLayout: View {
    let entry: FitStreakEntry
    var body: some View {
        let cards = LogCardModel.all
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("STREAK")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.1)
                    .foregroundStyle(WidgetPalette.dim)
                Text("\(entry.currentStreak)")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(WidgetPalette.accent)
                Text(entry.currentStreak == 1 ? "day" : "days")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.dim)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(cards) { card in
                    ActivityWidgetButton(card: card,
                                         isLogged: entry.loggedToday.contains(card.kind),
                                         compact: false)
                }
            }
        }
    }
}

private struct LargeLayout: View {
    let entry: FitStreakEntry
    var body: some View {
        let cards = LogCardModel.all
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("CURRENT STREAK")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.1)
                        .foregroundStyle(WidgetPalette.dim)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(entry.currentStreak)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(WidgetPalette.accent)
                        Text(entry.currentStreak == 1 ? "day" : "days")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(WidgetPalette.primary)
                    }
                }
                Spacer()
            }

            Text(entry.loggedToday.isEmpty ? "Log today to keep it going." : "Logged today \u{2713}")
                .font(.footnote)
                .foregroundStyle(WidgetPalette.dim)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(cards) { card in
                    ActivityWidgetButton(card: card,
                                         isLogged: entry.loggedToday.contains(card.kind),
                                         compact: false)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Entry view + Widget

struct FitStreakEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FitStreakEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallLayout(entry: entry)
        case .systemMedium: MediumLayout(entry: entry)
        case .systemLarge:  LargeLayout(entry: entry)
        default:            SmallLayout(entry: entry)
        }
    }
}

struct FitStreakWidget: Widget {
    let kind: String = "FitStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitStreakProvider()) { entry in
            FitStreakEntryView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("FitStreak")
        .description("Log an activity from the home screen. Updates your streak instantly.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Small — zero", as: .systemSmall) {
    FitStreakWidget()
} timeline: {
    FitStreakEntry(date: .now, currentStreak: 0, loggedToday: [])
}

#Preview("Small — active", as: .systemSmall) {
    FitStreakWidget()
} timeline: {
    FitStreakEntry(date: .now, currentStreak: 4, loggedToday: [.weights])
}

#Preview("Medium — active", as: .systemMedium) {
    FitStreakWidget()
} timeline: {
    FitStreakEntry(date: .now, currentStreak: 7, loggedToday: [.running])
}

#Preview("Large — active", as: .systemLarge) {
    FitStreakWidget()
} timeline: {
    FitStreakEntry(date: .now, currentStreak: 12, loggedToday: [.weights, .pickleball])
}

// FitStreak/DayDetailSheet.swift
//
// Sheet that opens when the user taps a heatmap cell.
//   - Editable (today + 2 days back per canBackfill): 2x2 grid of LOG-TODAY
//     cards. Tap toggles entries on that day via ActivityLogger.
//   - Older: stacked, read-only list of what was logged that day, or empty.

import SwiftUI
import SwiftData

// `.sheet(item:)` needs Identifiable.
extension DayKey: Identifiable {
    public var id: Int { year * 10000 + month * 100 + day }
}

private enum SheetPalette {
    static let accent     = Color(red: 0.78, green: 0.96, blue: 0.32)
    static let cardFill   = Color.white.opacity(0.04)
    static let iconWell   = Color.white.opacity(0.06)
}

struct DayDetailSheet: View {
    let day: DayKey
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [ActivityEntry]

    private var calculator: StreakCalculator {
        StreakCalculator(calendar: .current, now: .now)
    }

    private var isEditable: Bool { calculator.canBackfill(targetDay: day) }

    private var loggedKinds: Set<ActivityKind> {
        Set(allEntries
            .filter { calculator.loggedDayKey(for: $0) == day }
            .map(\.kind))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            if isEditable {
                editableGrid
            } else {
                viewOnlyList
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(titleColor)
        }
    }

    private var eyebrow: String {
        let dayLabel: String
        if isEditable {
            switch dayOffset {
            case 0:  dayLabel = "TODAY"
            case -1: dayLabel = "YESTERDAY"
            default: dayLabel = "\(-dayOffset) DAYS AGO"
            }
        } else {
            dayLabel = absoluteWeekday.uppercased()
        }
        return "\(dayLabel)  ·  \(absoluteShortDate.uppercased())"
    }

    private var title: String {
        if isEditable {
            return loggedKinds.isEmpty ? "Tap to add" : "Tap to add or remove"
        } else {
            switch loggedKinds.count {
            case 0: return "No activity logged"
            case 1: return "1 activity"
            default: return "\(loggedKinds.count) activities"
            }
        }
    }

    private var titleColor: Color {
        !isEditable && loggedKinds.isEmpty ? .secondary : .primary
    }

    // MARK: - Editable: LOG-TODAY style 2x2

    private var editableGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(LogCardModel.all) { card in
                EditableCard(
                    card: card,
                    isLogged: loggedKinds.contains(card.kind),
                    onTap: { toggle(card.kind) }
                )
            }
        }
    }

    private func toggle(_ kind: ActivityKind) {
        _ = try? ActivityLogger.toggleEntry(of: kind, onDay: day, in: modelContext)
    }

    // MARK: - View-only: stacked list or empty

    @ViewBuilder
    private var viewOnlyList: some View {
        if loggedKinds.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 8) {
                ForEach(LogCardModel.all.filter { loggedKinds.contains($0.kind) }) { card in
                    ViewOnlyRow(card: card)
                }
            }
            Text("Older days are read-only.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Date helpers

    private var dayDate: Date {
        var comps = DateComponents()
        comps.year = day.year
        comps.month = day.month
        comps.day = day.day
        return Calendar.current.date(from: comps) ?? .now
    }

    private var dayOffset: Int {
        let cal = Calendar.current
        let now = cal.startOfDay(for: .now)
        let then = cal.startOfDay(for: dayDate)
        return cal.dateComponents([.day], from: now, to: then).day ?? 0
    }

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private var absoluteWeekday: String { Self.weekdayFormatter.string(from: dayDate) }
    private var absoluteShortDate: String { Self.shortDateFormatter.string(from: dayDate) }
}

// MARK: - Subviews

private struct EditableCard: View {
    let card: LogCardModel
    let isLogged: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 36) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle().fill(SheetPalette.iconWell).frame(width: 36, height: 36)
                        Image(systemName: card.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isLogged {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(SheetPalette.accent)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(card.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SheetPalette.cardFill)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.title)
        .accessibilityHint(isLogged ? "Logged; tap to remove" : "Tap to log")
    }
}

private struct ViewOnlyRow: View {
    let card: LogCardModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(SheetPalette.iconWell).frame(width: 36, height: 36)
                Image(systemName: card.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SheetPalette.accent.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(SheetPalette.cardFill)
        )
    }
}

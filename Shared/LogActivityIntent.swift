// Shared/LogActivityIntent.swift
//
// The AppIntent the widget invokes when a user taps an activity button. Runs
// in-process inside the widget extension (openAppWhenRun stays at its default
// false), writes via the shared container, and reloads timelines so the widget
// reflects the new state.

import AppIntents
import SwiftData
import WidgetKit

struct LogActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Activity"
    static var description = IntentDescription("Toggle today's log for the chosen activity.")

    @Parameter(title: "Activity")
    var kind: ActivityKind

    init() {}

    init(kind: ActivityKind) {
        self.kind = kind
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = ModelContext(SharedModelContainer.shared)
        try ActivityLogger.toggleTodaysEntry(of: kind, in: context)
        // ActivityLogger reloads widget timelines itself, so the intent doesn't
        // need a separate call.
        return .result()
    }
}

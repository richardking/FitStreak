// Shared/LogCardModel.swift
//
// The catalog of activity types as they appear on the log surface. Used by the
// home screen grid AND by the widget. Single source of truth so the widget
// can't drift from the app.

import Foundation

struct LogCardModel: Identifiable, Hashable {
    let kind: ActivityKind
    let title: String
    let symbol: String
    var id: ActivityKind { kind }

    static let all: [LogCardModel] = [
        .init(kind: .weights,    title: "Weights",    symbol: "dumbbell.fill"),
        .init(kind: .running,    title: "Running",    symbol: "waveform.path.ecg"),
        .init(kind: .pickleball, title: "Pickleball", symbol: "scope"),
        .init(kind: .other,      title: "Other",      symbol: "bolt.fill"),
    ]
}

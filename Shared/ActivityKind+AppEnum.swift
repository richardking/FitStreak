// Shared/ActivityKind+AppEnum.swift
//
// AppIntents conformance so ActivityKind can be a parameter to LogActivityIntent.
// Lives in a separate file so ActivityKind itself stays AppIntents-free.

import AppIntents

// The project compiles with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so
// without `nonisolated` the protocol witness would be MainActor-isolated,
// which conflicts with AppEnum's Sendable requirement.
extension ActivityKind: AppEnum {
    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Activity")
    }

    // AppIntents requires a literal dictionary so it can be inspected at build
    // time. LogCardModel remains the source of truth for the in-app surface;
    // this mirror gets caught at compile time if a case is missing.
    nonisolated static let caseDisplayRepresentations: [ActivityKind: DisplayRepresentation] = [
        .weights:    DisplayRepresentation(title: "Weights",    image: .init(systemName: "dumbbell.fill")),
        .running:    DisplayRepresentation(title: "Running",    image: .init(systemName: "waveform.path.ecg")),
        .pickleball: DisplayRepresentation(title: "Pickleball", image: .init(systemName: "scope")),
        .other:      DisplayRepresentation(title: "Other",      image: .init(systemName: "bolt.fill")),
    ]
}

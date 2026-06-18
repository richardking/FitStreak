// FitStreak/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    // Bumping this UUID rebuilds HomeView's subtree, which forces @Query to
    // re-fetch. Needed because SwiftData @Query does NOT observe writes from
    // the widget extension process, so cross-process writes only become
    // visible after the app gets a fresh fetch — which we trigger on
    // foreground.
    @State private var refreshToken = UUID()

    var body: some View {
        HomeView()
            .id(refreshToken)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshToken = UUID()
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActivityEntry.self, inMemory: true)
}

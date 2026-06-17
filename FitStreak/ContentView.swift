// FitStreak/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ActivityEntry.self, inMemory: true)
}

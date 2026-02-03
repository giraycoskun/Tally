//
//  MainTabView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            HabitListView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
            
            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

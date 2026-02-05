//
//  MainTabView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    @Environment(\.scenePhase) private var scenePhase
    @State private var refreshId = UUID()
    @State private var dayChangeTimer: Timer?
    
    private var currentTheme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
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
        .id(refreshId)
        .tint(currentTheme.accentColor)
        .onAppear {
            updateTabBarAppearance()
            scheduleDayBoundaryRefresh()
        }
        .onDisappear {
            dayChangeTimer?.invalidate()
            dayChangeTimer = nil
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshId = UUID()
                scheduleDayBoundaryRefresh()
            }
        }
        .onChange(of: selectedThemeRaw) { _, newValue in
            let theme = ThemeColor(rawValue: newValue) ?? .purple
            updateTabBarAppearance(for: theme)
            refreshId = UUID()
        }
        .onChange(of: daySwitchHour) { _, _ in
            // Delay refresh slightly to ensure UserDefaults is fully synchronized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refreshId = UUID()
            }
            scheduleDayBoundaryRefresh()
        }
    }
    
    private func updateTabBarAppearance(for theme: ThemeColor? = nil) {
        let theme = theme ?? currentTheme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.darkColor)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(theme.lightColor)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(theme.lightColor)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.accentColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(theme.accentColor)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func scheduleDayBoundaryRefresh() {
        dayChangeTimer?.invalidate()

        let now = DateService.now()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = DateService.daySwitchHour
        components.minute = 0
        components.second = 0

        guard var boundary = calendar.date(from: components) else { return }
        if boundary <= now {
            boundary = calendar.date(byAdding: .day, value: 1, to: boundary) ?? boundary
        }

        let interval = max(boundary.timeIntervalSince(now), 1)
        dayChangeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            refreshId = UUID()
            scheduleDayBoundaryRefresh()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

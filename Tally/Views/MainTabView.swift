//
//  MainTabView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @State private var tabBarId = UUID()
    
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
        .id(tabBarId)
        .tint(currentTheme.accentColor)
        .onAppear {
            updateTabBarAppearance()
        }
        .onChange(of: selectedThemeRaw) { _, newValue in
            let theme = ThemeColor(rawValue: newValue) ?? .purple
            updateTabBarAppearance(for: theme)
            tabBarId = UUID()
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
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

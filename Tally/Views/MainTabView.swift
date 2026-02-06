//
//  MainTabView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
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
        .task {
            seedSampleDataIfNeeded()
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

    private func seedSampleDataIfNeeded() {
#if DEBUG
        let defaults = UserDefaults.standard
        let seedKey = "seededSampleData_v1"
        guard !defaults.bool(forKey: seedKey) else { return }

        let descriptor = FetchDescriptor<Habit>()
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            defaults.set(true, forKey: seedKey)
            return
        }

        let calendar = Calendar.current
        let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
        let startDate = calendar.date(byAdding: .day, value: -59, to: today) ?? today

        let samples: [(name: String, icon: String, colorHex: String, frequency: HabitFrequency, target: Int)] = [
            ("Hydrate", "drop.fill", "#4FC3F7", .daily, 7),
            ("Workout", "figure.run", "#FF7043", .weekly, 4),
            ("Read", "book.fill", "#BA68C8", .daily, 7),
            ("Listen", "music.note", "#3F51B5", .weekly, 2)
        ]

        for (index, sample) in samples.enumerated() {
            let habit = Habit(
                name: sample.name,
                icon: sample.icon,
                colorHex: sample.colorHex,
                reminderEnabled: false,
                frequency: sample.frequency,
                targetPerWeek: sample.target
            )
            habit.createdAt = calendar.date(byAdding: .day, value: index, to: startDate) ?? startDate
            modelContext.insert(habit)

            var date = habit.createdAt
            while date <= today {
                let dayIndex = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
                let shouldComplete = ((dayIndex + index) % 3) != 0
                if shouldComplete {
                    let entry = HabitEntry(date: date, completed: true)
                    entry.habit = habit
                    habit.entries.append(entry)
                    modelContext.insert(entry)
                }
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
        }

        let fullyCompletedStartDate = calendar.date(byAdding: .day, value: -20, to: today) ?? today
        let fullyCompletedHabit = Habit(
            name: "Meditate",
            icon: "brain.head.profile",
            colorHex: "#81C784",
            reminderEnabled: false,
            frequency: .daily,
            targetPerWeek: 7
        )
        fullyCompletedHabit.createdAt = fullyCompletedStartDate
        modelContext.insert(fullyCompletedHabit)

        var completedDate = fullyCompletedStartDate
        while completedDate <= today {
            let entry = HabitEntry(date: completedDate, completed: true)
            entry.habit = fullyCompletedHabit
            fullyCompletedHabit.entries.append(entry)
            modelContext.insert(entry)
            completedDate = calendar.date(byAdding: .day, value: 1, to: completedDate) ?? completedDate
        }

        let alternateDayStartDate = calendar.date(byAdding: .day, value: -240, to: today) ?? today
        let alternateDayHabit = Habit(
            name: "Stretch",
            icon: "figure.cooldown",
            colorHex: "#FFB74D",
            reminderEnabled: false,
            frequency: .daily,
            targetPerWeek: 7
        )
        alternateDayHabit.createdAt = alternateDayStartDate
        modelContext.insert(alternateDayHabit)

        var alternateDate = alternateDayStartDate
        while alternateDate <= today {
            let dayIndex = calendar.dateComponents([.day], from: alternateDayStartDate, to: alternateDate).day ?? 0
            if dayIndex % 2 == 0 {
                let entry = HabitEntry(date: alternateDate, completed: true)
                entry.habit = alternateDayHabit
                alternateDayHabit.entries.append(entry)
                modelContext.insert(entry)
            }
            alternateDate = calendar.date(byAdding: .day, value: 1, to: alternateDate) ?? alternateDate
        }

        try? modelContext.save()
        defaults.set(true, forKey: seedKey)
#endif
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

//
//  TallyApp.swift
//  Tally
//
//  Created by Giray Coskun on 3.02.2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct TallyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                clearNotifications()
                refreshScheduledReminders()
            }
        }
    }
    
    private func clearNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    private func refreshScheduledReminders() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Habit>()

        guard let habits = try? context.fetch(descriptor) else {
            return
        }

        NotificationService.shared.scheduleSmartReminders(for: habits)
    }
}

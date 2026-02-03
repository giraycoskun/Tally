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
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, delete the old store files and create fresh
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            let storeFiles = [
                "default.store",
                "default.store-shm",
                "default.store-wal"
            ]
            
            for file in storeFiles {
                let url = appSupport.appendingPathComponent(file)
                if fileManager.fileExists(atPath: url.path) {
                    try? fileManager.removeItem(at: url)
                }
            }
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
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
            }
        }
    }
    
    private func clearNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }
}

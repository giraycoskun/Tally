//
//  SettingsView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    await NotificationService.shared.requestPermission()
                                    NotificationService.shared.scheduleSmartReminders(for: habits)
                                }
                            } else {
                                NotificationService.shared.cancelAllReminders()
                            }
                        }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Habits")
                        Spacer()
                        Text("\(habits.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(habits.flatMap { $0.entries }.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Feedback") {
                    Link(destination: URL(string: "mailto:feedback@tally.app")!) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com/app/tally")!) {
                        Label("Rate on App Store", systemImage: "star")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    // Would need to implement actual reset
                }
            } message: {
                Text("This will permanently delete all habits and their history. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

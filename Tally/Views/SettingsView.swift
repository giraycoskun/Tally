//
//  SettingsView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    @State private var showingResetAlert = false
    
    private var selectedTheme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.surfaceBackground
                    .ignoresSafeArea()
                
                Form {
                    appearanceSection
                    dayBoundarySection
                    notificationsSection
                    aboutSection
                    feedbackSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(selectedTheme.darkColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    habits.forEach { modelContext.delete($0) }
                    try? modelContext.save()
                    NotificationService.shared.cancelAllReminders()
                }
            } message: {
                Text("This will permanently delete all habits and their history. This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme Color")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                    ForEach(ThemeColor.allCases) { theme in
                        ZStack {
                            Circle()
                                .fill(theme.previewColor)
                                .frame(width: 44, height: 44)
                            
                            if selectedTheme == theme {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            selectedThemeRaw = theme.rawValue
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var dayBoundarySection: some View {
        Section {
            Picker("Day Starts At", selection: $daySwitchHour) {
                Text("Midnight (12:00 AM)").tag(0)
                Text("1:00 AM").tag(1)
                Text("2:00 AM").tag(2)
                Text("3:00 AM").tag(3)
                Text("4:00 AM").tag(4)
                Text("5:00 AM").tag(5)
                Text("6:00 AM").tag(6)
            }

        } header: {
            Text("Day Boundary")
        } footer: {
            Text("Set when a new day begins. Useful if you're a night owl—completing habits after midnight will count for the previous day.")
        }
    }
    
    private var notificationsSection: some View {
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
    }
    
    private var aboutSection: some View {
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
    }
    
    private var feedbackSection: some View {
        Section("Feedback") {
            Link(destination: URL(string: "mailto:feedback@tally.app")!) {
                Label("Send Feedback", systemImage: "envelope")
            }
            
            Link(destination: URL(string: "https://apps.apple.com/app/tally")!) {
                Label("Rate on App Store", systemImage: "star")
            }
        }
    }
    
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

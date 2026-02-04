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
    @State private var showingResetAlert = false
    
    private var selectedTheme: ThemeColor {
        get { ThemeColor(rawValue: selectedThemeRaw) ?? .purple }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.surfaceBackground
                    .ignoresSafeArea()
                
                Form {
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
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

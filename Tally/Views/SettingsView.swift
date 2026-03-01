//
//  SettingsView.swift
//  Tally
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    @State private var showingResetAlert = false
    @State private var exportItem: ExportItem?
    @State private var exportError: String?
    @State private var showingExportError = false
    @State private var showingImportPicker = false
    @State private var showingImportConfirm = false
    @State private var importError: String?
    @State private var showingImportError = false
    @State private var pendingImport: ExportData?
    
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
                    dataSection
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
            .sheet(item: $exportItem) { item in
                ShareSheet(activityItems: [item.url])
            }
            .alert("Export Failed", isPresented: $showingExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "An unknown error occurred.")
            }
            .alert("Import Data?", isPresented: $showingImportConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingImport = nil
                }
                Button("Import", role: .destructive) {
                    if let pendingImport {
                        importData(pendingImport)
                        self.pendingImport = nil
                    }
                }
            } message: {
                Text("Importing will merge with existing habits and history. Existing items with the same ID will be updated.")
            }
            .alert("Import Failed", isPresented: $showingImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "An unknown error occurred.")
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        let data = try Data(contentsOf: url)
                        let exportData = try ExportService.shared.decodeFromJSON(data: data)
                        pendingImport = exportData
                        showingImportConfirm = true
                    } catch {
                        importError = error.localizedDescription
                        showingImportError = true
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                    showingImportError = true
                }
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
    
    private var dataSection: some View {
        Section("Data") {
            Button {
                do {
                    let url = try ExportService.shared.generateExportURL(habits: habits)
                    exportItem = ExportItem(url: url)
                } catch {
                    exportError = error.localizedDescription
                    showingExportError = true
                }
            } label: {
                Label("Export as JSON", systemImage: "square.and.arrow.up")
            }
            
            Button {
                showingImportPicker = true
            } label: {
                Label("Import from JSON", systemImage: "square.and.arrow.down")
            }
        }
    }
    
    private func importData(_ exportData: ExportData) {
        var habitsById: [UUID: Habit] = [:]
        habits.forEach { habit in
            habitsById[habit.id] = habit
        }
        
        let currentMaxSortOrder = habits.map(\.sortOrder).max() ?? -1
        var nextSortOrder = currentMaxSortOrder + 1
        
        for exportHabit in exportData.habits {
            let habitId = UUID(uuidString: exportHabit.id)
            let frequency = HabitFrequency(rawValue: exportHabit.frequency) ?? .daily
            let reminderType = ReminderType(rawValue: exportHabit.reminderType) ?? .single
            
            let habit: Habit
            if let habitId, let existing = habitsById[habitId] {
                habit = existing
            } else {
                habit = Habit(
                    name: exportHabit.name,
                    icon: exportHabit.icon,
                    colorHex: exportHabit.colorHex,
                    reminderTime: exportHabit.reminderTime,
                    reminderTimes: exportHabit.reminderTimes,
                    reminderEnabled: exportHabit.reminderEnabled,
                    frequency: frequency,
                    targetPerWeek: exportHabit.targetPerWeek,
                    dailyTarget: exportHabit.dailyTarget,
                    sortOrder: exportHabit.sortOrder > 0 ? exportHabit.sortOrder : nextSortOrder,
                    reminderType: reminderType,
                    periodicStartTime: exportHabit.periodicStartTime,
                    periodicEndTime: exportHabit.periodicEndTime,
                    periodicIntervalHours: exportHabit.periodicIntervalHours
                )
                
                habit.id = habitId ?? UUID()
                habit.createdAt = exportHabit.createdAt
                modelContext.insert(habit)
                habitsById[habit.id] = habit
                nextSortOrder += 1
            }
            
            habit.name = exportHabit.name
            habit.icon = exportHabit.icon
            habit.colorHex = exportHabit.colorHex
            habit.reminderTime = exportHabit.reminderTime
            habit.reminderTimes = exportHabit.reminderTimes
            habit.reminderEnabled = exportHabit.reminderEnabled
            habit.frequency = frequency
            habit.targetPerWeek = exportHabit.targetPerWeek
            habit.dailyTarget = exportHabit.dailyTarget
            habit.reminderType = reminderType
            habit.periodicStartTime = exportHabit.periodicStartTime
            habit.periodicEndTime = exportHabit.periodicEndTime
            habit.periodicIntervalHours = exportHabit.periodicIntervalHours
            habit.createdAt = exportHabit.createdAt
            if exportHabit.sortOrder > 0 {
                habit.sortOrder = exportHabit.sortOrder
            }
            
            var entriesById: [UUID: HabitEntry] = [:]
            habit.entries.forEach { entry in
                entriesById[entry.id] = entry
            }
            
            for entry in exportHabit.entries {
                let entryId = UUID(uuidString: entry.id)
                if let entryId, let existingEntry = entriesById[entryId] {
                    existingEntry.date = entry.date
                    existingEntry.completed = entry.completed
                    existingEntry.count = entry.count
                } else {
                    let habitEntry = HabitEntry(
                        date: entry.date,
                        completed: entry.completed,
                        count: entry.count
                    )
                    habitEntry.id = entryId ?? UUID()
                    habitEntry.habit = habit
                    habit.entries.append(habitEntry)
                    modelContext.insert(habitEntry)
                }
            }
        }
        
        try? modelContext.save()
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("Version \(AppVersion.version)")
                    .font(.footnote)
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

struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

//
//  AddHabitView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "checkmark.circle"
    @State private var selectedColor = "#4CAF50"
    @State private var frequency: HabitFrequency = .daily
    @State private var targetPerWeek = 3
    @State private var dailyTarget = 1
    @State private var reminderEnabled = false
    @State private var reminderType: ReminderType = .single
    @State private var reminderTimes: [Date] = [Date()]
    @State private var periodicStartTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var periodicEndTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var periodicIntervalHours = 2
    
    private let icons = [
        "checkmark.circle", "star.fill", "heart.fill", "book.fill",
        "figure.run", "drop.fill", "moon.fill", "sun.max.fill",
        "brain.head.profile", "dumbbell.fill", "fork.knife", "cup.and.saucer.fill",
        "bed.double.fill", "pencil", "music.note", "gamecontroller.fill",
        "leaf.fill", "pills.fill", "cross.case.fill", "creditcard.fill"
    ]
    
    private let colors = [
        "#4CAF50", "#2196F3", "#9C27B0", "#FF9800",
        "#F44336", "#00BCD4", "#E91E63", "#795548",
        "#607D8B", "#3F51B5", "#009688", "#FFC107"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Habit Details") {
                    TextField("Habit name", text: $name)
                    
                    iconPicker
                    
                    colorPicker
                }
                
                Section("Frequency") {
                    Picker("How often", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.description).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if frequency == .weekly {
                        Stepper("\(targetPerWeek) times per week", value: $targetPerWeek, in: 1...6)
                    } else {
                        Stepper("\(dailyTarget) time\(dailyTarget > 1 ? "s" : "") per day", value: $dailyTarget, in: 1...12)
                    }
                }
                
                Section("Reminders") {
                    Toggle("Enable Reminders", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        Picker("Reminder Type", selection: $reminderType) {
                            ForEach(ReminderType.allCases, id: \.self) { type in
                                Text(type.description).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if reminderType == .single {
                            VStack(spacing: 8) {
                                ForEach(reminderTimes.indices, id: \.self) { index in
                                    HStack {
                                        DatePicker(
                                            "Time \(index + 1)",
                                            selection: Binding(
                                                get: { reminderTimes[index] },
                                                set: { reminderTimes[index] = $0 }
                                            ),
                                            displayedComponents: .hourAndMinute
                                        )
                                        
                                        Spacer()
                                        
                                        if reminderTimes.count > 1 {
                                            Button(role: .destructive) {
                                                reminderTimes.remove(at: index)
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                    }
                                }
                                
                                Button {
                                    reminderTimes.append(Date())
                                } label: {
                                    Label("Add Time", systemImage: "plus.circle.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                        } else {
                            DatePicker("From", selection: $periodicStartTime, displayedComponents: .hourAndMinute)
                            DatePicker("To", selection: $periodicEndTime, displayedComponents: .hourAndMinute)
                            Stepper("Every \(periodicIntervalHours) hour\(periodicIntervalHours > 1 ? "s" : "")", value: $periodicIntervalHours, in: 1...6)
                        }
                    }
                }
                
                Section {
                    previewCard
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(icons, id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(selectedIcon == icon ? Color(hex: selectedColor)?.opacity(0.2) : Color(.systemGray6))
                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .gray)
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedIcon = icon
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(Color(hex: color) ?? .gray)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                .padding(2)
                        )
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var previewCard: some View {
        HStack {
            Image(systemName: selectedIcon)
                .font(.title2)
                .foregroundColor(Color(hex: selectedColor))
                .frame(width: 44, height: 44)
                .background((Color(hex: selectedColor) ?? .green).opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(name.isEmpty ? "Habit Name" : name)
                    .font(.headline)
                    .foregroundColor(name.isEmpty ? .secondary : .primary)
                
                if frequency == .daily {
                    Text(dailyTarget == 1 ? "Daily" : "\(dailyTarget)x per day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(targetPerWeek)x per week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if reminderEnabled {
                    if reminderType == .single {
                        if reminderTimes.count == 1 {
                            Text("Reminder at \(reminderTimes[0], style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(reminderTimes.count) reminders daily")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func saveHabit() {
        let habit = Habit(
            name: name,
            icon: selectedIcon,
            colorHex: selectedColor,
            reminderTime: nil,
            reminderTimes: reminderEnabled && reminderType == .single ? sortedReminderTimes(reminderTimes) : [],
            reminderEnabled: reminderEnabled,
            frequency: frequency,
            targetPerWeek: frequency == .weekly ? targetPerWeek : 7,
            dailyTarget: frequency == .daily ? max(dailyTarget, 1) : 1,
            reminderType: reminderType,
            periodicStartTime: reminderEnabled && reminderType == .periodic ? periodicStartTime : nil,
            periodicEndTime: reminderEnabled && reminderType == .periodic ? periodicEndTime : nil,
            periodicIntervalHours: periodicIntervalHours
        )
        
        modelContext.insert(habit)
        
        if reminderEnabled {
            Task {
                await NotificationService.shared.requestPermission()
                NotificationService.shared.scheduleReminder(for: habit)
            }
        }
        
        dismiss()
    }

    private func sortedReminderTimes(_ times: [Date]) -> [Date] {
        let calendar = Calendar.current
        return times.sorted {
            let lhs = calendar.dateComponents([.hour, .minute], from: $0)
            let rhs = calendar.dateComponents([.hour, .minute], from: $1)
            if lhs.hour == rhs.hour {
                return (lhs.minute ?? 0) < (rhs.minute ?? 0)
            }
            return (lhs.hour ?? 0) < (rhs.hour ?? 0)
        }
    }
}

#Preview {
    AddHabitView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

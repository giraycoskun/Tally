//
//  EditHabitView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var frequency: HabitFrequency
    @State private var targetPerWeek: Int
    @State private var reminderEnabled: Bool
    @State private var reminderType: ReminderType
    @State private var reminderTimes: [Date]
    @State private var periodicStartTime: Date
    @State private var periodicEndTime: Date
    @State private var periodicIntervalHours: Int
    
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
    
    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColor = State(initialValue: habit.colorHex)
        _frequency = State(initialValue: habit.frequency)
        _targetPerWeek = State(initialValue: habit.targetPerWeek)
        _reminderEnabled = State(initialValue: habit.reminderEnabled)
        _reminderType = State(initialValue: habit.reminderType)
        if !habit.reminderTimes.isEmpty {
            _reminderTimes = State(initialValue: habit.reminderTimes)
        } else if let reminderTime = habit.reminderTime {
            _reminderTimes = State(initialValue: [reminderTime])
        } else {
            _reminderTimes = State(initialValue: [Date()])
        }
        _periodicStartTime = State(initialValue: habit.periodicStartTime ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date())
        _periodicEndTime = State(initialValue: habit.periodicEndTime ?? Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date())
        _periodicIntervalHours = State(initialValue: habit.periodicIntervalHours)
    }
    
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
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
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
    
    private func saveChanges() {
        habit.name = name
        habit.icon = selectedIcon
        habit.colorHex = selectedColor
        habit.frequency = frequency
        habit.targetPerWeek = frequency == .daily ? 7 : targetPerWeek
        habit.reminderEnabled = reminderEnabled
        habit.reminderType = reminderType
        habit.reminderTime = nil
        habit.reminderTimes = reminderEnabled && reminderType == .single ? sortedReminderTimes(reminderTimes) : []
        habit.periodicStartTime = reminderEnabled && reminderType == .periodic ? periodicStartTime : nil
        habit.periodicEndTime = reminderEnabled && reminderType == .periodic ? periodicEndTime : nil
        habit.periodicIntervalHours = periodicIntervalHours
        
        if reminderEnabled {
            Task {
                await NotificationService.shared.requestPermission()
                NotificationService.shared.scheduleReminder(for: habit)
            }
        } else {
            NotificationService.shared.cancelReminder(for: habit)
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
    EditHabitView(habit: Habit(name: "Exercise", icon: "figure.run"))
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

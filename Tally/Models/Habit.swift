//
//  Habit.swift
//  Tally
//

import Foundation
import SwiftData
import SwiftUI

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    
    var description: String {
        rawValue
    }
}

enum ReminderType: String, Codable, CaseIterable {
    case single = "Single"
    case periodic = "Periodic"
    
    var description: String {
        switch self {
        case .single: return "Once a day"
        case .periodic: return "Regular intervals"
        }
    }
}

@Model
final class Habit {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var reminderTime: Date?
    var reminderEnabled: Bool
    var frequencyRaw: String
    var targetPerWeek: Int
    
    // Periodic reminder properties
    var reminderTypeRaw: String
    var periodicStartTime: Date?
    var periodicEndTime: Date?
    var periodicIntervalHours: Int
    
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []
    
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }
    
    var reminderType: ReminderType {
        get { ReminderType(rawValue: reminderTypeRaw) ?? .single }
        set { reminderTypeRaw = newValue.rawValue }
    }
    
    init(
        name: String,
        icon: String = "checkmark.circle",
        colorHex: String = "#4CAF50",
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        frequency: HabitFrequency = .daily,
        targetPerWeek: Int = 7,
        reminderType: ReminderType = .single,
        periodicStartTime: Date? = nil,
        periodicEndTime: Date? = nil,
        periodicIntervalHours: Int = 2
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.frequencyRaw = frequency.rawValue
        self.targetPerWeek = frequency == .daily ? 7 : targetPerWeek
        self.reminderTypeRaw = reminderType.rawValue
        self.periodicStartTime = periodicStartTime
        self.periodicEndTime = periodicEndTime
        self.periodicIntervalHours = periodicIntervalHours
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .green
    }
    
    var frequencyLabel: String {
        if frequency == .daily {
            return "Daily"
        } else {
            return "\(targetPerWeek)x per week"
        }
    }
    
    // Completions this week
    var completionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        return entries.filter { entry in
            entry.completed && entry.date >= weekStart && entry.date <= now
        }.count
    }
    
    // Check if weekly goal is met
    var isWeeklyGoalMet: Bool {
        completionsThisWeek >= targetPerWeek
    }
    
    // Progress towards weekly goal (0.0 to 1.0)
    var weeklyProgress: Double {
        min(Double(completionsThisWeek) / Double(targetPerWeek), 1.0)
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        
        if frequency == .daily {
            var streak = 0
            var currentDate = calendar.startOfDay(for: Date())
            
            let sortedEntries = entries
                .filter { $0.completed }
                .map { calendar.startOfDay(for: $0.date) }
                .sorted(by: >)
            
            let entrySet = Set(sortedEntries)
            
            while entrySet.contains(currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            }
            
            return streak
        } else {
            // For weekly habits, count consecutive weeks where goal was met
            var streak = 0
            var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            
            while true {
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
                let completionsInWeek = entries.filter { entry in
                    entry.completed && entry.date >= weekStart && entry.date <= weekEnd
                }.count
                
                if completionsInWeek >= targetPerWeek {
                    streak += 1
                    weekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
                } else {
                    break
                }
            }
            
            return streak
        }
    }
    
    var longestStreak: Int {
        let calendar = Calendar.current
        
        if frequency == .daily {
            let sortedDates = entries
                .filter { $0.completed }
                .map { calendar.startOfDay(for: $0.date) }
                .sorted()
            
            guard !sortedDates.isEmpty else { return 0 }
            
            var longest = 1
            var current = 1
            
            for i in 1..<sortedDates.count {
                let diff = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
                if diff == 1 {
                    current += 1
                    longest = max(longest, current)
                } else if diff > 1 {
                    current = 1
                }
            }
            
            return longest
        } else {
            // For weekly, find longest streak of weeks meeting goal
            guard !entries.isEmpty else { return 0 }
            
            let sortedDates = entries.filter { $0.completed }.map { $0.date }.sorted()
            guard let firstDate = sortedDates.first else { return 0 }
            
            var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDate))!
            let now = Date()
            
            var longest = 0
            var current = 0
            
            while weekStart <= now {
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
                let completionsInWeek = entries.filter { entry in
                    entry.completed && entry.date >= weekStart && entry.date <= weekEnd
                }.count
                
                if completionsInWeek >= targetPerWeek {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 0
                }
                
                weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            }
            
            return longest
        }
    }
    
    var completionRate: Double {
        let calendar = Calendar.current
        
        if frequency == .daily {
            let daysSinceCreation = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
            guard daysSinceCreation > 0 else { return 0 }
            
            let completedCount = entries.filter { $0.completed }.count
            return Double(completedCount) / Double(daysSinceCreation + 1) * 100
        } else {
            // For weekly habits, calculate based on weeks
            let weeksSinceCreation = calendar.dateComponents([.weekOfYear], from: createdAt, to: Date()).weekOfYear ?? 0
            guard weeksSinceCreation > 0 else {
                return weeklyProgress * 100
            }
            
            let totalExpected = (weeksSinceCreation + 1) * targetPerWeek
            let completedCount = entries.filter { $0.completed }.count
            return Double(completedCount) / Double(totalExpected) * 100
        }
    }
    
    func isCompletedOn(date: Date) -> Bool {
        let calendar = Calendar.current
        return entries.contains { entry in
            entry.completed && calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    func toggleCompletion(for date: Date, context: ModelContext) {
        let calendar = Calendar.current
        
        if let existingEntry = entries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            existingEntry.completed.toggle()
        } else {
            let newEntry = HabitEntry(date: date, completed: true)
            newEntry.habit = self
            entries.append(newEntry)
            context.insert(newEntry)
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

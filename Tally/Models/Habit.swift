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
    var reminderTimes: [Date]
    var reminderEnabled: Bool
    var frequencyRaw: String
    var targetPerWeek: Int
    var dailyTarget: Int
    
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
        reminderTimes: [Date] = [],
        reminderEnabled: Bool = false,
        frequency: HabitFrequency = .daily,
        targetPerWeek: Int = 7,
        dailyTarget: Int = 1,
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
        self.reminderTimes = reminderTimes
        self.reminderEnabled = reminderEnabled
        self.frequencyRaw = frequency.rawValue
        self.targetPerWeek = frequency == .daily ? 7 : targetPerWeek
        self.dailyTarget = max(dailyTarget, 1)
        self.reminderTypeRaw = reminderType.rawValue
        self.periodicStartTime = periodicStartTime
        self.periodicEndTime = periodicEndTime
        self.periodicIntervalHours = periodicIntervalHours
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .green
    }

    var effectiveReminderTimes: [Date] {
        if !reminderTimes.isEmpty {
            return reminderTimes
        }
        if let reminderTime {
            return [reminderTime]
        }
        return []
    }
    
    var frequencyLabel: String {
        if frequency == .daily {
            return dailyTarget == 1 ? "Daily" : "\(dailyTarget)x per day"
        } else {
            return "\(targetPerWeek)x per week"
        }
    }
    
    var totalCompletions: Int {
        entries.reduce(0) { $0 + normalizedCount(for: $1) }
    }
    
    func completionCount(on date: Date) -> Int {
        let dateService = DateService.shared
        let effectiveDay = dateService.startOfEffectiveDay(for: date)
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: effectiveDay)
        
        if let entry = entries.first(where: {
            let entryComponents = calendar.dateComponents([.year, .month, .day], from: $0.date)
            return targetComponents.year == entryComponents.year &&
                   targetComponents.month == entryComponents.month &&
                   targetComponents.day == entryComponents.day
        }) {
            return normalizedCount(for: entry)
        }
        
        return 0
    }
    
    func completionProgress(on date: Date) -> Double {
        if frequency == .daily {
            return min(Double(completionCount(on: date)) / Double(max(dailyTarget, 1)), 1.0)
        }
        return isCompletedOn(date: date) ? 1.0 : 0.0
    }
    
    func completions(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        return entries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return entryDay >= start && entryDay <= end
        }.reduce(0) { $0 + normalizedCount(for: $1) }
    }
    
    func entryCount(_ entry: HabitEntry) -> Int {
        normalizedCount(for: entry)
    }
    
    // Completions this week
    var completionsThisWeek: Int {
        let dateService = DateService.shared
        let effectiveToday = dateService.startOfEffectiveDay(for: DateService.now())
        let weekStart = dateService.startOfEffectiveWeek(for: DateService.now())
        let calendar = Calendar.current
        
        return entries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return entryDay >= weekStart && entryDay <= effectiveToday
        }.reduce(0) { $0 + normalizedCount(for: $1) }
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
        let dateService = DateService.shared
        
        if frequency == .daily {
            var streak = 0
            var currentDate = dateService.startOfEffectiveDay(for: DateService.now())
            
            // Normalize entry dates to midnight for consistent comparison
            let sortedEntries = entries
                .filter { isEntryCompleted($0) }
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
            var weekStart = dateService.startOfEffectiveWeek(for: DateService.now())
            
            while true {
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let completionsInWeek = entries.filter { entry in
                    let entryDay = calendar.startOfDay(for: entry.date)
                    return entryDay >= weekStart && entryDay <= weekEnd
                }.reduce(0) { $0 + normalizedCount(for: $1) }
                
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
        let dateService = DateService.shared
        
        if frequency == .daily {
            // Normalize entry dates to midnight for consistent comparison
            let sortedDates = entries
                .filter { isEntryCompleted($0) }
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
            
            let sortedDates = entries.filter { isEntryCompleted($0) }.map { $0.date }.sorted()
            guard let firstDate = sortedDates.first else { return 0 }
            
            var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDate))!
            let effectiveToday = dateService.startOfEffectiveDay(for: DateService.now())
            
            var longest = 0
            var current = 0
            
            while weekStart <= effectiveToday {
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
                let completionsInWeek = entries.filter { entry in
                    let entryDay = calendar.startOfDay(for: entry.date)
                    return entryDay >= weekStart && entryDay <= weekEnd
                }.reduce(0) { $0 + normalizedCount(for: $1) }
                
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
            let daysSinceCreation = calendar.dateComponents([.day], from: createdAt, to: DateService.now()).day ?? 0
            let totalDays = max(0, daysSinceCreation) + 1
            let expectedTotal = totalDays * max(dailyTarget, 1)
            let completedCount = totalCompletions
            let rate = Double(completedCount) / Double(expectedTotal) * 100
            return min(rate, 100)
        } else {
            // For weekly habits, calculate based on weeks
            let weeksSinceCreation = calendar.dateComponents([.weekOfYear], from: createdAt, to: DateService.now()).weekOfYear ?? 0
            guard weeksSinceCreation > 0 else {
                return min(weeklyProgress * 100, 100)
            }
            
            let totalExpected = (weeksSinceCreation + 1) * targetPerWeek
            let completedCount = totalCompletions
            let rate = Double(completedCount) / Double(totalExpected) * 100
            return min(rate, 100)
        }
    }
    
    func isCompletedOn(date: Date) -> Bool {
        let dateService = DateService.shared
        let effectiveDay = dateService.startOfEffectiveDay(for: date)
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: effectiveDay)
        
        return entries.contains { entry in
            let entryComponents = calendar.dateComponents([.year, .month, .day], from: entry.date)
            let isSameDay = targetComponents.year == entryComponents.year &&
                targetComponents.month == entryComponents.month &&
                targetComponents.day == entryComponents.day
            guard isSameDay else { return false }
            return isEntryCompleted(entry)
        }
    }
    
    func toggleCompletion(for date: Date, context: ModelContext) {
        let dateService = DateService.shared
        let effectiveDay = dateService.startOfEffectiveDay(for: date)
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: effectiveDay)
        
        if let existingEntry = entries.first(where: { 
            let entryComponents = calendar.dateComponents([.year, .month, .day], from: $0.date)
            return targetComponents.year == entryComponents.year &&
                   targetComponents.month == entryComponents.month &&
                   targetComponents.day == entryComponents.day
        }) {
            if frequency == .daily {
                let currentCount = normalizedCount(for: existingEntry)
                if currentCount >= dailyTarget {
                    existingEntry.count = 0
                    existingEntry.completed = false
                } else {
                    let nextCount = min(currentCount + 1, dailyTarget)
                    existingEntry.count = nextCount
                    existingEntry.completed = nextCount >= dailyTarget
                }
            } else {
                let isComplete = normalizedCount(for: existingEntry) > 0
                existingEntry.completed = !isComplete
                existingEntry.count = existingEntry.completed ? 1 : 0
            }
        } else {
            let initialCount = frequency == .daily ? 1 : 1
            let isComplete = frequency == .daily ? initialCount >= dailyTarget : true
            let newEntry = HabitEntry(date: effectiveDay, completed: isComplete, count: initialCount)
            newEntry.habit = self
            entries.append(newEntry)
            context.insert(newEntry)
        }
    }
    
    private func normalizedCount(for entry: HabitEntry) -> Int {
        if entry.count > 0 {
            return entry.count
        }
        return entry.completed ? 1 : 0
    }
    
    private func isEntryCompleted(_ entry: HabitEntry) -> Bool {
        let count = normalizedCount(for: entry)
        if frequency == .daily {
            return count >= dailyTarget
        }
        return count > 0
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

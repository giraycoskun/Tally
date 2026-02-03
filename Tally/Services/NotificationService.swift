//
//  NotificationService.swift
//  Tally
//

import Foundation
import UserNotifications
import SwiftData

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func scheduleReminder(for habit: Habit) {
        guard habit.reminderEnabled else { return }
        
        cancelReminder(for: habit)
        
        if habit.reminderType == .periodic {
            schedulePeriodicReminders(for: habit)
        } else {
            scheduleSingleReminder(for: habit)
        }
    }
    
    private func scheduleSingleReminder(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for \(habit.name)"
        content.body = getSmartMessage(for: habit)
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: habit.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func schedulePeriodicReminders(for habit: Habit) {
        guard let startTime = habit.periodicStartTime,
              let endTime = habit.periodicEndTime else { return }
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let startMinute = calendar.component(.minute, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)
        let interval = habit.periodicIntervalHours
        
        var currentHour = startHour
        var reminderIndex = 0
        
        while currentHour <= endHour {
            let content = UNMutableNotificationContent()
            content.title = "Reminder: \(habit.name)"
            content.body = getPeriodicMessage(for: habit, isFirst: reminderIndex == 0)
            content.sound = .default
            
            var components = DateComponents()
            components.hour = currentHour
            components.minute = startMinute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let identifier = "\(habit.id.uuidString)-periodic-\(reminderIndex)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule periodic notification: \(error)")
                }
            }
            
            currentHour += interval
            reminderIndex += 1
        }
    }
    
    func cancelReminder(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        // Cancel single reminder
        center.removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
        
        // Cancel all periodic reminders (up to 12 possible per day)
        var periodicIds: [String] = []
        for i in 0..<12 {
            periodicIds.append("\(habit.id.uuidString)-periodic-\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: periodicIds)
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func getSmartMessage(for habit: Habit) -> String {
        let streak = habit.currentStreak
        let completionRate = habit.completionRate
        
        if streak >= 7 {
            return "🔥 \(streak) day streak! Keep the momentum going!"
        } else if streak >= 3 {
            return "Great progress! You're on a \(streak) day streak."
        } else if streak == 0 && completionRate > 50 {
            return "Start a new streak today! You've been doing great overall."
        } else if completionRate < 30 {
            return "Small steps lead to big changes. Let's do this!"
        } else {
            return "Don't break the chain! Complete your habit today."
        }
    }
    
    private func getPeriodicMessage(for habit: Habit, isFirst: Bool) -> String {
        if habit.isCompletedOn(date: Date()) {
            return "Great job completing \(habit.name) today! 🎉"
        } else if isFirst {
            return "Start your day right! Time for \(habit.name)."
        } else {
            return "Quick check: Have you done \(habit.name) yet?"
        }
    }
    
    func scheduleSmartReminders(for habits: [Habit]) {
        for habit in habits where habit.reminderEnabled {
            scheduleReminder(for: habit)
        }
    }
}

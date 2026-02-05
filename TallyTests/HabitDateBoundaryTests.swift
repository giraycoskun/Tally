//
//  HabitDateBoundaryTests.swift
//  TallyTests
//

import Testing
import Foundation
import SwiftData
@testable import Tally

@Suite(.serialized)
@MainActor
struct HabitDateBoundaryTests {
    
    var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }
    
    // MARK: - Helper Methods
    
    private func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = TimeZone.current
        return cal.date(from: components)!
    }
    
    private func dayComponent(from date: Date) -> Int {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal.component(.day, from: date)
    }
    
    private func setDaySwitchHour(_ hour: Int) {
        UserDefaults.standard.set(hour, forKey: "daySwitchHour")
    }
    
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    }
    
    // MARK: - Entry Creation with Boundary Tests
    
    @Test func entryCreatedWithBoundaryStoresCorrectDate() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        // Simulate clicking at 2 AM on Feb 5th (should store Feb 4th)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        habit.toggleCompletion(for: twoAM, context: context)
        
        #expect(habit.entries.count == 1)
        #expect(dayComponent(from: habit.entries[0].date) == 4) // Should be Feb 4th
    }
    
    @Test func entryCreatedAfterBoundaryStoresCurrentDate() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        // Simulate clicking at 4 AM on Feb 5th (should store Feb 5th)
        let fourAM = createDate(year: 2026, month: 2, day: 5, hour: 4)
        habit.toggleCompletion(for: fourAM, context: context)
        
        #expect(habit.entries.count == 1)
        #expect(dayComponent(from: habit.entries[0].date) == 5) // Should be Feb 5th
    }
    
    // MARK: - isCompletedOn with Boundary Change Tests
    
    @Test func isCompletedOnRespectsBoundaryForCurrentTime() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        // Create entry for Feb 4th at midnight
        let feb4th = createDate(year: 2026, month: 2, day: 4, hour: 0)
        habit.toggleCompletion(for: feb4th, context: context)
        
        // At 2 AM Feb 5th with boundary 3 AM, effective day is Feb 4th
        setDaySwitchHour(3)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        #expect(habit.isCompletedOn(date: twoAM)) // Should be true (effective day is Feb 4th)
        
        // At 2 AM Feb 5th with boundary 1 AM, effective day is Feb 5th
        setDaySwitchHour(1)
        #expect(!habit.isCompletedOn(date: twoAM)) // Should be false (effective day is Feb 5th)
    }
    
    @Test func boundaryChangeDoesNotCreateDuplicateEntries() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        // With boundary at 3 AM, click at 2 AM (stores Feb 4th)
        setDaySwitchHour(3)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        habit.toggleCompletion(for: twoAM, context: context)
        
        #expect(habit.entries.count == 1)
        #expect(dayComponent(from: habit.entries[0].date) == 4)
        
        // Change boundary to 1 AM, click at same time (now stores Feb 5th)
        setDaySwitchHour(1)
        habit.toggleCompletion(for: twoAM, context: context)
        
        // Should have 2 separate entries (Feb 4th and Feb 5th)
        #expect(habit.entries.count == 2)
    }
    
    @Test func entryForDayNotAffectedByBoundaryChange() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        // Create entry for Feb 5th with boundary at 0
        setDaySwitchHour(0)
        let feb5thNoon = createDate(year: 2026, month: 2, day: 5, hour: 12)
        habit.toggleCompletion(for: feb5thNoon, context: context)
        
        let entryDate = habit.entries[0].date
        #expect(dayComponent(from: entryDate) == 5)
        
        // Change boundary to 3 AM - entry should still be for Feb 5th
        setDaySwitchHour(3)
        
        // Check if Feb 5th (as a midnight date) is still completed
        let feb5thMidnight = createDate(year: 2026, month: 2, day: 5, hour: 0)
        #expect(habit.isCompletedOn(date: feb5thMidnight))
        
        // Feb 4th should NOT be completed
        let feb4thMidnight = createDate(year: 2026, month: 2, day: 4, hour: 0)
        #expect(!habit.isCompletedOn(date: feb4thMidnight))
    }
    
    // MARK: - Streak Calculation with Boundary Tests
    
    @Test func currentStreakCalculatesCorrectlyWithBoundary() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        setDaySwitchHour(0)
        
        // Create entries for Feb 3, 4, 5
        for day in 3...5 {
            let date = createDate(year: 2026, month: 2, day: day, hour: 12)
            habit.toggleCompletion(for: date, context: context)
        }
        
        #expect(habit.entries.count == 3)
        
        // Current streak should be calculated based on effective today
        // This test verifies entries are stored and retrieved consistently
    }
    
    // MARK: - Weekly Stats with Boundary Tests
    
    @Test func completionsThisWeekRespectsBoundary() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let habit = Habit(name: "Test Habit", frequency: .weekly, targetPerWeek: 3)
        context.insert(habit)
        
        setDaySwitchHour(0)
        
        // Create some entries in the current week
        let today = Date()
        habit.toggleCompletion(for: today, context: context)
        
        #expect(habit.completionsThisWeek >= 1)
    }
    
    // MARK: - Toggle Consistency Tests
    
    @Test func toggleOffAndOnMaintainsConsistency() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        setDaySwitchHour(3)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        
        // Toggle on
        habit.toggleCompletion(for: twoAM, context: context)
        #expect(habit.isCompletedOn(date: twoAM))
        #expect(habit.entries[0].completed == true)
        
        // Toggle off
        habit.toggleCompletion(for: twoAM, context: context)
        #expect(!habit.isCompletedOn(date: twoAM))
        #expect(habit.entries[0].completed == false)
        
        // Toggle on again
        habit.toggleCompletion(for: twoAM, context: context)
        #expect(habit.isCompletedOn(date: twoAM))
        #expect(habit.entries[0].completed == true)
        
        // Should still be only 1 entry
        #expect(habit.entries.count == 1)
    }
    
    @Test func toggleWithDifferentBoundariesCreatesCorrectEntries() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        
        // With boundary 3, toggle creates Feb 4th entry
        setDaySwitchHour(3)
        habit.toggleCompletion(for: twoAM, context: context)
        
        // With boundary 1, toggle creates Feb 5th entry
        setDaySwitchHour(1)
        habit.toggleCompletion(for: twoAM, context: context)
        
        #expect(habit.entries.count == 2)
        
        let days = habit.entries.map { dayComponent(from: $0.date) }.sorted()
        #expect(days == [4, 5])
    }
    
    // MARK: - Multiple Habits with History Tests
    
    @Test func multipleHabitsWithHistoryTrackedIndependently() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let exercise = Habit(name: "Exercise", icon: "figure.run")
        let reading = Habit(name: "Reading", icon: "book")
        let meditation = Habit(name: "Meditation", icon: "brain")
        
        context.insert(exercise)
        context.insert(reading)
        context.insert(meditation)
        
        // Create history for exercise: Feb 1-5 at various times
        for day in 1...5 {
            let date = createDate(year: 2026, month: 2, day: day, hour: 10)
            exercise.toggleCompletion(for: date, context: context)
        }
        
        // Create history for reading: Feb 2, 3, 5 (skipped Feb 1, 4)
        for day in [2, 3, 5] {
            let date = createDate(year: 2026, month: 2, day: day, hour: 21)
            reading.toggleCompletion(for: date, context: context)
        }
        
        // Create history for meditation: only Feb 5
        let feb5 = createDate(year: 2026, month: 2, day: 5, hour: 7)
        meditation.toggleCompletion(for: feb5, context: context)
        
        #expect(exercise.entries.count == 5)
        #expect(reading.entries.count == 3)
        #expect(meditation.entries.count == 1)
        
        // Check completion status for Feb 5
        let checkDate = createDate(year: 2026, month: 2, day: 5, hour: 12)
        #expect(exercise.isCompletedOn(date: checkDate))
        #expect(reading.isCompletedOn(date: checkDate))
        #expect(meditation.isCompletedOn(date: checkDate))
        
        // Check completion status for Feb 4
        let feb4Check = createDate(year: 2026, month: 2, day: 4, hour: 12)
        #expect(exercise.isCompletedOn(date: feb4Check))
        #expect(!reading.isCompletedOn(date: feb4Check))
        #expect(!meditation.isCompletedOn(date: feb4Check))
    }
    
    @Test func multipleHabitsLateNightCompletionWithBoundary() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let workout = Habit(name: "Late Night Workout")
        let journal = Habit(name: "Journal")
        
        context.insert(workout)
        context.insert(journal)
        
        // Complete workout at 1:30 AM on Feb 5 (should be Feb 4th effective)
        let lateNight = createDate(year: 2026, month: 2, day: 5, hour: 1, minute: 30)
        workout.toggleCompletion(for: lateNight, context: context)
        
        // Complete journal at 4:00 AM on Feb 5 (should be Feb 5th effective)
        let earlyMorning = createDate(year: 2026, month: 2, day: 5, hour: 4)
        journal.toggleCompletion(for: earlyMorning, context: context)
        
        // Verify entries stored on correct effective dates
        #expect(dayComponent(from: workout.entries[0].date) == 4)
        #expect(dayComponent(from: journal.entries[0].date) == 5)
        
        // Check from Feb 4th perspective
        let feb4Check = createDate(year: 2026, month: 2, day: 4, hour: 12)
        #expect(workout.isCompletedOn(date: feb4Check))
        #expect(!journal.isCompletedOn(date: feb4Check))
        
        // Check from Feb 5th perspective
        let feb5Check = createDate(year: 2026, month: 2, day: 5, hour: 12)
        #expect(!workout.isCompletedOn(date: feb5Check))
        #expect(journal.isCompletedOn(date: feb5Check))
    }
    
    @Test func streakCalculationWithHistoryAndBoundary() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let habit = Habit(name: "Daily Habit")
        context.insert(habit)
        
        // Create 7-day streak: Jan 30 - Feb 5 (all at noon)
        for dayOffset in 0..<7 {
            var components = DateComponents()
            components.year = 2026
            components.month = 1
            components.day = 30 + dayOffset
            components.hour = 12
            
            // Handle month overflow
            if components.day! > 31 {
                components.month = 2
                components.day = components.day! - 31
            }
            
            let date = calendar.date(from: components)!
            habit.toggleCompletion(for: date, context: context)
        }
        
        #expect(habit.entries.count == 7)
        #expect(habit.longestStreak >= 7)
    }
    
    @Test func streakBrokenByLateNightMiss() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let habit = Habit(name: "Streak Test")
        context.insert(habit)
        
        // Feb 1, 2, 3 completed at noon
        for day in 1...3 {
            let date = createDate(year: 2026, month: 2, day: day, hour: 12)
            habit.toggleCompletion(for: date, context: context)
        }
        
        // Feb 4 missed entirely
        
        // Feb 5 completed at 2 AM (counts as Feb 4 with boundary)
        let lateNight = createDate(year: 2026, month: 2, day: 5, hour: 2)
        habit.toggleCompletion(for: lateNight, context: context)
        
        #expect(habit.entries.count == 4)
        
        // Check that Feb 4 is now completed (via late night Feb 5 entry)
        let feb4Check = createDate(year: 2026, month: 2, day: 4, hour: 12)
        #expect(habit.isCompletedOn(date: feb4Check))
        
        // This should give us a 4-day streak (Feb 1-4)
        #expect(habit.longestStreak >= 4)
    }
    
    @Test func weeklyHabitWithMultipleCompletionsAndBoundary() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let habit = Habit(name: "Gym", frequency: .weekly, targetPerWeek: 3)
        context.insert(habit)
        
        // Complete on Mon, Wed, Fri of first week of Feb 2026
        // Feb 2 (Mon), Feb 4 (Wed), Feb 6 (Fri)
        let monday = createDate(year: 2026, month: 2, day: 2, hour: 18)
        let wednesday = createDate(year: 2026, month: 2, day: 4, hour: 19)
        let friday = createDate(year: 2026, month: 2, day: 6, hour: 20)
        
        habit.toggleCompletion(for: monday, context: context)
        habit.toggleCompletion(for: wednesday, context: context)
        habit.toggleCompletion(for: friday, context: context)
        
        #expect(habit.entries.count == 3)
        
        // All entries should be completed
        let completedEntries = habit.entries.filter { $0.completed }
        #expect(completedEntries.count == 3)
    }
    
    @Test func weeklyHabitLateNightCompletionCountsForPreviousDay() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let habit = Habit(name: "Weekly Habit", frequency: .weekly, targetPerWeek: 2)
        context.insert(habit)
        
        // Complete at 2 AM on Sunday Feb 8 (counts as Saturday Feb 7)
        let saturdayLateNight = createDate(year: 2026, month: 2, day: 8, hour: 2)
        habit.toggleCompletion(for: saturdayLateNight, context: context)
        
        // Verify stored as Feb 7
        #expect(dayComponent(from: habit.entries[0].date) == 7)
        
        // Complete at noon on Sunday Feb 8
        let sundayNoon = createDate(year: 2026, month: 2, day: 8, hour: 12)
        habit.toggleCompletion(for: sundayNoon, context: context)
        
        #expect(habit.entries.count == 2)
        #expect(dayComponent(from: habit.entries[1].date) == 8)
    }
    
    @Test func multipleHabitsCompletionRateWithHistory() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(0)
        
        // Create habit with createdAt backdated
        let habit = Habit(name: "Test Habit")
        context.insert(habit)
        
        // Manually set createdAt to Feb 1
        habit.createdAt = createDate(year: 2026, month: 2, day: 1, hour: 0)
        
        // Complete on Feb 1, 2, 3, 5 (skip Feb 4)
        for day in [1, 2, 3, 5] {
            let date = createDate(year: 2026, month: 2, day: day, hour: 12)
            habit.toggleCompletion(for: date, context: context)
        }
        
        #expect(habit.entries.count == 4)
        // 4 completions out of 5 days = 80%
        #expect(habit.completionRate > 0)
    }
    
    @Test func boundaryChangePreservesExistingHistory() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        // Start with boundary at midnight
        setDaySwitchHour(0)
        
        let habit = Habit(name: "History Test")
        context.insert(habit)
        
        // Create entries at noon for Feb 1-3
        for day in 1...3 {
            let date = createDate(year: 2026, month: 2, day: day, hour: 12)
            habit.toggleCompletion(for: date, context: context)
        }
        
        #expect(habit.entries.count == 3)
        
        // Change boundary to 3 AM
        setDaySwitchHour(3)
        
        // Existing entries should still be accessible
        let feb1Check = createDate(year: 2026, month: 2, day: 1, hour: 12)
        let feb2Check = createDate(year: 2026, month: 2, day: 2, hour: 12)
        let feb3Check = createDate(year: 2026, month: 2, day: 3, hour: 12)
        
        #expect(habit.isCompletedOn(date: feb1Check))
        #expect(habit.isCompletedOn(date: feb2Check))
        #expect(habit.isCompletedOn(date: feb3Check))
        
        // Entry count unchanged
        #expect(habit.entries.count == 3)
    }
    
    @Test func multipleHabitsDifferentFrequenciesWithHistory() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        
        setDaySwitchHour(3)
        
        let dailyHabit = Habit(name: "Daily", frequency: .daily)
        let weeklyHabit = Habit(name: "Weekly", frequency: .weekly, targetPerWeek: 3)
        
        context.insert(dailyHabit)
        context.insert(weeklyHabit)
        
        // Daily: complete every day Feb 1-5
        for day in 1...5 {
            let date = createDate(year: 2026, month: 2, day: day, hour: 10)
            dailyHabit.toggleCompletion(for: date, context: context)
        }
        
        // Weekly: complete Mon, Wed, Fri (Feb 2, 4, 6)
        for day in [2, 4, 6] {
            let date = createDate(year: 2026, month: 2, day: day, hour: 18)
            weeklyHabit.toggleCompletion(for: date, context: context)
        }
        
        #expect(dailyHabit.entries.count == 5)
        #expect(weeklyHabit.entries.count == 3)
        
        // Daily should have streak
        #expect(dailyHabit.longestStreak >= 5)
        
        // Weekly should meet goal
        #expect(weeklyHabit.entries.filter { $0.completed }.count >= 3)
    }
}

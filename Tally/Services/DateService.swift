//
//  DateService.swift
//  Tally
//

import Foundation
import SwiftUI

/// Handles date calculations with configurable day boundary
/// (e.g., day switches at 3 AM instead of midnight)
struct DateService {
    static let shared = DateService()
    
    /// The hour at which a new day starts (0-6 range recommended)
    /// Stored in UserDefaults as "daySwitchHour"
    static var daySwitchHour: Int {
        get { UserDefaults.standard.integer(forKey: "daySwitchHour") }
        set { UserDefaults.standard.set(newValue, forKey: "daySwitchHour") }
    }
    
    /// Mock time for UI testing. Set via launch argument "-mockTime" with ISO8601 string.
    /// Example: "-mockTime" "2026-02-05T01:30:00"
    static var mockTime: Date? = {
        if let mockTimeString = UserDefaults.standard.string(forKey: "mockTime") {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
            return formatter.date(from: mockTimeString)
        }
        return nil
    }()
    
    /// Returns the current time, or mock time if set for testing
    static func now() -> Date {
        mockTime ?? Date()
    }
    
    private var calendar: Calendar { Calendar.current }
    
    /// Returns the "effective date" considering the day switch hour.
    /// For example, if daySwitchHour is 3, then 2:30 AM on Jan 5th
    /// is considered part of Jan 4th.
    func effectiveDate(for date: Date = Date()) -> Date {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let switchHour = DateService.daySwitchHour
        
        // If date is exactly at midnight, it's a "day marker" (result of startOfDay),
        // not a real timestamp, so don't transform it
        if hour == 0 && minute == 0 && second == 0 {
            return date
        }
        
        if switchHour > 0 && hour < switchHour {
            // Before the switch hour, treat as previous day
            return calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return date
    }
    
    /// Returns the start of the "effective day" for the given date.
    /// This accounts for the day switch hour.
    func startOfEffectiveDay(for date: Date = Date()) -> Date {
        let effectiveDay = effectiveDate(for: date)
        return calendar.startOfDay(for: effectiveDay)
    }
    
    /// Checks if two dates fall on the same "effective day"
    func isSameEffectiveDay(_ date1: Date, _ date2: Date) -> Bool {
        let effective1 = startOfEffectiveDay(for: date1)
        let effective2 = startOfEffectiveDay(for: date2)
        return calendar.isDate(effective1, inSameDayAs: effective2)
    }
    
    /// Checks if the given date is on the current "effective day"
    func isEffectivelyToday(_ date: Date) -> Bool {
        isSameEffectiveDay(date, DateService.now())
    }
    
    /// Returns the start of the effective week for the given date
    func startOfEffectiveWeek(for date: Date = Date()) -> Date {
        let effectiveDay = effectiveDate(for: date)
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: effectiveDay))!
    }
}

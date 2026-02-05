//
//  DateServiceTests.swift
//  TallyTests
//

import Testing
import Foundation
@testable import Tally

@Suite(.serialized)
struct DateServiceTests {
    
    var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }
    let dateService = DateService.shared
    
    // MARK: - Helper Methods
    
    private func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
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
    
    private func hourComponent(from date: Date) -> Int {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal.component(.hour, from: date)
    }
    
    private func setDaySwitchHour(_ hour: Int) {
        UserDefaults.standard.set(hour, forKey: "daySwitchHour")
        UserDefaults.standard.synchronize()
    }
    
    private func resetDaySwitchHour() {
        UserDefaults.standard.removeObject(forKey: "daySwitchHour")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Effective Date Tests
    
    @Test func effectiveDateAtMidnightReturnsUnchanged() {
        setDaySwitchHour(3)
        let midnight = createDate(year: 2026, month: 2, day: 5, hour: 0)
        let result = dateService.effectiveDate(for: midnight)
        
        #expect(dayComponent(from: result) == 5)
    }
    
    @Test func effectiveDateBeforeSwitchHourReturnsPreviousDay() {
        setDaySwitchHour(3)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        let result = dateService.effectiveDate(for: twoAM)
        
        #expect(dayComponent(from: result) == 4)
    }
    
    @Test func effectiveDateAfterSwitchHourReturnsSameDay() {
        setDaySwitchHour(3)
        let fourAM = createDate(year: 2026, month: 2, day: 5, hour: 4)
        let result = dateService.effectiveDate(for: fourAM)
        
        #expect(dayComponent(from: result) == 5)
    }
    
    @Test func effectiveDateWithZeroBoundaryNeverShifts() {
        setDaySwitchHour(0)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        let result = dateService.effectiveDate(for: twoAM)
        
        #expect(dayComponent(from: result) == 5)
    }
    
    // MARK: - Start of Effective Day Tests
    
    @Test func startOfEffectiveDayReturnsCorrectMidnight() {
        setDaySwitchHour(3)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        let result = dateService.startOfEffectiveDay(for: twoAM)
        
        #expect(dayComponent(from: result) == 4)
        #expect(hourComponent(from: result) == 0)
    }
    
    // MARK: - Same Effective Day Tests
    
    @Test func isSameEffectiveDayWithSameTimestamps() {
        setDaySwitchHour(3)
        let date1 = createDate(year: 2026, month: 2, day: 5, hour: 4)
        let date2 = createDate(year: 2026, month: 2, day: 5, hour: 10)
        
        #expect(dateService.isSameEffectiveDay(date1, date2))
    }
    
    @Test func isSameEffectiveDayAcrossMidnight() {
        setDaySwitchHour(3)
        // 11 PM on Feb 4th and 2 AM on Feb 5th should be same effective day (Feb 4th)
        let elevenPM = createDate(year: 2026, month: 2, day: 4, hour: 23)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        
        #expect(dateService.isSameEffectiveDay(elevenPM, twoAM))
    }
    
    @Test func isDifferentEffectiveDayAfterBoundary() {
        setDaySwitchHour(3)
        // 2 AM on Feb 5th (effective Feb 4th) and 4 AM on Feb 5th (effective Feb 5th)
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        let fourAM = createDate(year: 2026, month: 2, day: 5, hour: 4)
        
        #expect(!dateService.isSameEffectiveDay(twoAM, fourAM))
    }
    
    // MARK: - Boundary Change Consistency Tests
    
    @Test func boundaryChangeDoesNotAffectMidnightDates() {
        // Create a midnight date (day marker)
        let midnight = createDate(year: 2026, month: 2, day: 5, hour: 0)
        
        // With boundary at 0 (midnight)
        setDaySwitchHour(0)
        let result1 = dateService.startOfEffectiveDay(for: midnight)
        
        // With boundary at 3 AM
        setDaySwitchHour(3)
        let result2 = dateService.startOfEffectiveDay(for: midnight)
        
        // Both should return Feb 5th midnight (unchanged)
        #expect(dayComponent(from: result1) == 5)
        #expect(dayComponent(from: result2) == 5)
    }
    
    @Test func boundaryChangeAffectsNonMidnightDates() {
        let twoAM = createDate(year: 2026, month: 2, day: 5, hour: 2)
        
        // Verify the input date is correct
        #expect(dayComponent(from: twoAM) == 5)
        #expect(hourComponent(from: twoAM) == 2)
        
        // With boundary at 0 (midnight) - 2 AM is Feb 5th
        setDaySwitchHour(0)
        #expect(DateService.daySwitchHour == 0)
        let result1 = dateService.startOfEffectiveDay(for: twoAM)
        #expect(dayComponent(from: result1) == 5)
        
        // With boundary at 3 AM - 2 AM is Feb 4th (shifted back)
        setDaySwitchHour(3)
        #expect(DateService.daySwitchHour == 3)
        let result2 = dateService.startOfEffectiveDay(for: twoAM)
        #expect(dayComponent(from: result2) == 4)
    }
}

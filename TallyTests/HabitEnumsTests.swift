//
//  HabitEnumsTests.swift
//  TallyTests
//

import Testing
import Foundation
@testable import Tally

@Suite
struct HabitFrequencyTests {
    
    @Test func rawValuesAndDescriptions() {
        #expect(HabitFrequency.daily.rawValue == "Daily")
        #expect(HabitFrequency.weekly.rawValue == "Weekly")
        #expect(HabitFrequency.daily.description == "Daily")
        #expect(HabitFrequency.weekly.description == "Weekly")
    }
    
    @Test func initFromRawValue() {
        #expect(HabitFrequency(rawValue: "Daily") == .daily)
        #expect(HabitFrequency(rawValue: "Weekly") == .weekly)
        #expect(HabitFrequency(rawValue: "Invalid") == nil)
    }
    
    @Test func codableEncodeDecode() throws {
        let original = HabitFrequency.weekly
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HabitFrequency.self, from: data)
        #expect(decoded == original)
    }
}

@Suite
struct ReminderTypeTests {
    
    @Test func rawValuesAndDescriptions() {
        #expect(ReminderType.single.rawValue == "Single")
        #expect(ReminderType.periodic.rawValue == "Periodic")
        #expect(ReminderType.single.description == "Once a day")
        #expect(ReminderType.periodic.description == "Regular intervals")
    }
    
    @Test func initFromRawValue() {
        #expect(ReminderType(rawValue: "Single") == .single)
        #expect(ReminderType(rawValue: "Periodic") == .periodic)
        #expect(ReminderType(rawValue: "Invalid") == nil)
    }
    
    @Test func codableEncodeDecode() throws {
        let original = ReminderType.periodic
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReminderType.self, from: data)
        #expect(decoded == original)
    }
}

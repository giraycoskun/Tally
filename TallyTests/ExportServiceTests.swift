//
//  ExportServiceTests.swift
//  TallyTests
//

import Testing
import Foundation
@testable import Tally

@Suite
struct ExportServiceTests {
    
    let exportService = ExportService.shared
    
    // MARK: - Helper Methods
    
    private func createSampleExportableHabit(
        id: String = UUID().uuidString,
        name: String = "Test Habit",
        createdAt: Date = Date(),
        entries: [ExportableHabitEntry] = []
    ) -> ExportableHabit {
        ExportableHabit(
            id: id,
            name: name,
            icon: "checkmark.circle",
            colorHex: "#4CAF50",
            createdAt: createdAt,
            frequency: "Daily",
            targetPerWeek: 7,
            reminderEnabled: false,
            reminderType: "Single",
            reminderTime: nil,
            periodicStartTime: nil,
            periodicEndTime: nil,
            periodicIntervalHours: 2,
            entries: entries
        )
    }
    
    private func createSampleEntry(completed: Bool = true) -> ExportableHabitEntry {
        ExportableHabitEntry(id: UUID().uuidString, date: Date(), completed: completed)
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    @Test func encodeAndDecodeEmptyHabits() throws {
        let exportData = ExportData(
            exportedAt: Date(),
            appVersion: "1.0.0",
            habits: []
        )
        
        let data = try exportService.encodeToJSON(exportData: exportData)
        let decoded = try exportService.decodeFromJSON(data: data)
        
        #expect(decoded.habits.isEmpty)
        #expect(decoded.appVersion == "1.0.0")
    }
    
    @Test func encodeAndDecodeHabitWithEntries() throws {
        let entry = createSampleEntry(completed: true)
        let habit = createSampleExportableHabit(name: "Exercise", entries: [entry])
        
        let exportData = ExportData(
            exportedAt: Date(),
            appVersion: "1.0.0",
            habits: [habit]
        )
        
        let encoded = try exportService.encodeToJSON(exportData: exportData)
        let decoded = try exportService.decodeFromJSON(data: encoded)
        
        #expect(decoded.habits.count == 1)
        #expect(decoded.habits[0].name == "Exercise")
        #expect(decoded.habits[0].entries.count == 1)
        #expect(decoded.habits[0].entries[0].completed == true)
    }
    
    @Test func encodeDatesInISO8601Format() throws {
        let fixedDate = ISO8601DateFormatter().date(from: "2026-02-07T12:00:00Z")!
        let habit = createSampleExportableHabit(createdAt: fixedDate)
        
        let exportData = ExportData(
            exportedAt: fixedDate,
            appVersion: "1.0.0",
            habits: [habit]
        )
        
        let data = try exportService.encodeToJSON(exportData: exportData)
        let jsonString = String(data: data, encoding: .utf8)!
        
        #expect(jsonString.contains("2026-02-07T12:00:00Z"))
    }
    
    @Test func encodeMultipleHabits() throws {
        let habits = [
            createSampleExportableHabit(name: "Habit 1"),
            createSampleExportableHabit(name: "Habit 2"),
            createSampleExportableHabit(name: "Habit 3")
        ]
        
        let exportData = ExportData(
            exportedAt: Date(),
            appVersion: "1.0.0",
            habits: habits
        )
        
        let encoded = try exportService.encodeToJSON(exportData: exportData)
        let decoded = try exportService.decodeFromJSON(data: encoded)
        
        #expect(decoded.habits.count == 3)
    }
    
    @Test func handleSpecialCharactersInName() throws {
        let habit = createSampleExportableHabit(name: "Exercise & Yoga \"Daily\" <routine>")
        
        let exportData = ExportData(
            exportedAt: Date(),
            appVersion: "1.0.0",
            habits: [habit]
        )
        
        let encoded = try exportService.encodeToJSON(exportData: exportData)
        let decoded = try exportService.decodeFromJSON(data: encoded)
        
        #expect(decoded.habits[0].name == "Exercise & Yoga \"Daily\" <routine>")
    }
    
    @Test func handleUnicodeCharacters() throws {
        let habit = createSampleExportableHabit(name: "运动 🏃‍♂️ Übung")
        
        let exportData = ExportData(
            exportedAt: Date(),
            appVersion: "1.0.0",
            habits: [habit]
        )
        
        let encoded = try exportService.encodeToJSON(exportData: exportData)
        let decoded = try exportService.decodeFromJSON(data: encoded)
        
        #expect(decoded.habits[0].name == "运动 🏃‍♂️ Übung")
    }
    
    // MARK: - Error Handling Tests
    
    @Test func decodeInvalidJSONThrows() {
        let invalidJSON = Data("not valid json".utf8)
        #expect(throws: Error.self) {
            try exportService.decodeFromJSON(data: invalidJSON)
        }
    }
    
    @Test func decodeEmptyDataThrows() {
        #expect(throws: Error.self) {
            try exportService.decodeFromJSON(data: Data())
        }
    }
    
    // MARK: - Equatable Tests
    
    @Test func exportDataEquatable() {
        let date = Date(timeIntervalSince1970: 1000)
        let data1 = ExportData(exportedAt: date, appVersion: "1.0", habits: [])
        let data2 = ExportData(exportedAt: date, appVersion: "1.0", habits: [])
        let data3 = ExportData(exportedAt: date, appVersion: "2.0", habits: [])
        
        #expect(data1 == data2)
        #expect(data1 != data3)
    }
}

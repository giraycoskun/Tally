//
//  ExportService.swift
//  Tally
//

import Foundation

struct ExportableHabitEntry: Codable, Equatable {
    let id: String
    let date: Date
    let completed: Bool
}

struct ExportableHabit: Codable, Equatable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let createdAt: Date
    let frequency: String
    let targetPerWeek: Int
    let reminderEnabled: Bool
    let reminderType: String
    let reminderTime: Date?
    let periodicStartTime: Date?
    let periodicEndTime: Date?
    let periodicIntervalHours: Int
    let entries: [ExportableHabitEntry]
}

struct ExportData: Codable, Equatable {
    let exportedAt: Date
    let appVersion: String
    let habits: [ExportableHabit]
}

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    func convertToExportable(habit: Habit) -> ExportableHabit {
        ExportableHabit(
            id: habit.id.uuidString,
            name: habit.name,
            icon: habit.icon,
            colorHex: habit.colorHex,
            createdAt: habit.createdAt,
            frequency: habit.frequencyRaw,
            targetPerWeek: habit.targetPerWeek,
            reminderEnabled: habit.reminderEnabled,
            reminderType: habit.reminderTypeRaw,
            reminderTime: habit.reminderTime,
            periodicStartTime: habit.periodicStartTime,
            periodicEndTime: habit.periodicEndTime,
            periodicIntervalHours: habit.periodicIntervalHours,
            entries: habit.entries.map { entry in
                ExportableHabitEntry(
                    id: entry.id.uuidString,
                    date: entry.date,
                    completed: entry.completed
                )
            }
        )
    }
    
    func encodeToJSON(exportData: ExportData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }
    
    func decodeFromJSON(data: Data) throws -> ExportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportData.self, from: data)
    }
    
    func exportToJSON(habits: [Habit]) throws -> Data {
        let exportableHabits = habits.map { convertToExportable(habit: $0) }
        
        let exportData = ExportData(
            exportedAt: Date(),
            appVersion: AppVersion.version,
            habits: exportableHabits
        )
        
        return try encodeToJSON(exportData: exportData)
    }
    
    func generateExportURL(habits: [Habit]) throws -> URL {
        let data = try exportToJSON(habits: habits)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "tally-export-\(dateString).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try data.write(to: tempURL)
        
        return tempURL
    }
}

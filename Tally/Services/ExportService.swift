//
//  ExportService.swift
//  Tally
//

import Foundation

struct ExportableHabitEntry: Codable, Equatable {
    let id: String
    let date: Date
    let completed: Bool
    let count: Int

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case completed
        case count
    }

    init(id: String, date: Date, completed: Bool, count: Int) {
        self.id = id
        self.date = date
        self.completed = completed
        self.count = count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        completed = try container.decode(Bool.self, forKey: .completed)
        count = try container.decodeIfPresent(Int.self, forKey: .count) ?? (completed ? 1 : 0)
    }
}

struct ExportableHabit: Codable, Equatable {
    let id: String
    let name: String
    let icon: String
    let colorHex: String
    let createdAt: Date
    let frequency: String
    let targetPerWeek: Int
    let dailyTarget: Int
    let sortOrder: Int
    let reminderEnabled: Bool
    let reminderType: String
    let reminderTime: Date?
    let reminderTimes: [Date]
    let periodicStartTime: Date?
    let periodicEndTime: Date?
    let periodicIntervalHours: Int
    let entries: [ExportableHabitEntry]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case colorHex
        case createdAt
        case frequency
        case targetPerWeek
        case dailyTarget
        case sortOrder
        case reminderEnabled
        case reminderType
        case reminderTime
        case reminderTimes
        case periodicStartTime
        case periodicEndTime
        case periodicIntervalHours
        case entries
    }
    
    init(
        id: String,
        name: String,
        icon: String,
        colorHex: String,
        createdAt: Date,
        frequency: String,
        targetPerWeek: Int,
        dailyTarget: Int,
        sortOrder: Int,
        reminderEnabled: Bool,
        reminderType: String,
        reminderTime: Date?,
        reminderTimes: [Date],
        periodicStartTime: Date?,
        periodicEndTime: Date?,
        periodicIntervalHours: Int,
        entries: [ExportableHabitEntry]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.frequency = frequency
        self.targetPerWeek = targetPerWeek
        self.dailyTarget = dailyTarget
        self.sortOrder = sortOrder
        self.reminderEnabled = reminderEnabled
        self.reminderType = reminderType
        self.reminderTime = reminderTime
        self.reminderTimes = reminderTimes
        self.periodicStartTime = periodicStartTime
        self.periodicEndTime = periodicEndTime
        self.periodicIntervalHours = periodicIntervalHours
        self.entries = entries
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        frequency = try container.decode(String.self, forKey: .frequency)
        targetPerWeek = try container.decode(Int.self, forKey: .targetPerWeek)
        dailyTarget = try container.decodeIfPresent(Int.self, forKey: .dailyTarget) ?? 1
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        reminderEnabled = try container.decode(Bool.self, forKey: .reminderEnabled)
        reminderType = try container.decode(String.self, forKey: .reminderType)
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)
        reminderTimes = try container.decodeIfPresent([Date].self, forKey: .reminderTimes) ?? []
        periodicStartTime = try container.decodeIfPresent(Date.self, forKey: .periodicStartTime)
        periodicEndTime = try container.decodeIfPresent(Date.self, forKey: .periodicEndTime)
        periodicIntervalHours = try container.decode(Int.self, forKey: .periodicIntervalHours)
        entries = try container.decode([ExportableHabitEntry].self, forKey: .entries)
    }
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
            dailyTarget: habit.dailyTarget,
            sortOrder: habit.sortOrder,
            reminderEnabled: habit.reminderEnabled,
            reminderType: habit.reminderTypeRaw,
            reminderTime: habit.reminderTime,
            reminderTimes: habit.reminderTimes,
            periodicStartTime: habit.periodicStartTime,
            periodicEndTime: habit.periodicEndTime,
            periodicIntervalHours: habit.periodicIntervalHours,
            entries: habit.entries.map { entry in
                ExportableHabitEntry(
                    id: entry.id.uuidString,
                    date: entry.date,
                    completed: entry.completed,
                    count: entry.count
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

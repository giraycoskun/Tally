//
//  TallyMigrationPlan.swift
//  Tally
//

import SwiftData
import Foundation

enum TallySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
    static var models: [any PersistentModel.Type] { [HabitV1.self, HabitEntryV1.self] }
    
    @Model
    final class HabitV1 {
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
        var reminderTypeRaw: String
        var periodicStartTime: Date?
        var periodicEndTime: Date?
        var periodicIntervalHours: Int
        
        @Relationship(deleteRule: .cascade, inverse: \HabitEntryV1.habit)
        var entries: [HabitEntryV1] = []
        
        init(
            name: String,
            icon: String = "checkmark.circle",
            colorHex: String = "#4CAF50",
            reminderTime: Date? = nil,
            reminderTimes: [Date] = [],
            reminderEnabled: Bool = false,
            frequencyRaw: String = HabitFrequency.daily.rawValue,
            targetPerWeek: Int = 7,
            reminderTypeRaw: String = ReminderType.single.rawValue,
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
            self.frequencyRaw = frequencyRaw
            self.targetPerWeek = targetPerWeek
            self.reminderTypeRaw = reminderTypeRaw
            self.periodicStartTime = periodicStartTime
            self.periodicEndTime = periodicEndTime
            self.periodicIntervalHours = periodicIntervalHours
        }
    }
    
    @Model
    final class HabitEntryV1 {
        var id: UUID
        var date: Date
        var completed: Bool
        var habit: HabitV1?
        
        init(date: Date, completed: Bool = false) {
            self.id = UUID()
            self.date = date
            self.completed = completed
        }
    }
}

enum TallySchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Habit.self, HabitEntry.self] }
}

enum TallyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [TallySchemaV1.self, TallySchemaV2.self] }
    static var stages: [MigrationStage] { [migrateV1toV2] }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: TallySchemaV1.self,
        toVersion: TallySchemaV2.self,
        willMigrate: { _ in },
        didMigrate: { context in
            let habits = (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
            var order = 0
            for habit in habits {
                if habit.dailyTarget <= 0 {
                    habit.dailyTarget = 1
                }
                habit.sortOrder = order
                order += 1
            }
            
            let entries = (try? context.fetch(FetchDescriptor<HabitEntry>())) ?? []
            for entry in entries {
                if entry.count <= 0 {
                    entry.count = entry.completed ? 1 : 0
                }
            }
            
            try? context.save()
        }
    )
}

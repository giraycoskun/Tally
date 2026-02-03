//
//  HabitEntry.swift
//  Tally
//

import Foundation
import SwiftData

@Model
final class HabitEntry {
    var id: UUID
    var date: Date
    var completed: Bool
    var habit: Habit?
    
    init(date: Date, completed: Bool = false) {
        self.id = UUID()
        self.date = date
        self.completed = completed
    }
}

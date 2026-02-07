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
    var count: Int
    var habit: Habit?
    
    init(date: Date, completed: Bool = false, count: Int = 0) {
        self.id = UUID()
        self.date = date
        self.completed = completed
        self.count = count
    }
}

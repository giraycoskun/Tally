//
//  ContributionGridView.swift
//  Tally
//

import SwiftUI

struct ContributionGridView: View {
    let habit: Habit
    let onDateTap: (Date) -> Void
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3
    
    init(habit: Habit, onDateTap: @escaping (Date) -> Void = { _ in }) {
        self.habit = habit
        self.onDateTap = onDateTap
    }
    
    private func weeksToShow(for width: CGFloat) -> Int {
        let availableWidth = width
        let cellWithSpacing = cellSize + spacing
        let weeks = Int(availableWidth / cellWithSpacing)
        return max(4, weeks)
    }
    
    private func dates(weeks: Int) -> [[Date]] {
        let _ = daySwitchHour
        let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
        let startOfThisWeek = startOfWeek(for: today)
        
        guard let startDate = calendar.date(byAdding: .day, value: -(weeks - 1) * 7, to: startOfThisWeek) else {
            return []
        }
        
        var weekColumns: [[Date]] = []
        var currentDate = startDate
        
        for _ in 0..<weeks {
            var week: [Date] = []
            for _ in 0..<7 {
                week.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            weekColumns.append(week)
        }
        
        return weekColumns
    }

    private func isWeeklyGoalMet(for week: [Date]) -> Bool {
        guard habit.frequency == .weekly, let weekStart = week.first, let weekEnd = week.last else {
            return false
        }
        let calendar = Calendar.current
        let completionsInWeek = habit.entries.filter { entry in
            guard entry.completed else { return false }
            let entryDay = calendar.startOfDay(for: entry.date)
            return entryDay >= weekStart && entryDay <= weekEnd
        }.count
        return completionsInWeek >= habit.targetPerWeek
    }
    
    private func startOfWeek(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let shift = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -shift, to: date)!
    }
    
    var body: some View {
        GeometryReader { geometry in
            let weeks = weeksToShow(for: geometry.size.width)
            let dateGrid = dates(weeks: weeks)
            
            HStack(spacing: spacing) {
                ForEach(Array(dateGrid.enumerated()), id: \.offset) { _, week in
                    let weekGoalMet = isWeeklyGoalMet(for: week)
                    VStack(spacing: spacing) {
                        ForEach(week, id: \.self) { date in
                            ContributionCell(
                                date: date,
                                isCompleted: habit.isCompletedOn(date: date),
                                color: habit.color,
                                size: cellSize,
                                highlightWeek: weekGoalMet
                            )
                            .onTapGesture {
                                onDateTap(date)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(weekGoalMet ? habit.color.opacity(0.18) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(weekGoalMet ? habit.color : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
        .frame(height: 7 * cellSize + 6 * spacing)
    }
}

struct ContributionCell: View {
    let date: Date
    let isCompleted: Bool
    let color: Color
    let size: CGFloat
    let highlightWeek: Bool
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private var isToday: Bool {
        let _ = daySwitchHour
        return DateService.shared.isEffectivelyToday(date)
    }
    
    private var isFuture: Bool {
        let _ = daySwitchHour
        return date > DateService.shared.startOfEffectiveDay(for: DateService.now())
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    private var borderColor: Color {
        if isToday {
            return color
        }
        if highlightWeek && !isCompleted && !isFuture {
            return color.opacity(0.85)
        }
        return Color.clear
    }

    private var borderWidth: CGFloat {
        if isToday {
            return 2
        }
        if highlightWeek && !isCompleted && !isFuture {
            return 1
        }
        return 0
    }
    
    private var cellColor: Color {
        if isFuture {
            return AppTheme.surfaceBackground
        } else if isCompleted {
            return color
        } else {
            return AppTheme.darkPurple
        }
    }
}

#Preview {
    ContributionGridView(habit: Habit(name: "Exercise"))
        .padding()
}

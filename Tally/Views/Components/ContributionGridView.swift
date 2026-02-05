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
                    VStack(spacing: spacing) {
                        ForEach(week, id: \.self) { date in
                            ContributionCell(
                                date: date,
                                isCompleted: habit.isCompletedOn(date: date),
                                color: habit.color,
                                size: cellSize
                            )
                            .onTapGesture {
                                onDateTap(date)
                            }
                        }
                    }
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
                    .stroke(isToday ? color : Color.clear, lineWidth: 2)
            )
    }
    
    private var cellColor: Color {
        if isFuture {
            return AppTheme.darkPurple
        } else if isCompleted {
            return color
        } else {
            return AppTheme.mediumPurple
        }
    }
}

#Preview {
    ContributionGridView(habit: Habit(name: "Exercise"))
        .padding()
}

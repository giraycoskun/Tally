//
//  ContributionGridView.swift
//  Tally
//

import SwiftUI

struct ContributionGridView: View {
    let habit: Habit
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3
    private let dayLabelWidth: CGFloat = 18
    
    init(habit: Habit, onDateTap: @escaping (Date) -> Void = { _ in }) {
        self.habit = habit
        self.onDateTap = onDateTap
    }
    
    private func weeksToShow(for width: CGFloat) -> Int {
        let availableWidth = width - dayLabelWidth - 8
        let cellWithSpacing = cellSize + spacing
        let weeks = Int(availableWidth / cellWithSpacing)
        return max(4, weeks)
    }
    
    private func dates(weeks: Int) -> [[Date]] {
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)
        
        var allDates: [Date] = []
        let totalDays = weeks * 7 + todayWeekday - 1
        
        for dayOffset in (0..<totalDays).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                allDates.append(date)
            }
        }
        
        var weekColumns: [[Date]] = []
        var currentWeek: [Date] = []
        
        for date in allDates {
            currentWeek.append(date)
            if calendar.component(.weekday, from: date) == 7 {
                weekColumns.append(currentWeek)
                currentWeek = []
            }
        }
        
        if !currentWeek.isEmpty {
            weekColumns.append(currentWeek)
        }
        
        return weekColumns
    }
    
    private func monthLabels(for dateGrid: [[Date]]) -> [(String, Int)] {
        var labels: [(String, Int)] = []
        var lastMonth = -1
        
        for (weekIndex, week) in dateGrid.enumerated() {
            if let firstDate = week.first {
                let month = calendar.component(.month, from: firstDate)
                if month != lastMonth {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM"
                    labels.append((formatter.string(from: firstDate), weekIndex))
                    lastMonth = month
                }
            }
        }
        
        return labels
    }
    
    var body: some View {
        GeometryReader { geometry in
            let weeks = weeksToShow(for: geometry.size.width)
            let dateGrid = dates(weeks: weeks)
            let labels = monthLabels(for: dateGrid)
            
            VStack(alignment: .leading, spacing: 4) {
                // Month labels
                HStack(spacing: 0) {
                    Color.clear.frame(width: dayLabelWidth)
                    
                    ForEach(0..<weeks + 1, id: \.self) { weekIndex in
                        if let label = labels.first(where: { $0.1 == weekIndex }) {
                            Text(label.0)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: cellSize + spacing, alignment: .leading)
                        } else {
                            Color.clear
                                .frame(width: cellSize + spacing)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                HStack(alignment: .top, spacing: 0) {
                    // Day labels
                    VStack(spacing: spacing) {
                        ForEach(["", "M", "", "W", "", "F", ""], id: \.self) { day in
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: dayLabelWidth, height: cellSize)
                        }
                    }
                    
                    // Grid
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
                    
                    Spacer(minLength: 0)
                }
                
                // Legend
                HStack(spacing: 4) {
                    Spacer()
                    
                    Text("Less")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(intensity == 0 ? AppTheme.mediumPurple : habit.color.opacity(intensity))
                            .frame(width: cellSize, height: cellSize)
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .frame(height: 7 * cellSize + 6 * spacing + 40)
    }
}

struct ContributionCell: View {
    let date: Date
    let isCompleted: Bool
    let color: Color
    let size: CGFloat
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        date > Date()
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

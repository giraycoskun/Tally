//
//  StatisticsView.swift
//  Tally
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var habits: [Habit]
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private var currentTheme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    private var totalCompletions: Int {
        let _ = daySwitchHour
        return habits.flatMap { $0.entries }.filter { $0.completed }.count
    }
    
    private var averageCompletionRate: Double {
        let _ = daySwitchHour
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.completionRate } / Double(habits.count)
    }
    
    private var bestStreak: Int {
        let _ = daySwitchHour
        return habits.map { $0.longestStreak }.max() ?? 0
    }
    
    private var habitsCompletedToday: Int {
        let _ = daySwitchHour
        return habits.filter { $0.isCompletedOn(date: DateService.now()) }.count
    }

    private var totalWeeklyTarget: Int {
        let _ = daySwitchHour
        return habits.reduce(0) { total, habit in
            total + (habit.frequency == .daily ? 7 : habit.targetPerWeek)
        }
    }

    private var weeklyCompletionsTotal: Int {
        weeklyData.reduce(0) { $0 + $1.count }
    }

    private var weeklyGoalRatioText: String {
        guard totalWeeklyTarget > 0 else { return "Ratio: --" }
        let ratio = Double(weeklyCompletionsTotal) / Double(totalWeeklyTarget)
        return String(format: "Ratio: %.0f%%", min(ratio, 1.0) * 100)
    }

    private var consistencyLast30Days: Double {
        let _ = daySwitchHour
        let calendar = Calendar.current
        let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
        var completedDays = 0
        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            if habits.contains(where: { $0.isCompletedOn(date: date) }) {
                completedDays += 1
            }
        }
        return Double(completedDays) / 30.0
    }

    private var fourWeekAverageRatioText: String {
        guard totalWeeklyTarget > 0 else { return "4W Avg: --" }
        let calendar = Calendar.current
        let startOfThisWeek = DateService.shared.startOfEffectiveWeek(for: DateService.now())
        var ratios: [Double] = []
        for weekOffset in 0..<4 {
            guard let weekStart = calendar.date(byAdding: .day, value: -7 * weekOffset, to: startOfThisWeek) else { continue }
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let completions = habits.flatMap { $0.entries }.filter { entry in
                guard entry.completed else { return false }
                let entryDay = calendar.startOfDay(for: entry.date)
                return entryDay >= weekStart && entryDay <= weekEnd
            }.count
            ratios.append(Double(completions) / Double(totalWeeklyTarget))
        }
        guard !ratios.isEmpty else { return "4W Avg: --" }
        let avg = ratios.reduce(0, +) / Double(ratios.count)
        return String(format: "4W Avg: %.0f%%", min(avg, 1.0) * 100)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.surfaceBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Overview Cards
                        overviewSection
                        
                        // Weekly Chart
                        weeklyChartSection
                        
                        // Habit Rankings
                        habitRankingsSection
                        
                        // Calendar Heatmap
                        calendarSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(currentTheme.darkColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
    
    private var overviewSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            OverviewCard(
                title: "Today",
                value: "\(habitsCompletedToday)/\(habits.count)",
                icon: "calendar",
                color: .blue
            )
            
            OverviewCard(
                title: "Total Completions",
                value: "\(totalCompletions)",
                icon: "checkmark.seal.fill",
                color: .green
            )
            
            OverviewCard(
                title: "Avg. Completion",
                value: "\(Int(averageCompletionRate))%",
                icon: "chart.pie.fill",
                color: .purple
            )
            
            OverviewCard(
                title: "4W Avg",
                value: fourWeekAverageRatioText.replacingOccurrences(of: "4W Avg: ", with: ""),
                icon: "waveform.path.ecg",
                color: .purple
            )
            
            OverviewCard(
                title: "Best Streak",
                value: "\(bestStreak) days",
                icon: "flame.fill",
                color: .orange
            )

            OverviewCard(
                title: "Consistency 30d",
                value: "\(Int(consistencyLast30Days * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .teal
            )
        }
    }
    
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 8) {
                Text("Goal: \(totalWeeklyTarget)x/week")
                Text("•")
                Text("Achieved: \(weeklyCompletionsTotal)/\(totalWeeklyTarget)")
                Text("•")
                Text(weeklyGoalRatioText)
            }
            .font(.caption)
            .foregroundColor(AppTheme.lightPurple)
            
            Chart {
                let targetPerDay = totalWeeklyTarget == 0 ? 0.0 : Double(totalWeeklyTarget) / 7.0

                ForEach(weeklyData, id: \.date) { data in
                    AreaMark(
                        x: .value("Day", data.date),
                        y: .value("Completions", data.count)
                    )
                    .foregroundStyle(Color.green.opacity(0.2))

                    LineMark(
                        x: .value("Day", data.date),
                        y: .value("Completions", data.count)
                    )
                    .foregroundStyle(Color.green)
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Day", data.date),
                        y: .value("Completions", data.count)
                    )
                    .foregroundStyle(Color.green)
                }

                if totalWeeklyTarget > 0 {
                    RuleMark(y: .value("Target", targetPerDay))
                        .foregroundStyle(AppTheme.lightPurple)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal")
                                .font(.caption2)
                                .foregroundColor(AppTheme.lightPurple)
                        }
                }
            }
            .frame(height: 200)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .chartXAxis {
                AxisMarks(values: weeklyData.map(\.date)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            let weekdayIndex = Calendar.current.component(.weekday, from: date) - 1
                            let label = (0..<weekdaysShort.count).contains(weekdayIndex) ? weekdaysShort[weekdayIndex] : ""
                            Text(label)
                        }
                    }
                }
            }
        }
    }
    
    private var weeklyData: [(date: Date, label: String, count: Int)] {
        let _ = daySwitchHour
        let calendar = Calendar.current
        let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
        let weekdays = weekdaysShort
        
        var data: [(date: Date, label: String, count: Int)] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let completions = habits.filter { $0.isCompletedOn(date: date) }.count
            data.append((date: date, label: weekdays[weekdayIndex], count: completions))
        }
        
        return data
    }

    private var weekdaysShort: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    private var habitRankingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit Rankings")
                .font(.headline)
                .foregroundColor(.white)
            
            if habits.isEmpty {
                Text("No habits yet")
                    .foregroundColor(AppTheme.lightPurple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(habits.sorted { $0.completionRate > $1.completionRate }) { habit in
                        HabitRankRow(habit: habit)
                    }
                }
            }
        }
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            OverallActivityGrid(habits: habits)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.lightPurple)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

struct HabitRankRow: View {
    let habit: Habit
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private var completionRate: Double {
        let _ = daySwitchHour
        return habit.completionRate
    }
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .foregroundColor(habit.color)
                .frame(width: 30)
            
            Text(habit.name)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(Int(completionRate))%")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(rateColor)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.mediumPurple)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(habit.color)
                        .frame(width: geo.size.width * (completionRate / 100))
                }
            }
            .frame(width: 60, height: 8)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(8)
    }
    
    private var rateColor: Color {
        if completionRate >= 70 {
            return .green
        } else if completionRate >= 40 {
            return .orange
        } else {
            return .red
        }
    }
}

struct OverallActivityGrid: View {
    let habits: [Habit]
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3
    
    private var effectiveToday: Date {
        let _ = daySwitchHour
        return DateService.shared.startOfEffectiveDay(for: DateService.now())
    }
    
    private func completionIntensity(for date: Date) -> Double {
        let _ = daySwitchHour
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.isCompletedOn(date: date) }.count
        return Double(completed) / Double(habits.count)
    }
    
    private func weeksToShow(for width: CGFloat) -> Int {
        let cellWithSpacing = cellSize + spacing
        let weeks = Int(width / cellWithSpacing)
        return max(4, weeks)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let weeks = weeksToShow(for: geometry.size.width)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: spacing) {
                    ForEach(0..<weeks, id: \.self) { weekOffset in
                        VStack(spacing: spacing) {
                            ForEach(0..<7, id: \.self) { dayOffset in
                                let totalDaysBack = (weeks - 1 - weekOffset) * 7 + (6 - dayOffset)
                                let date = calendar.date(byAdding: .day, value: -totalDaysBack, to: effectiveToday)!
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cellColor(for: date))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                HStack(spacing: 4) {
                    Spacer()
                    
                    Text("Less")
                        .font(.caption2)
                        .foregroundColor(AppTheme.lightPurple)
                    
                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(intensity == 0 ? AppTheme.mediumPurple : Color.green.opacity(intensity))
                            .frame(width: cellSize, height: cellSize)
                    }
                    
                    Text("More")
                        .font(.caption2)
                        .foregroundColor(AppTheme.lightPurple)
                }
                .padding(.top, 4)
            }
        }
        .frame(height: 7 * cellSize + 6 * spacing + 30)
    }
    
    private func cellColor(for date: Date) -> Color {
        if date > effectiveToday {
            return AppTheme.surfaceBackground
        }
        
        let intensity = completionIntensity(for: date)
        if intensity == 0 {
            return AppTheme.mediumPurple
        }
        return Color.green.opacity(intensity)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

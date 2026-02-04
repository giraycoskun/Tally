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
    
    private var currentTheme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    private var totalCompletions: Int {
        habits.flatMap { $0.entries }.filter { $0.completed }.count
    }
    
    private var averageCompletionRate: Double {
        guard !habits.isEmpty else { return 0 }
        return habits.reduce(0) { $0 + $1.completionRate } / Double(habits.count)
    }
    
    private var bestStreak: Int {
        habits.map { $0.longestStreak }.max() ?? 0
    }
    
    private var habitsCompletedToday: Int {
        habits.filter { $0.isCompletedOn(date: Date()) }.count
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
                title: "Best Streak",
                value: "\(bestStreak) days",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart {
                ForEach(weeklyData, id: \.day) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Completions", data.count)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var weeklyData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let today = Date()
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        var data: [(day: String, count: Int)] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let completions = habits.filter { $0.isCompletedOn(date: date) }.count
            data.append((day: weekdays[weekdayIndex], count: completions))
        }
        
        return data
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
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .foregroundColor(habit.color)
                .frame(width: 30)
            
            Text(habit.name)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(Int(habit.completionRate))%")
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
                        .frame(width: geo.size.width * (habit.completionRate / 100))
                }
            }
            .frame(width: 60, height: 8)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(8)
    }
    
    private var rateColor: Color {
        if habit.completionRate >= 70 {
            return .green
        } else if habit.completionRate >= 40 {
            return .orange
        } else {
            return .red
        }
    }
}

struct OverallActivityGrid: View {
    let habits: [Habit]
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 3
    
    private func completionIntensity(for date: Date) -> Double {
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
                                let date = calendar.date(byAdding: .day, value: -totalDaysBack, to: Date())!
                                
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
        if date > Date() {
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

//
//  HabitDetailView.swift
//  Tally
//

import SwiftUI
import SwiftData
import Charts

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    
    private var currentTheme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        ZStack {
            AppTheme.surfaceBackground
                .ignoresSafeArea()
            
            ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Stats Cards
                statsSection

                // Behavior Curve
                behaviorCurveSection
                
                // Reminder Settings
                reminderSection
                
                // Full Contribution Grid
                gridSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(currentTheme.darkColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit)
        }
        .alert("Delete Habit?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(habit)
                dismiss()
            }
        } message: {
            Text("This will permanently delete \"\(habit.name)\" and all its history.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(habit.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: habit.icon)
                    .font(.system(size: 36))
                    .foregroundColor(habit.color)
            }
            
            Text(habit.frequencyLabel)
                .font(.caption)
                .foregroundColor(AppTheme.lightPurple)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AppTheme.cardBackground)
                .cornerRadius(8)

            Text("Created \(habit.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(AppTheme.lightPurple)
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    habit.toggleCompletion(for: DateService.now(), context: modelContext)
                    try? modelContext.save()
                }
            } label: {
                let isCompleted = habit.isCompletedOn(date: DateService.now())
                HStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    Text(isCompleted ? "Completed Today" : "Mark as Complete")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isCompleted ? habit.color : Color.gray)
                .cornerRadius(25)
            }
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            // Weekly progress for weekly habits
            if habit.frequency == .weekly {
                VStack(spacing: 8) {
                    HStack {
                        Text("This Week")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.lightPurple)
                        Spacer()
                        Text("\(habit.completionsThisWeek)/\(habit.targetPerWeek)")
                            .font(.headline)
                            .foregroundColor(habit.isWeeklyGoalMet ? .green : .white)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.mediumPurple)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(habit.isWeeklyGoalMet ? Color.green : habit.color)
                                .frame(width: geo.size.width * habit.weeklyProgress)
                        }
                    }
                    .frame(height: 12)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: habit.frequency == .daily ? "Day Streak" : "Week Streak",
                    value: "\(habit.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Longest Streak",
                    value: "\(habit.longestStreak)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Completion Rate",
                    value: "\(Int(habit.completionRate))%",
                    icon: "chart.pie.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Total Completions",
                    value: "\(habit.entries.filter { $0.completed }.count)",
                    icon: "checkmark.seal.fill",
                    color: .green
                )

                StatCard(
                    title: "Last 7 Days",
                    value: "\(last7DaysCompletions)/\(last7DaysExpected)",
                    icon: "calendar.badge.checkmark",
                    color: habit.color
                )
                
                StatCard(
                    title: "Last 4 Weeks",
                    value: "\(last4WeeksCompletions)/\(last4WeeksExpected)",
                    icon: "calendar",
                    color: habit.color
                )
            }
        }
    }

    private var behaviorCurveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Behavior Curve")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Text("Forming")
                Spacer()
                Text("Strengthening")
                Spacer()
                Text("Automatic")
            }
            .font(.caption2)
            .foregroundColor(AppTheme.lightPurple)

            let actualHistory = actualStrengthHistory()
            let currentStrength = actualHistory.last?.strength ?? 0
            
            // Always show at least 100 days on x-axis
            let minDisplayDays = 100
            let startDay = max(0, daysSinceCreated - minDisplayDays)
            let endDay = max(startDay + minDisplayDays, daysSinceCreated + 14)
            
            // Filter history to last 100 days
            let visibleHistory = actualHistory.filter { $0.day >= startDay }
            
            // Ideal curve starts from the visible range's start point (day 0 of visible = 0 strength)
            let idealCurveFromStart = stride(from: startDay, through: endDay, by: 1).map { day in
                CurvePoint(day: day, strength: asymptoticStrength(day: day - startDay))
            }
            
            // 66-day marker relative to visible start
            let marker66Day = startDay + 66
            
            Chart {
                // Ideal curve (faded, for reference) - starts at 0 from visible range
                ForEach(idealCurveFromStart, id: \.day) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Ideal", point.strength),
                        series: .value("Series", "Ideal")
                    )
                    .foregroundStyle(AppTheme.lightPurple.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                
                // Actual strength history (main curve)
                ForEach(visibleHistory, id: \.day) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Strength", point.strength),
                        series: .value("Series", "Actual")
                    )
                    .foregroundStyle(habit.color)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                
                // Projected future (dashed)
                ForEach(projectedStrengthPoints(from: currentStrength, startDay: daysSinceCreated, maxDays: endDay), id: \.day) { point in
                    LineMark(
                        x: .value("Day", point.day),
                        y: .value("Projected", point.strength),
                        series: .value("Series", "Projected")
                    )
                    .foregroundStyle(habit.color.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }

                // Current position marker
                PointMark(
                    x: .value("Day", daysSinceCreated),
                    y: .value("Current", currentStrength)
                )
                .foregroundStyle(Color.white)
                .symbolSize(100)
                
                // 66-day milestone marker (relative to visible start)
                if marker66Day <= endDay {
                    RuleMark(x: .value("66 Days", marker66Day))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(AppTheme.lightPurple.opacity(0.4))
                        .annotation(position: .top, alignment: .center) {
                            Text("66d")
                                .font(.caption2)
                                .foregroundColor(AppTheme.lightPurple)
                        }
                }
            }
            .chartXScale(domain: startDay...endDay)
            .chartYScale(domain: 0...1.05)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1.0]) { value in
                    AxisGridLine()
                    if let v = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(v * 100))%")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            
            // Strength indicator
            HStack {
                Text("Current Strength:")
                    .font(.caption)
                    .foregroundColor(AppTheme.lightPurple)
                Text("\(Int(currentStrength * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(strengthColor(currentStrength))
                Spacer()
                if currentStrength < 0.5 {
                    Text("Keep going!")
                        .font(.caption2)
                        .foregroundColor(AppTheme.lightPurple)
                } else if currentStrength < 0.8 {
                    Text("Building momentum")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else {
                    Text("Almost automatic!")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private func strengthColor(_ strength: Double) -> Color {
        if strength < 0.33 { return .red }
        if strength < 0.66 { return .orange }
        return .green
    }
    
    private struct CurvePoint: Identifiable {
        let id = UUID()
        let day: Int
        let strength: Double
    }
    
    /// Calculates actual habit strength history based on completions
    /// - Daily habits: Each completion increases strength, each missed day decreases it
    /// - Weekly habits: Strength changes based on meeting weekly targets
    private func actualStrengthHistory() -> [CurvePoint] {
        let calendar = Calendar.current
        let creationDay = DateService.shared.startOfEffectiveDay(for: habit.createdAt)
        let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
        
        guard let totalDays = calendar.dateComponents([.day], from: creationDay, to: today).day,
              totalDays >= 0 else {
            return [CurvePoint(day: 0, strength: 0)]
        }
        
        // Build set of completed days (as day index from creation)
        var completedDays = Set<Int>()
        for entry in habit.entries where entry.completed {
            let entryDay = calendar.startOfDay(for: entry.date)
            if let dayIndex = calendar.dateComponents([.day], from: creationDay, to: entryDay).day,
               dayIndex >= 0 {
                completedDays.insert(dayIndex)
            }
        }
        
        var points: [CurvePoint] = []
        var strength: Double = 0
        
        if habit.frequency == .daily {
            // Daily habit: evaluate each day
            let maxStrength: Double = 1.0
            let gainRate: Double = 0.045  // ~66 days to reach 95% with perfect consistency
            let baseDecayRate: Double = 0.08
            
            for day in 0...totalDays {
                if completedDays.contains(day) {
                    let gain = gainRate * (maxStrength - strength)
                    strength = min(strength + gain, maxStrength)
                } else if day > 0 {
                    let decayMultiplier = 1.0 - (strength * 0.7)
                    let decay = baseDecayRate * decayMultiplier
                    strength = max(strength - decay, 0)
                }
                points.append(CurvePoint(day: day, strength: strength))
            }
        } else {
            // Weekly habit: evaluate by week
            let targetPerWeek = habit.targetPerWeek
            let maxStrength: Double = 1.0
            let gainRate: Double = 0.12  // Faster gain per successful week (~12 weeks to plateau)
            let baseDecayRate: Double = 0.15  // Larger decay for missed week
            
            var currentWeek = 0
            var completionsThisWeek = 0
            var weekStartDay = 0
            
            for day in 0...totalDays {
                let weekIndex = day / 7
                
                // New week started
                if weekIndex > currentWeek {
                    // Evaluate previous week
                    let metTarget = completionsThisWeek >= targetPerWeek
                    if metTarget {
                        let gain = gainRate * (maxStrength - strength)
                        strength = min(strength + gain, maxStrength)
                    } else if currentWeek > 0 {
                        // Partial credit: reduce decay based on how close to target
                        let completionRatio = Double(completionsThisWeek) / Double(targetPerWeek)
                        let decayMultiplier = (1.0 - completionRatio) * (1.0 - strength * 0.5)
                        let decay = baseDecayRate * decayMultiplier
                        strength = max(strength - decay, 0)
                    }
                    
                    // Fill in points for the previous week
                    for d in weekStartDay..<day {
                        points.append(CurvePoint(day: d, strength: strength))
                    }
                    
                    currentWeek = weekIndex
                    completionsThisWeek = 0
                    weekStartDay = day
                }
                
                if completedDays.contains(day) {
                    completionsThisWeek += 1
                }
            }
            
            // Handle current incomplete week - show current progress
            let progressRatio = Double(completionsThisWeek) / Double(targetPerWeek)
            let currentWeekBonus = min(progressRatio, 1.0) * gainRate * (maxStrength - strength) * 0.5
            let displayStrength = strength + currentWeekBonus
            
            for day in weekStartDay...totalDays {
                points.append(CurvePoint(day: day, strength: min(displayStrength, maxStrength)))
            }
        }
        
        return points
    }
    
    /// Ideal curve showing what perfect consistency would look like
    private func idealCurveDataPoints(maxDays: Int) -> [CurvePoint] {
        stride(from: 0, through: maxDays, by: 1).map { day in
            CurvePoint(day: day, strength: asymptoticStrength(day: day))
        }
    }
    
    /// Projects future strength if user continues current pattern
    private func projectedStrengthPoints(from currentStrength: Double, startDay: Int, maxDays: Int) -> [CurvePoint] {
        guard startDay < maxDays else { return [] }
        
        var points: [CurvePoint] = []
        var strength = currentStrength
        
        if habit.frequency == .daily {
            // Daily: project based on daily completion rate
            let completionRate = habit.completionRate / 100.0
            let gainRate: Double = 0.045
            let baseDecayRate: Double = 0.08
            
            for day in startDay...maxDays {
                let expectedGain = completionRate * gainRate * (1.0 - strength)
                let expectedDecay = (1.0 - completionRate) * baseDecayRate * (1.0 - strength * 0.7)
                strength = min(max(strength + expectedGain - expectedDecay, 0), 1.0)
                points.append(CurvePoint(day: day, strength: strength))
            }
        } else {
            // Weekly: project based on weekly success rate
            let targetPerWeek = habit.targetPerWeek
            let avgCompletionsPerWeek = habit.entries.isEmpty ? 0 : 
                Double(habit.entries.filter { $0.completed }.count) / max(1, Double(daysSinceCreated) / 7.0)
            let weeklySuccessRate = min(avgCompletionsPerWeek / Double(targetPerWeek), 1.0)
            
            let gainRate: Double = 0.12
            let baseDecayRate: Double = 0.15
            
            var currentWeekInProjection = startDay / 7
            
            for day in startDay...maxDays {
                let weekIndex = day / 7
                
                // Apply weekly change at week boundaries
                if weekIndex > currentWeekInProjection {
                    let expectedGain = weeklySuccessRate * gainRate * (1.0 - strength)
                    let expectedDecay = (1.0 - weeklySuccessRate) * baseDecayRate * (1.0 - strength * 0.5)
                    strength = min(max(strength + expectedGain - expectedDecay, 0), 1.0)
                    currentWeekInProjection = weekIndex
                }
                
                points.append(CurvePoint(day: day, strength: strength))
            }
        }
        
        return points
    }
    
    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            ContributionGridView(habit: habit) { date in
                let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
                if date <= today {
                    withAnimation {
                        habit.toggleCompletion(for: date, context: modelContext)
                        try? modelContext.save()
                    }
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Image(systemName: habit.reminderEnabled ? "alarm.fill" : "alarm")
                    .foregroundColor(habit.reminderEnabled ? habit.color : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    if habit.reminderEnabled {
                        if habit.reminderType == .single {
                            let times = sortedReminderTimes(habit.effectiveReminderTimes)
                            if times.isEmpty {
                                Text("No times set")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else if times.count == 1 {
                                Text("Daily at \(formattedTime(times[0]))")
                                    .font(.subheadline)
                            } else {
                                Text("Daily at \(times.map { formattedTime($0) }.joined(separator: ", "))")
                                    .font(.subheadline)
                            }
                        } else {
                            Text("Every \(habit.periodicIntervalHours) hour\(habit.periodicIntervalHours > 1 ? "s" : "")")
                                .font(.subheadline)
                            Text("\(formattedTime(habit.periodicStartTime))–\(formattedTime(habit.periodicEndTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Reminders Off")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private func formattedTime(_ date: Date?) -> String {
        guard let date else { return "--:--" }
        return date.formatted(date: .omitted, time: .shortened)
    }
    
    private func sortedReminderTimes(_ times: [Date]) -> [Date] {
        let calendar = Calendar.current
        return times.sorted {
            let lhs = calendar.dateComponents([.hour, .minute], from: $0)
            let rhs = calendar.dateComponents([.hour, .minute], from: $1)
            if lhs.hour == rhs.hour {
                return (lhs.minute ?? 0) < (rhs.minute ?? 0)
            }
            return (lhs.hour ?? 0) < (rhs.hour ?? 0)
        }
    }

    private var last7DaysCompletions: Int {
        let calendar = Calendar.current
        let end = DateService.shared.startOfEffectiveDay(for: DateService.now())
        let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        return habit.entries.filter { entry in
            guard entry.completed else { return false }
            let entryDay = calendar.startOfDay(for: entry.date)
            return entryDay >= start && entryDay <= end
        }.count
    }
    
    private var last7DaysExpected: Int {
        habit.frequency == .daily ? 7 : habit.targetPerWeek
    }
    
    private var last4WeeksCompletions: Int {
        let calendar = Calendar.current
        let end = DateService.shared.startOfEffectiveDay(for: DateService.now())
        let start = calendar.date(byAdding: .day, value: -27, to: end) ?? end
        return habit.entries.filter { entry in
            guard entry.completed else { return false }
            let entryDay = calendar.startOfDay(for: entry.date)
            return entryDay >= start && entryDay <= end
        }.count
    }
    
    private var last4WeeksExpected: Int {
        habit.frequency == .daily ? 28 : habit.targetPerWeek * 4
    }

    private var daysSinceCreated: Int {
        let calendar = Calendar.current
        let start = DateService.shared.startOfEffectiveDay(for: habit.createdAt)
        let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(days, 0)
    }

    private let plateauDay: Int = 66

    /// Ideal asymptotic curve (Mitscherlich's law) for reference
    private func asymptoticStrength(day: Int) -> Double {
        if day >= plateauDay {
            return 1
        }
        let k = -log(1 - 0.95) / Double(plateauDay)
        let value = 1 - exp(-k * Double(day))
        return min(max(value, 0), 1)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            let recentEntries = habit.entries
                .filter { $0.completed }
                .sorted { $0.date > $1.date }
                .prefix(6)
            let activityItems: [(date: Date, isCreation: Bool)] =
                [(habit.createdAt, true)] + recentEntries.map { ($0.date, false) }
            
            if activityItems.isEmpty {
                Text("No completions yet")
                    .foregroundColor(AppTheme.lightPurple)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(activityItems.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Circle()
                                .fill(item.isCreation ? AppTheme.lightPurple : habit.color)
                                .frame(width: 8, height: 8)
                            
                            if item.isCreation {
                                Text("Created")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.lightPurple)
                            } else {
                                Text(item.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            if item.isCreation {
                                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.lightPurple)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.lightPurple)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(name: "Exercise", icon: "figure.run"))
    }
    .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

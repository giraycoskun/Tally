//
//  HabitDetailView.swift
//  Tally
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Stats Cards
                statsSection
                
                // Reminder Settings
                reminderSection
                
                // Full Contribution Grid
                gridSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
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
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    habit.toggleCompletion(for: Date(), context: modelContext)
                    try? modelContext.save()
                }
            } label: {
                HStack {
                    Image(systemName: habit.isCompletedOn(date: Date()) ? "checkmark.circle.fill" : "circle")
                    Text(habit.isCompletedOn(date: Date()) ? "Completed Today" : "Mark as Complete")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(habit.isCompletedOn(date: Date()) ? habit.color : Color.gray)
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
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(habit.completionsThisWeek)/\(habit.targetPerWeek)")
                            .font(.headline)
                            .foregroundColor(habit.isWeeklyGoalMet ? .green : .primary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(habit.isWeeklyGoalMet ? Color.green : habit.color)
                                .frame(width: geo.size.width * habit.weeklyProgress)
                        }
                    }
                    .frame(height: 12)
                }
                .padding()
                .background(Color(.systemGray6))
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
            }
        }
    }
    
    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
            
            ContributionGridView(habit: habit) { date in
                if date <= Date() {
                    withAnimation {
                        habit.toggleCompletion(for: date, context: modelContext)
                        try? modelContext.save()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder")
                .font(.headline)
            
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
            .background(Color(.systemGray6))
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
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            let recentEntries = habit.entries
                .filter { $0.completed }
                .sorted { $0.date > $1.date }
                .prefix(7)
            
            if recentEntries.isEmpty {
                Text("No completions yet")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(recentEntries), id: \.id) { entry in
                        HStack {
                            Circle()
                                .fill(habit.color)
                                .frame(width: 8, height: 8)
                            
                            Text(entry.date, style: .date)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(name: "Exercise", icon: "figure.run"))
    }
    .modelContainer(for: [Habit.self, HabitEntry.self], inMemory: true)
}

//
//  HabitListView.swift
//  Tally
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct HabitListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var orderedHabits: [Habit] = []
    @State private var draggedHabit: Habit?
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private var currentTheme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.surfaceBackground
                    .ignoresSafeArea()
                
                Group {
                    if habits.isEmpty {
                        EmptyHabitsView(showingAddHabit: $showingAddHabit)
                    } else {
                        habitList
                    }
                }
            }
            .navigationTitle("Tally")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(currentTheme.darkColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(currentTheme.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            syncOrderedHabits()
            ensureInitialSortOrder()
        }
        .onChange(of: habits.map(\.id)) { _, _ in
            syncOrderedHabits()
            ensureInitialSortOrder()
        }
    }
    
    private var habitList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Last7DaysSection(habits: habits)
                TodaySection(habits: habits)
                
                ForEach(orderedHabits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        HabitCardView(habit: habit)
                    }
                    .buttonStyle(.plain)
                    .onDrag {
                        draggedHabit = habit
                        return NSItemProvider(object: habit.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: HabitDropDelegate(
                        item: habit,
                        items: $orderedHabits,
                        draggedItem: $draggedHabit,
                        onMove: persistSortOrder
                    ))
                }
            }
            .padding()
        }
    }
    
    private func syncOrderedHabits() {
        orderedHabits = habits.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    private func ensureInitialSortOrder() {
        guard !habits.isEmpty else { return }
        let uniqueOrderCount = Set(habits.map(\.sortOrder)).count
        if uniqueOrderCount <= 1 {
            let sortedByCreatedAt = habits.sorted { $0.createdAt < $1.createdAt }
            for (index, habit) in sortedByCreatedAt.enumerated() {
                habit.sortOrder = index
            }
            try? modelContext.save()
            orderedHabits = sortedByCreatedAt
        }
    }
    
    private func persistSortOrder(_ items: [Habit]) {
        for (index, habit) in items.enumerated() {
            habit.sortOrder = index
        }
        try? modelContext.save()
    }
}

private struct HabitDropDelegate: DropDelegate {
    let item: Habit
    @Binding var items: [Habit]
    @Binding var draggedItem: Habit?
    let onMove: ([Habit]) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        withAnimation {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        onMove(items)
        draggedItem = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

struct TodaySection: View {
    let habits: [Habit]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private var theme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    private var completedToday: Int {
        // daySwitchHour dependency ensures recomputation when setting changes
        let _ = daySwitchHour
        return habits.filter { $0.isCompletedOn(date: DateService.now()) }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(completedToday)/\(habits.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(completedToday == habits.count ? .green : theme.accentColor)
            }
            
            // Quick complete buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(habits) { habit in
                        QuickCompleteButton(habit: habit)
                    }
                }
            }
        }
        .padding()
        .background(theme.mediumColor)
        .cornerRadius(16)
    }
}

struct Last7DaysSection: View {
    let habits: [Habit]
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    private let calendar = Calendar.current
    
    private var theme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    private var last7Dates: [Date] {
        // daySwitchHour dependency ensures recomputation when setting changes
        let _ = daySwitchHour
        let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
        let dates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
        return dates.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(last7Dates, id: \.self) { date in
                    DaySummaryView(
                        date: date,
                        completed: habits.filter { $0.isCompletedOn(date: date) }.count,
                        total: habits.count
                    )
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }
}

struct DaySummaryView: View {
    let date: Date
    let completed: Int
    let total: Int
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    
    private var theme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    private var ratio: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    private var circleColor: Color {
        if total == 0 {
            return theme.lightColor
        }
        return blend(from: theme.surfaceBackground, to: .green, fraction: ratio)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(date.formatted(.dateTime.weekday(.narrow)))
                .font(.caption2)
                .foregroundColor(theme.lightColor)
            
            Text(date.formatted(.dateTime.day()))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(theme.surfaceBackground.opacity(0.6), lineWidth: 2)
                    .frame(width: 34, height: 34)
                
                Circle()
                    .fill(circleColor)
                    .frame(width: 28, height: 28)
                
            Text("\(completed)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(circleColor)
        }
    }
    .frame(maxWidth: .infinity)
}
    
    private func blend(from: Color, to: Color, fraction: Double) -> Color {
        let clamped = min(max(fraction, 0), 1)
        let uiFrom = UIColor(from)
        let uiTo = UIColor(to)
        var fr: CGFloat = 0
        var fg: CGFloat = 0
        var fb: CGFloat = 0
        var fa: CGFloat = 0
        var tr: CGFloat = 0
        var tg: CGFloat = 0
        var tb: CGFloat = 0
        var ta: CGFloat = 0
        guard uiFrom.getRed(&fr, green: &fg, blue: &fb, alpha: &fa),
              uiTo.getRed(&tr, green: &tg, blue: &tb, alpha: &ta) else {
            return to
        }
        let r = fr + (tr - fr) * clamped
        let g = fg + (tg - fg) * clamped
        let b = fb + (tb - fb) * clamped
        let a = fa + (ta - fa) * clamped
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

struct QuickCompleteButton: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private var theme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    private var isCompletedToday: Bool {
        let _ = daySwitchHour
        return habit.isCompletedOn(date: DateService.now())
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                habit.toggleCompletion(for: DateService.now(), context: modelContext)
                try? modelContext.save()
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isCompletedToday ? habit.color : theme.cardBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: habit.icon)
                        .font(.title3)
                        .foregroundColor(isCompletedToday ? .white : theme.lightColor)
                }
                
                Text(habit.name)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
            .frame(width: 70)
        }
    }
}

struct HabitCardView: View {
    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    @AppStorage("daySwitchHour") private var daySwitchHour: Int = 0
    
    private var theme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    private var isCompletedToday: Bool {
        let _ = daySwitchHour
        return habit.isCompletedOn(date: DateService.now())
    }
    
    private var currentStreak: Int {
        let _ = daySwitchHour
        return habit.currentStreak
    }
    
    private var completionsThisWeek: Int {
        let _ = daySwitchHour
        return habit.completionsThisWeek
    }
    
    private var isWeeklyGoalMet: Bool {
        let _ = daySwitchHour
        return habit.isWeeklyGoalMet
    }
    
    private var completionRate: Double {
        let _ = daySwitchHour
        return habit.completionRate
    }
    
    private var todayCount: Int {
        let _ = daySwitchHour
        return habit.completionCount(on: DateService.now())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: habit.icon)
                    .font(.title2)
                    .foregroundColor(habit.color)
                    .frame(width: 40, height: 40)
                    .background(habit.color.opacity(0.2))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(habit.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(habit.frequencyLabel)
                            .font(.caption2)
                            .foregroundColor(theme.lightColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.mediumColor)
                            .cornerRadius(4)
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(currentStreak)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        if habit.frequency == .weekly {
                            Label("\(completionsThisWeek)/\(habit.targetPerWeek)", systemImage: "calendar.badge.checkmark")
                                .font(.caption)
                                .foregroundColor(isWeeklyGoalMet ? .green : theme.lightColor)
                        } else if habit.dailyTarget > 1 {
                            Label("\(todayCount)/\(habit.dailyTarget) today", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(theme.lightColor)
                        } else {
                            Label("\(Int(completionRate))%", systemImage: "chart.pie.fill")
                                .font(.caption)
                                .foregroundColor(theme.lightColor)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        habit.toggleCompletion(for: DateService.now(), context: modelContext)
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(isCompletedToday ? habit.color : theme.lightColor)
                }
            }
            
            // Contribution grid - fills available width
            ContributionGridView(habit: habit)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }
}

struct EmptyHabitsView: View {
    @Binding var showingAddHabit: Bool
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    
    private var theme: ThemeColor {
        ThemeColor(rawValue: selectedThemeRaw) ?? .purple
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(theme.primaryColor)
            
            Text("Start Your Journey")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Create your first habit and begin building\nbetter routines one day at a time.")
                .multilineTextAlignment(.center)
                .foregroundColor(theme.lightColor)
            
            Button {
                showingAddHabit = true
            } label: {
                Label("Add Habit", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.primaryColor)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

#Preview {
    let container = makeHabitListPreviewContainer()
    HabitListView()
        .modelContainer(container)
}

private func makeHabitListPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitEntry.self, configurations: config)
    let context = container.mainContext
    let calendar = Calendar.current
    let today = DateService.shared.startOfEffectiveDay(for: DateService.now())
    
    let dailyTwice = Habit(
        name: "Hydrate",
        icon: "drop.fill",
        colorHex: "#4FC3F7",
        reminderEnabled: false,
        frequency: .daily,
        targetPerWeek: 7,
        dailyTarget: 2
    )
    
    let weeklyHabit = Habit(
        name: "Workout",
        icon: "figure.run",
        colorHex: "#FF7043",
        reminderEnabled: false,
        frequency: .weekly,
        targetPerWeek: 4
    )
    
    let dailyOnce = Habit(
        name: "Read",
        icon: "book.fill",
        colorHex: "#BA68C8",
        reminderEnabled: false,
        frequency: .daily,
        targetPerWeek: 7,
        dailyTarget: 1
    )
    
    [dailyTwice, weeklyHabit, dailyOnce].forEach { context.insert($0) }
    
    let dailyEntry = HabitEntry(date: today, completed: true, count: 1)
    dailyEntry.habit = dailyTwice
    dailyTwice.entries.append(dailyEntry)
    context.insert(dailyEntry)
    
    let dailyEntry2 = HabitEntry(date: today, completed: true, count: 2)
    dailyEntry2.habit = dailyOnce
    dailyOnce.entries.append(dailyEntry2)
    context.insert(dailyEntry2)
    
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
        let weeklyEntry = HabitEntry(date: yesterday, completed: true, count: 1)
        weeklyEntry.habit = weeklyHabit
        weeklyHabit.entries.append(weeklyEntry)
        context.insert(weeklyEntry)
    }
    
    return container
}

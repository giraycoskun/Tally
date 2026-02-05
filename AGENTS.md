# Tally - Habit Tracker App

## Project Overview
iOS habit tracking app built with SwiftUI and SwiftData. Features GitHub-style contribution grids, smart reminders, and a dark purple theme.

## Tech Stack
- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Data:** SwiftData (Core Data wrapper)
- **Notifications:** UserNotifications framework
- **Min iOS:** 17.0+
- **IDE:** Xcode 15.0+

## Project Structure
```
Tally/
├── TallyApp.swift              # App entry point, ModelContainer setup
├── Models/
│   ├── Habit.swift             # Main habit model with computed properties
│   └── HabitEntry.swift        # Daily completion entries
├── Views/
│   ├── MainTabView.swift       # Tab navigation (Habits, Stats, Settings)
│   ├── HabitListView.swift     # Main list with TodaySection, QuickCompleteButton, HabitCardView
│   ├── HabitDetailView.swift   # Full habit view with stats and grid
│   ├── AddHabitView.swift      # Create new habit form
│   ├── EditHabitView.swift     # Edit existing habit
│   ├── StatisticsView.swift    # Charts, rankings, overall activity grid
│   ├── SettingsView.swift      # App settings
│   └── Components/
│       └── ContributionGridView.swift  # GitHub-style contribution grid
├── Services/
│   ├── DateService.swift          # Day boundary logic (configurable day switch hour)
│   └── NotificationService.swift  # Reminder scheduling (single & periodic)
└── Theme/
    └── AppTheme.swift          # Color palette (matte purple theme)
```

## Key Models

### Habit
- `id`, `name`, `icon`, `colorHex`, `createdAt`
- **Frequency:** `HabitFrequency` enum (.daily, .weekly) + `targetPerWeek` (1-6)
- **Reminders:** `reminderEnabled`, `reminderType` (.single, .periodic)
  - Single: `reminderTime`
  - Periodic: `periodicStartTime`, `periodicEndTime`, `periodicIntervalHours`
- **Computed:** `currentStreak`, `longestStreak`, `completionRate`, `completionsThisWeek`, `weeklyProgress`
- **Relationship:** `entries: [HabitEntry]` (cascade delete)

### HabitEntry
- `id`, `date`, `completed`, `habit` (inverse relationship)

## Key Features

### 1. Contribution Grid
- Dynamic width calculation using GeometryReader
- Fills available space, calculates weeks to show
- Tappable cells to toggle completion for past dates
- Uses habit color for completed cells

### 2. Frequency Types
- **Daily:** Track every day, streaks count consecutive days
- **Weekly:** Set target 1-6x per week, shows progress bar, streaks count consecutive weeks meeting goal

### 3. Reminder Types
- **Single:** One notification per day at set time
- **Periodic:** Multiple notifications within time range (e.g., 8am-10pm every 2 hours)

### 4. Theme
- Dark purple matte color scheme defined in `AppTheme.swift`
- Colors: `primaryPurple`, `darkPurple`, `mediumPurple`, `lightPurple`, `accentPurple`, `cardBackground`, `surfaceBackground`

## Common Patterns

### SwiftData Binding
Use `@Bindable var habit: Habit` (not `let`) in subviews to observe model changes and keep UI in sync.

### Saving Changes
After modifying SwiftData models, call `try? modelContext.save()` to persist immediately.

### Schema Migrations
TallyApp.swift handles migration failures by deleting old store files and recreating. For production, implement proper versioned migrations.

## Build & Run
```bash
# Open in Xcode
open Tally.xcodeproj

# Build: ⌘+B
# Run: ⌘+R
```

## Known Considerations
1. **Notifications require permission** - App requests on first reminder setup
2. **Notifications cleared on app open** - Badge reset, delivered notifications removed
3. **Navigation bar** uses `.inline` display mode to prevent collapsing on scroll
4. **Grid sizing** - Both ContributionGridView and OverallActivityGrid use GeometryReader for responsive width
5. **Day boundary** - Configurable day switch hour (0-6 AM) in Settings. Use `DateService.shared` for all date calculations to respect this setting. Note: Midnight dates (hour=0, minute=0, second=0) are treated as "day markers" and won't be transformed again to avoid double-application bugs.

## Future Improvements
- [ ] Widget support for quick completion
- [ ] iCloud sync
- [ ] Data export (CSV/JSON)
- [ ] Habit categories/groups
- [ ] Custom reminder sounds
- [ ] Habit templates
- [ ] Apple Watch companion app

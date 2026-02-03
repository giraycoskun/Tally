# Tally - Habit Tracker

A simple, beautiful habit tracking app for iOS with GitHub-style contribution grids and smart reminders.

## Features

- **GitHub-style Contribution Grid** - Visual tracking that shows your progress over time
- **Quick Complete** - Tap to mark habits done directly from the home screen
- **Statistics Dashboard** - Track streaks, completion rates, and weekly progress with charts
- **Smart Reminders** - Context-aware notifications that adapt based on your streak and progress
- **Custom Habits** - Create habits with custom icons and colors

## Screenshots

*Coming soon*

## Project Structure

```
Tally/
├── Models/
│   ├── Habit.swift              # Habit model with streak/completion calculations
│   └── HabitEntry.swift         # Daily completion entries
├── Views/
│   ├── MainTabView.swift        # Tab navigation (Habits, Stats, Settings)
│   ├── HabitListView.swift      # Home screen with quick actions
│   ├── HabitDetailView.swift    # Full contribution grid + statistics
│   ├── AddHabitView.swift       # Create new habit
│   ├── EditHabitView.swift      # Modify existing habit
│   ├── StatisticsView.swift     # Charts and habit rankings
│   ├── SettingsView.swift       # App settings
│   └── Components/
│       └── ContributionGridView.swift  # Reusable GitHub-style grid
├── Services/
│   └── NotificationService.swift  # Smart reminder scheduling
└── TallyApp.swift               # App entry point
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Tech Stack

- **SwiftUI** - Modern declarative UI
- **SwiftData** - Data persistence
- **Swift Charts** - Statistics visualization
- **UserNotifications** - Smart reminders

## Getting Started

1. Clone the repository
2. Open `Tally.xcodeproj` in Xcode
3. Select a simulator or device
4. Build and run (⌘+R)

## License

MIT

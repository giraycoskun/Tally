
<img
  src="Tally/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
  alt="Tally Logo"
  width="200"
  style="margin-bottom: 20px;">


# Tally - Habit Tracker

Everyone has its own idea of a habit tracker and also because available apps limiting number of habits. I thought why not with the help of coding agents it became possible to create a working version on an afternoon. So here it is, Tally -

A simple habit tracking app for iOS with GitHub-style contribution grids, analytics and reminders.



## Features

- **GitHub-style Contribution Grid** - Visual tracking that shows your progress over time
- **Quick Complete** - Tap to mark habits done directly from the home screen
- **Statistics Dashboard** - Track streaks, completion rates, and weekly progress with charts
- **Reminders with Interval** - Reminders either simple daily or interval-based notifications

It is free so no limitations on number of habits or entries.

## Screenshots

*Coming soon*

## Project Structure
```
Tally/
├── TallyApp.swift                 # App entry point + ModelContainer
├── Models/
│   ├── Habit.swift                # Habit model + computed stats
│   └── HabitEntry.swift           # Daily completion entries
├── Views/
│   ├── MainTabView.swift          # Tab navigation (Habits/Stats/Settings)
│   ├── HabitListView.swift        # Today section + quick actions + cards
│   ├── HabitDetailView.swift      # Contribution grid + analytics
│   ├── AddHabitView.swift         # Create habit form
│   ├── EditHabitView.swift        # Edit habit form
│   ├── StatisticsView.swift       # Charts + rankings + overall activity grid
│   ├── SettingsView.swift         # App settings
│   └── Components/
│       └── ContributionGridView.swift  # Reusable GitHub-style grid
├── Services/
│   └── NotificationService.swift  # Reminder scheduling (single & periodic)
├── Theme/
│   └── AppTheme.swift             # Matte purple color palette
└── Assets.xcassets/               # App icons and colors
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

## References

- [AltStore Docs](https://faq.altstore.io/)
- [AltStore Source Docs](https://faq.altstore.io/developers/make-a-source)

## License

MIT

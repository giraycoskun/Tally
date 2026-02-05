<img
  src="Tally/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
  alt="Tally Logo"
  width="200"
  style="margin-bottom: 20px;">

# Tally - Habit Tracker

Everyone has its own idea of a habit tracker and also because available apps limiting number of habits. I thought why not with the help of coding agents it became possible to create a working version on an afternoon. So here it is, Tally -

A simple habit tracking app for iOS with GitHub-style contribution grids, analytics and reminders.

It is free so no limitations on number of habits or entries. This was the most annoying part taht led me to develop a custom app for myself. I understand just keeping an app on AppStore costs so I understand the apps requiring subscription but it is just something very basic that I really couldn't justify to myself to pay for it regularly. It is basically a list with UI.

And also this was my first time building an IOS app and I really understood the IOS developers' grievances on AppStore. I know AppStore wants to keep certain standards for security and quality but it should really leave room if I personally take risks and install unauthorized apps.

## Features

- **GitHub-style Contribution Grid** - Visual tracking that shows your progress over time
- **Quick Complete** - Tap to mark habits done directly from the home screen
- **Statistics Dashboard** - Track streaks, completion rates, and weekly progress with charts
- **Reminders with Interval** - Reminders either simple daily or interval-based notifications

## Screenshots

<p float="left">
  <img src="https://images.giraycoskun.dev/ss-tally-home.png" width="150" />
  <img src="https://images.giraycoskun.dev/ss-tally-home-2.png" width="150" />
  <img src="https://images.giraycoskun.dev/ss-tally-stats.png" width="150" />
  <img src="https://images.giraycoskun.dev/ss-tally-settings.png" width="150" />
</p>


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

## Next Tasks/Bugs

- [ ] Add x - times a day feature
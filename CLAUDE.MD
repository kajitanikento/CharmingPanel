# CharmingPanel

CharmingPanel is a macOS menu bar application featuring an animated cat character that lives on your desktop and helps with productivity through a Pomodoro timer.

## Overview

CharmingPanel provides a delightful desktop companion that:
- Displays an animated cat character on your screen
- Includes a Pomodoro timer to help manage work sessions
- Shows input source indicators
- Responds to hotkeys for quick interaction
- Can follow your mouse cursor

## Architecture

### Technology Stack
- **Platform**: macOS 15.0+
- **Language**: Swift 6.2
- **Framework**: SwiftUI
- **State Management**: The Composable Architecture (TCA) v1.23.1
- **Build System**: Swift Package Manager + Xcode

### Project Structure

```
CharmingPanel/
├── CharmingPanel/                      # Main app target
│   └── CharmingPanelApp.swift         # App entry point
├── CharmingPanelPackage/              # Core package
│   ├── Package.swift                   # Package manifest
│   └── Sources/
│       ├── AppDelegate.swift          # App lifecycle & status bar setup
│       ├── Device/                    # System integrations
│       │   ├── InputSourceObserver.swift
│       │   └── HotKeyObserver.swift
│       ├── Feature/                   # Feature modules
│       │   ├── ActorPanel/           # Main panel coordinator
│       │   │   ├── ActorPanel.swift              # TCA reducer
│       │   │   ├── ActorPanelController.swift    # NSPanel controller
│       │   │   ├── ActorPanelView.swift          # Main view
│       │   │   └── ActorPanelMenu/              # Menu panel
│       │   ├── Cat/                  # Cat character feature
│       │   │   ├── Cat.swift                     # TCA reducer
│       │   │   └── CatView.swift                # Cat animation view
│       │   └── PomodorTimer/         # Timer feature
│       │       ├── PomodoroTimer.swift          # TCA reducer
│       │       └── PomodoroTimerView.swift      # Timer UI
│       └── UICore/                   # Shared UI utilities
│           └── Extension/
└── CharmingPanel.xcodeproj/          # Xcode project
```

## Key Features

### 1. Animated Cat Character
- The cat has multiple states: `onBall`, `hasTimer`, `completeTimer`
- Animation intervals can be adjusted (default, quick, custom)
- Configurable animation enable/disable

### 2. Pomodoro Timer
- Set custom timer durations via menu
- Recent timer durations are saved for quick access
- Visual feedback through cat animation changes
- When timer completes:
  - Cat changes to "complete timer" state
  - Cat follows mouse cursor for 30 seconds
  - Quick animation mode activated

### 3. Panel Positioning
- Can be manually positioned on screen
- Hotkey support to call cat to mouse location
- Optional automatic movement to mouse after idle time
- Smooth animations with configurable duration

### 4. Menu Bar Integration
- Status bar icon with menu
- Toggle panel visibility (Cmd+U)
- Show/hide controls
- Quick quit option (Cmd+Q)

### 5. Hotkey Support
- **Call Cat**: Summons cat to mouse location
- **Toggle Hidden**: Show/hide the panel
- Implemented via `HotKeyObserver` dependency

### 6. Input Source Monitoring
- Tracks current keyboard input source
- Updates displayed in panel
- Uses reactive stream via `InputSourceObserver`

## TCA (The Composable Architecture) Pattern

The app follows TCA's unidirectional data flow:

### ActorPanel (Root Reducer)
- **State**: Holds app-wide state including input source, panel position, visibility, child states
- **Actions**: Lifecycle, user inputs, dependency updates, child actions
- **Effects**: Input source observation, hotkey monitoring, timer-based effects
- **Child Reducers**: PomodoroTimer, Cat, ActorPanelMenu

### Dependencies
- `InputSourceObserver`: Streams input source changes
- `HotKeyObserver`: Streams hotkey events
- `ContinuousClock`: Timer intervals
- `Date`: Current date/time

## Recent Changes

Based on recent commits:
- Menu panel now displays to the right of actor panel
- If menu would go offscreen, it displays to the left instead
- Menu has been refactored into a separate panel component
- Code has been organized into smaller, focused functions

## Development Guidelines

### When Adding Features
1. Follow TCA pattern: define State, Action, Reducer
2. Use dependencies for external interactions
3. Keep reducers pure - side effects in `.run` blocks
4. Scope child reducers appropriately
5. Use `.send` for action composition

### When Modifying UI
1. SwiftUI views should be stateless
2. Use `@ObservableState` for view state
3. Send actions to store for state changes
4. Prefer composition over monolithic views

### Testing Considerations
- TCA provides excellent testability
- Test reducers by sending actions and asserting state changes
- Mock dependencies for isolated testing
- Test effects using TestStore

## Build & Run

### Requirements
- macOS 15.0 or later
- Xcode with Swift 6.2 support
- Swift Package Manager (included with Xcode)

### Building
```bash
# Open in Xcode
open CharmingPanel.xcodeproj

# Or build via command line
xcodebuild -project CharmingPanel.xcodeproj -scheme CharmingPanel
```

### Dependencies
Dependencies are managed via Swift Package Manager and defined in `CharmingPanelPackage/Package.swift`:
- swift-composable-architecture (1.23.1+)

## Code Style Notes

- Swift 6 language mode enabled
- Uses strict concurrency checking (`@MainActor` annotations)
- Follows TCA best practices
- SwiftUI previews available for views
- Modular architecture with clear separation of concerns

## Menu Bar Icon
The app uses a custom menu bar icon (`MenuIcon`) from the module's asset bundle.

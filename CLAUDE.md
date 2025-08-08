# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack
- **Platform**: iOS/macOS app
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Testing Framework**: Swift Testing (new framework, uses `@Test` macro)
- **Build System**: Xcode

## Common Commands

### Build & Run
```bash
# Build the project
xcodebuild -project expense.xcodeproj -scheme expense -configuration Debug build

# Run on simulator
open -a Simulator
xcodebuild -project expense.xcodeproj -scheme expense -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Testing
```bash
# Run all tests
xcodebuild test -project expense.xcodeproj -scheme expense -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test
xcodebuild test -project expense.xcodeproj -scheme expense -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:expenseTests/expenseTests/example
```

### Clean Build
```bash
xcodebuild clean -project expense.xcodeproj -scheme expense
```

## Architecture

### Core Components
- **expenseApp.swift**: Main app entry point, configures SwiftData ModelContainer
- **ContentView.swift**: Primary UI view with list of items and navigation
- **Item.swift**: SwiftData model representing expense items (currently just timestamps)

### Data Layer
- Uses SwiftData with `@Model` macro for persistence
- ModelContainer configured in app entry point
- ModelContext injected via environment

### Testing Structure
- **expenseTests/**: Unit tests using Swift Testing framework
- **expenseUITests/**: UI tests for automated interface testing
- Tests use `@Test` macro (new Swift Testing syntax, not XCTest)

## Key Development Notes

When modifying SwiftData models:
- Changes to `@Model` classes require migration if app is already deployed
- Use `modelContainer(for:inMemory:)` for preview and test environments

SwiftUI view updates:
- Views using `@Query` automatically refresh when data changes
- Use `@Environment(\.modelContext)` to access data context
- Wrap data modifications in `withAnimation` for smooth UI transitions
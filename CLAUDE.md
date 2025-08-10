# CLAUDE.md - Receipt Expense Tracker

This file provides guidance to Claude Code (claude.ai/code) when working with this iOS receipt/expense tracking app.

## Project Overview
A comprehensive iOS receipt management and expense tracking app that allows users to:
- Capture receipts using the device camera
- Organize expenses by business categories (meals, travel, office supplies, etc.)
- Track submission status through approval workflow
- Export receipt data for expense reporting
- Manage a backlog of unprocessed receipts

## Tech Stack
- **Platform**: iOS (iPhone/iPad)
- **Language**: Swift
- **UI Framework**: SwiftUI with tab-based navigation
- **Data Persistence**: SwiftData with Receipt model
- **Camera**: Native iOS camera integration
- **Testing Framework**: Swift Testing (uses `@Test` macro)
- **Build System**: Xcode

## Common Commands

### Build & Run
```bash
# Build the project
xcodebuild -project expense.xcodeproj -scheme expense -configuration Debug build

# Run on iPhone simulator
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

### App Structure
- **expenseApp.swift**: Main app entry point with LaunchScreenView and SwiftData ModelContainer for Receipt model
- **MainTabView.swift**: Root tab interface with 3 tabs: Capture (camera), Backlog (unprocessed), History (all receipts)
- **LaunchScreenView.swift**: 2.5-second launch animation with fade transition

### Core Views
- **CameraView.swift**: Receipt capture interface using device camera
- **BacklogView.swift**: Lists unprocessed receipts with badge count on tab
- **ReceiptListView.swift**: Historical view of all receipts with filtering/search
- **ReceiptEditView.swift**: Form for editing receipt details (amount, merchant, category, notes)
- **ReceiptDetailView.swift**: Read-only detailed view of individual receipts
- **BatchExportView.swift**: Bulk export functionality for expense reporting

### Data Models
- **Receipt.swift**: SwiftData model with comprehensive expense data:
  - Basic info: amount, merchant, timestamp, imageData
  - Categorization: ReceiptCategory enum (meals, travel, office, vehicle, utilities, etc.)
  - Workflow: SubmissionStatus enum (pending, submitted, approved, rejected)
  - Optional fields: taxAmount, paymentMethod, notes
  - Processing state: isProcessed boolean for backlog management

### Categories & Status
- **ReceiptCategory**: 10 business expense categories with SF Symbol icons and colors
- **SubmissionStatus**: 4-state approval workflow with visual indicators
- Each category/status has associated icon, color, and formatted display

### Utilities
- **ExportManager.swift**: Handles bulk export of receipt data (CSV, PDF, etc.)
- **AppIconExporter.swift**: Development utility for app icon generation

### Data Layer
- Uses SwiftData with Receipt model as primary entity
- ModelContainer configured in expenseApp.swift
- @Query with filters for unprocessed receipts in MainTabView
- ModelContext injected via environment for data operations

### Testing Structure
- **expenseTests/**: Unit tests using Swift Testing framework
- **expenseUITests/**: UI tests for tab navigation and receipt workflows
- Tests use `@Test` macro (Swift Testing, not XCTest)

## Development Guidelines

### Receipt Management
- New receipts default to .pending status and unprocessed state
- Camera integration stores image as Data in receipt.imageData
- Use ReceiptCategory enum for consistent categorization
- Always update submission dates when changing status

### SwiftData Best Practices
- Receipt model changes require migration planning
- Use @Query with predicates for filtered views (e.g., unprocessed receipts)
- Wrap data modifications in withAnimation for smooth UI transitions
- Use modelContainer(for:inMemory:) for preview/test environments

### UI Patterns
- Tab badges show unprocessed receipt count
- SF Symbols used consistently for categories and status
- Color coding matches category/status enums
- Navigation stack used for History tab to support detail views

### Camera Integration
- Capture receipt images directly to Receipt.imageData
- Handle camera permissions and availability
- Optimize image size for storage while maintaining readability
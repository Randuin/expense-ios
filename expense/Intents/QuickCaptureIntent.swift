//
//  QuickCaptureIntent.swift
//  expense
//
//  Created by Claude on 8/10/25.
//

import Foundation
import AppIntents
import SwiftUI

@available(iOS 16.0, *)
struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Capture Receipt"
    static var description = IntentDescription("Quickly capture a receipt with minimal steps")
    static var openAppWhenRun: Bool = true
    
    static var parameterSummary: some ParameterSummary {
        Summary("Capture a receipt quickly")
    }
    
    func perform() async throws -> some IntentResult {
        // This intent will open the app and trigger quick capture mode
        return .result()
    }
}

@available(iOS 16.0, *)
struct ExpenseAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickCaptureIntent(),
            phrases: [
                "Capture receipt with \(.applicationName)",
                "Quick capture with \(.applicationName)",
                "Take receipt photo with \(.applicationName)"
            ],
            shortTitle: "Quick Capture",
            systemImageName: "camera.fill"
        )
    }
}
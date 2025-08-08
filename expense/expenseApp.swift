//
//  expenseApp.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI
import SwiftData

@main
struct expenseApp: App {
    @State private var showLaunchScreen = true
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Receipt.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .opacity(showLaunchScreen ? 0 : 1)
                
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showLaunchScreen = false
                                }
                            }
                        }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

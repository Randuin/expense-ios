//
//  MainTabView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var syncManager = SyncManager()
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Receipt> { !$0.isProcessed }) private var unprocessedReceipts: [Receipt]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }
                .tag(0)
            
            BacklogView()
                .tabItem {
                    Label("Backlog", systemImage: "tray.full")
                }
                .badge(unprocessedReceipts.count > 0 ? unprocessedReceipts.count : 0)
                .tag(1)
            
            NavigationStack {
                ReceiptListView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(2)
        }
        .accentColor(.blue)
        .overlay(alignment: .top) {
            // Sync status indicator
            if syncManager.isSyncing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.9))
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            syncManager.setModelContext(modelContext)
            
            // Perform initial sync if authenticated
            if authManager.isAuthenticated {
                Task {
                    await syncManager.performFullSync()
                }
            }
        }
        .environmentObject(syncManager)
    }
}
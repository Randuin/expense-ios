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
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                QuickCaptureView()
            }
            .tabItem {
                Label("Capture", systemImage: "camera.fill")
            }
            .tag(0)
            
            NavigationStack {
                ReceiptListView()
            }
            .tabItem {
                Label("Receipts", systemImage: "receipt")
            }
            .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .overlay(alignment: .top) {
            // Sync status indicator
            VStack(spacing: 8) {
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
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if syncManager.backgroundUploadCount > 0 {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.caption2)
                        Text("\(syncManager.backgroundUploadCount) uploading")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if let error = syncManager.syncError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                        Text("Sync failed")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 50)
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
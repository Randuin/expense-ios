//
//  MainTabView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }
                .tag(0)
            
            NavigationStack {
                ReceiptListView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(1)
        }
        .accentColor(.blue)
    }
}
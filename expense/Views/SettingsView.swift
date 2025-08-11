import SwiftUI

struct SettingsView: View {
    @AppStorage("useLocalhost") private var useLocalhost = false
    @State private var showingRestartAlert = false
    @EnvironmentObject private var syncManager: SyncManager
    @State private var isManualSyncing = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sync & Storage") {
                    HStack {
                        Text("Upload Queue")
                        Spacer()
                        if syncManager.backgroundUploadCount > 0 {
                            HStack {
                                Text("\(syncManager.backgroundUploadCount)")
                                    .foregroundColor(.orange)
                                Image(systemName: "icloud.and.arrow.up")
                                    .foregroundColor(.orange)
                            }
                        } else {
                            Text("All synced")
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack {
                        Text("Sync Status")
                        Spacer()
                        if syncManager.isSyncing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Syncing...")
                                    .foregroundColor(.blue)
                            }
                        } else if let error = syncManager.syncError {
                            Text("Failed")
                                .foregroundColor(.red)
                        } else {
                            Text("Ready")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            isManualSyncing = true
                            await syncManager.retryFailedUploads()
                            isManualSyncing = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                        }
                    }
                    .disabled(syncManager.isSyncing || isManualSyncing)
                    
                    if syncManager.backgroundUploadCount > 0 {
                        Button(action: {
                            syncManager.clearUploadQueue()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Clear Upload Queue")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if let error = syncManager.syncError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(2)
                    }
                }
                
                Section("API Configuration") {
                    HStack {
                        Text("Environment")
                        Spacer()
                        Text(useLocalhost ? "Development" : "Production")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Current API")
                        Spacer()
                        Text(currentAPIURL)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    // Allow switching to localhost for development testing
                    Toggle("Use Local Development Server", isOn: $useLocalhost)
                        .onChange(of: useLocalhost) { oldValue, newValue in
                            AppConfig.customBaseURL = newValue ? AppConfig.localhostURL : nil
                            showingRestartAlert = true
                        }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Restart Required", isPresented: $showingRestartAlert) {
                Button("OK") { }
            } message: {
                Text("Please restart the app for the API change to take full effect.")
            }
        }
    }
    
    private var currentAPIURL: String {
        let url = AppConfig.customBaseURL ?? AppConfig.baseURL
        return url.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }
}

#Preview {
    SettingsView()
}
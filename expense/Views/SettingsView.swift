import SwiftUI

struct SettingsView: View {
    @AppStorage("useLocalhost") private var useLocalhost = false
    @State private var showingRestartAlert = false
    
    var body: some View {
        NavigationView {
            Form {
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
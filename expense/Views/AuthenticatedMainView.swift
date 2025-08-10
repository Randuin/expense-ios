import SwiftUI

struct AuthenticatedMainView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
        .onOpenURL { url in
            // Handle OAuth callback URL
            if url.scheme == "expense" && url.host == "auth" {
                Task {
                    await authManager.handleAuthCallback(url)
                }
            }
        }
    }
}

#Preview {
    AuthenticatedMainView()
}
import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "receipt")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Expense Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to sync your receipts across devices")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if authManager.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
            } else {
                Button(action: {
                    Task {
                        await authManager.signInWithGoogle()
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Sign in with Google")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Text("Your data is stored securely and synced across your devices")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .navigationBarHidden(true)
    }
}

#Preview {
    AuthView()
}
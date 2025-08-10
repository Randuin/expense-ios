import Foundation
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:3000"
    private let keychain = KeychainHelper.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let token = keychain.getAccessToken() {
            Task {
                await validateToken(token)
            }
        }
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let presentingViewController = await UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
                throw AuthError.invalidResponse
            }
            
            // Use Google Sign-In SDK
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            // Get ID token to send to backend
            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.invalidResponse
            }
            
            // Send ID token to backend for verification and JWT generation
            await exchangeGoogleToken(idToken: idToken, user: user)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func exchangeGoogleToken(idToken: String, user: GIDGoogleUser) async {
        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/google/verify")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = [
                "idToken": idToken,
                "email": user.profile?.email ?? "",
                "name": user.profile?.name ?? "",
                "picture": user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw AuthError.invalidResponse
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store tokens securely (tokens come from cookies, so they're handled by the backend)
            self.user = authResponse.user
            self.isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func handleAuthCallback(_ url: URL) async {
        // This would be called when the app receives the callback URL
        // Implementation depends on URL scheme configuration
        isLoading = true
        
        do {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
                throw AuthError.noAuthCode
            }
            
            // Exchange code for tokens via backend
            let callbackURL = URL(string: "\(baseURL)/auth/callback?code=\(code)")!
            let (data, _) = try await URLSession.shared.data(from: callbackURL)
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store tokens securely
            keychain.storeTokens(
                accessToken: authResponse.accessToken,
                refreshToken: authResponse.refreshToken
            )
            
            self.user = authResponse.user
            self.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshToken() async {
        guard let refreshToken = keychain.getRefreshToken() else {
            signOut()
            return
        }
        
        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/refresh")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            keychain.storeTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            
            self.user = response.user
            self.isAuthenticated = true
        } catch {
            signOut()
        }
    }
    
    private func validateToken(_ token: String) async {
        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/me")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(UserResponse.self, from: data)
            
            self.user = response.user
            self.isAuthenticated = true
        } catch {
            // Token is invalid, try to refresh
            await refreshToken()
        }
    }
    
    func signOut() {
        keychain.clearTokens()
        user = nil
        isAuthenticated = false
    }
}

// MARK: - Models
struct User: Codable {
    let id: String
    let email: String
    let name: String
    let picture: String?
}

struct AuthURLResponse: Codable {
    let authUrl: String
    let message: String
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String?
    let refreshToken: String?
    let message: String
}

struct UserResponse: Codable {
    let user: User
}

enum AuthError: LocalizedError {
    case invalidURL
    case noAuthCode
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noAuthCode:
            return "No authorization code received"
        case .networkError:
            return "Network error occurred"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}
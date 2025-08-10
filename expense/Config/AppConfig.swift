import Foundation

struct AppConfig {
    // Always use production URL for all builds
    static let baseURL = "https://expense-backend-one-nu.vercel.app"
    static let environment = "Production"
    
    // You can override with a custom URL if needed
    static var customBaseURL: String? = nil
    
    static var currentBaseURL: String {
        return customBaseURL ?? baseURL
    }
    
    // Keep localhost as an option that can be enabled in Settings if needed
    static let localhostURL = "http://localhost:3000"
}
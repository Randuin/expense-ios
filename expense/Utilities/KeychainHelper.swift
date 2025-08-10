import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let accessTokenKey = "expense_access_token"
    private let refreshTokenKey = "expense_refresh_token"
    private let service = "expense-tracker"
    
    private init() {}
    
    func storeTokens(accessToken: String?, refreshToken: String?) {
        if let accessToken = accessToken {
            store(key: accessTokenKey, value: accessToken)
        }
        if let refreshToken = refreshToken {
            store(key: refreshTokenKey, value: refreshToken)
        }
    }
    
    func getAccessToken() -> String? {
        return retrieve(key: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return retrieve(key: refreshTokenKey)
    }
    
    func clearTokens() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }
    
    private func store(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain store error: \(status)")
        }
    }
    
    private func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
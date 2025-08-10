import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:3000"
    private let keychain = KeychainHelper.shared
    
    private init() {}
    
    private func authenticatedRequest(url: URL, method: HTTPMethod = .GET, body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let accessToken = keychain.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle 401 - try to refresh token
        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            
            // Retry with new token
            if let newToken = keychain.getAccessToken() {
                request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
                
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                return (retryData, retryHttpResponse)
            }
        }
        
        return (data, httpResponse)
    }
    
    private func refreshTokenIfNeeded() async throws {
        guard let refreshToken = keychain.getRefreshToken() else {
            throw APIError.noRefreshToken
        }
        
        var request = URLRequest(url: URL(string: "\(baseURL)/api/auth/refresh")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.tokenRefreshFailed
        }
        
        // Note: The refresh endpoint uses cookies, so tokens are automatically updated
        // In a production app, you might want to extract new tokens from response
    }
    
    // MARK: - Receipt API Methods
    
    func getReceipts(filters: ReceiptFilters? = nil) async throws -> [ReceiptResponse] {
        var urlComponents = URLComponents(string: "\(baseURL)/api/receipts")!
        
        if let filters = filters {
            var queryItems: [URLQueryItem] = []
            
            if let category = filters.category {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            if let status = filters.submissionStatus {
                queryItems.append(URLQueryItem(name: "status", value: status))
            }
            if let processed = filters.isProcessed {
                queryItems.append(URLQueryItem(name: "processed", value: String(processed)))
            }
            if let startDate = filters.startDate {
                queryItems.append(URLQueryItem(name: "start_date", value: ISO8601DateFormatter().string(from: startDate)))
            }
            if let endDate = filters.endDate {
                queryItems.append(URLQueryItem(name: "end_date", value: ISO8601DateFormatter().string(from: endDate)))
            }
            if let limit = filters.limit {
                queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            
            urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        }
        
        let (data, response) = try await authenticatedRequest(url: urlComponents.url!)
        
        guard response.statusCode == 200 else {
            throw APIError.requestFailed(response.statusCode)
        }
        
        let receiptsResponse = try JSONDecoder().decode(ReceiptsResponse.self, from: data)
        return receiptsResponse.receipts
    }
    
    func createReceipt(_ receipt: ReceiptRequest) async throws -> ReceiptResponse {
        let url = URL(string: "\(baseURL)/api/receipts")!
        let data = try JSONEncoder().encode(receipt)
        
        let (responseData, response) = try await authenticatedRequest(url: url, method: .POST, body: data)
        
        guard response.statusCode == 201 else {
            throw APIError.requestFailed(response.statusCode)
        }
        
        let createResponse = try JSONDecoder().decode(CreateReceiptResponse.self, from: responseData)
        return createResponse.receipt
    }
    
    func updateReceipt(id: String, updates: ReceiptRequest) async throws -> ReceiptResponse {
        let url = URL(string: "\(baseURL)/api/receipts/\(id)")!
        let data = try JSONEncoder().encode(updates)
        
        let (responseData, response) = try await authenticatedRequest(url: url, method: .PUT, body: data)
        
        guard response.statusCode == 200 else {
            throw APIError.requestFailed(response.statusCode)
        }
        
        let updateResponse = try JSONDecoder().decode(UpdateReceiptResponse.self, from: responseData)
        return updateResponse.receipt
    }
    
    func deleteReceipt(id: String) async throws {
        let url = URL(string: "\(baseURL)/api/receipts/\(id)")!
        let (_, response) = try await authenticatedRequest(url: url, method: .DELETE)
        
        guard response.statusCode == 200 else {
            throw APIError.requestFailed(response.statusCode)
        }
    }
    
    func uploadReceiptWithImage(receipt: ReceiptRequest, imageData: Data) async throws -> ReceiptResponse {
        let url = URL(string: "\(baseURL)/api/receipts/upload")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let accessToken = keychain.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add receipt fields
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"amount\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(receipt.amount)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"merchant\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(receipt.merchant)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(receipt.category)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"notes\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(receipt.notes)\r\n".data(using: .utf8)!)
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"receipt.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.uploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(CreateReceiptResponse.self, from: responseData)
        return uploadResponse.receipt
    }
}

// MARK: - Models
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

struct ReceiptFilters {
    let category: String?
    let submissionStatus: String?
    let isProcessed: Bool?
    let startDate: Date?
    let endDate: Date?
    let limit: Int?
    
    init(category: String? = nil, submissionStatus: String? = nil, isProcessed: Bool? = nil, 
         startDate: Date? = nil, endDate: Date? = nil, limit: Int? = nil) {
        self.category = category
        self.submissionStatus = submissionStatus
        self.isProcessed = isProcessed
        self.startDate = startDate
        self.endDate = endDate
        self.limit = limit
    }
}

struct ReceiptRequest: Codable {
    let id: String?
    let amount: Double
    let merchant: String
    let category: String
    let notes: String
    let submissionStatus: String?
    let taxAmount: Double?
    let paymentMethod: String?
    let isProcessed: Bool?
    let timestamp: String?
    let submissionDate: String?
}

struct ReceiptResponse: Codable {
    let id: String
    let userId: String
    let timestamp: String
    let imageData: String?
    let amount: Double
    let merchant: String
    let category: String
    let notes: String
    let submissionStatus: String
    let submissionDate: String?
    let taxAmount: Double?
    let paymentMethod: String?
    let isProcessed: Bool
    let createdAt: String
    let updatedAt: String
}

struct ReceiptsResponse: Codable {
    let receipts: [ReceiptResponse]
}

struct CreateReceiptResponse: Codable {
    let receipt: ReceiptResponse
    let message: String
}

struct UpdateReceiptResponse: Codable {
    let receipt: ReceiptResponse
    let message: String
}

enum APIError: LocalizedError {
    case invalidResponse
    case noRefreshToken
    case tokenRefreshFailed
    case requestFailed(Int)
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .requestFailed(let code):
            return "Request failed with status code: \(code)"
        case .uploadFailed:
            return "Failed to upload receipt"
        }
    }
}
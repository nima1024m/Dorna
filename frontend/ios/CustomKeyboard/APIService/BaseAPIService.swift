import Foundation

// MARK: - Base API Service
class BaseAPIService {
    static let shared = BaseAPIService()
    private let appGroupManager = AppGroupManager.shared
    
    // Base URL for all API endpoints
    let baseURL = "https://dorna.thepersa.com/v1/assistant"
    
    // Refresh token management
    private static var isRefreshing = false
    private static var isRefreshed = false
    private static let refreshLock = NSLock()
    
    private init() {}
    
    // Helper method to build full URL for specific endpoints
    func buildURL(for endpoint: String) -> String {
        return "\(baseURL)/\(endpoint)"
    }
    
    // Helper method to create URLRequest with bearer token header
    func createRequest(for endpoint: String, httpMethod: String = "POST") -> URLRequest? {
        let fullURL = buildURL(for: endpoint)
        guard let url = URL(string: fullURL) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add bearer token if available
        if let accessToken = appGroupManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            Logger.debug("BaseAPIService: Added bearer token to request=\(accessToken)")
        }
        
        return request
    }
    
    // Helper method to create URLRequest with bearer token header for custom URLs
    func createRequestWithURL(for fullURL: String, httpMethod: String = "POST") -> URLRequest? {
        guard let url = URL(string: fullURL) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add bearer token if available
        if let accessToken = appGroupManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            Logger.debug("BaseAPIService: Added bearer token to request=\(accessToken)")
        }
        
        return request
    }
    
    // MARK: - Token Refresh
    
    /// Executes a request with automatic token refresh on 401 errors
    /// - Parameter request: The URLRequest to execute
    /// - Returns: A tuple containing the response data and HTTPURLResponse
    func executeRequestWithTokenRefresh(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // If not 401, return the response as-is
            if httpResponse.statusCode != 401 {
                return (data, httpResponse)
            }
            
            Logger.debug("BaseAPIService: Received 401, attempting token refresh")
            
            // Handle 401 error with token refresh
            return try await handle401Error(originalRequest: request)
            
        } catch let error as APIError {
            throw error
        } catch {
            throw BaseAPIService.convertErrorToAPIError(error)
        }
    }
    
    /// Handles 401 errors by refreshing the token and retrying the request
    /// - Parameter originalRequest: The original request that received 401
    /// - Returns: A tuple containing the response data and HTTPURLResponse
    private func handle401Error(originalRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        BaseAPIService.refreshLock.lock()
        let wasRefreshing = BaseAPIService.isRefreshing
        
        // If another task is already refreshing, wait for it
        if wasRefreshing {
            BaseAPIService.refreshLock.unlock()
            
            // Wait for the ongoing refresh to complete
            while BaseAPIService.isRefreshing {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            
            // If refresh was successful, retry the original request
            if BaseAPIService.isRefreshed {
                Logger.debug("BaseAPIService: Token refresh completed by another task, retrying request")
                return try await retryRequestWithNewToken(originalRequest)
            } else {
                Logger.debug("BaseAPIService: Token refresh failed, throwing 401 error")
                throw APIError.httpError(statusCode: 401)
            }
        }
        
        // Start token refresh process
        BaseAPIService.isRefreshing = true
        BaseAPIService.isRefreshed = false
        BaseAPIService.refreshLock.unlock()
        
        defer {
            BaseAPIService.refreshLock.lock()
            BaseAPIService.isRefreshing = false
            BaseAPIService.refreshLock.unlock()
        }
        
        do {
            // Attempt to refresh the token
            let refreshSuccess = try await refreshToken()
            
            if refreshSuccess {
                BaseAPIService.refreshLock.lock()
                BaseAPIService.isRefreshed = true
                BaseAPIService.refreshLock.unlock()
                
                Logger.debug("BaseAPIService: Token refreshed successfully, retrying request")
                return try await retryRequestWithNewToken(originalRequest)
            } else {
                Logger.debug("BaseAPIService: Token refresh failed")
                throw APIError.httpError(statusCode: 401)
            }
        } catch {
            Logger.debug("BaseAPIService: Error during token refresh: \(error.localizedDescription)")
            throw APIError.httpError(statusCode: 401)
        }
    }
    
    /// Retries the original request with the new access token
    /// - Parameter originalRequest: The original request to retry
    /// - Returns: A tuple containing the response data and HTTPURLResponse
    private func retryRequestWithNewToken(_ originalRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var retryRequest = originalRequest
        
        // Update with new access token
        if let newAccessToken = appGroupManager.getAccessToken() {
            retryRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")
            Logger.debug("BaseAPIService: Retrying request with new token")
        }
        
        let (data, response) = try await URLSession.shared.data(for: retryRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        return (data, httpResponse)
    }
    
    /// Refreshes the access token using the refresh token
    /// - Returns: True if successful, false otherwise
    private func refreshToken() async throws -> Bool {
        guard let refreshToken = appGroupManager.getRefreshToken() else {
            Logger.debug("BaseAPIService: No refresh token available")
            return false
        }
        
        // Build refresh token URL (change /assistant to /auth for refresh endpoint)
        let refreshURL = "https://dorna.thepersa.com/v1/auth/refresh"
        
        guard let url = URL(string: refreshURL) else {
            Logger.debug("BaseAPIService: Invalid refresh URL")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        Logger.debug("BaseAPIService: Making refresh token request")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.debug("BaseAPIService: Invalid response from refresh endpoint")
                return false
            }
            
            Logger.debug("BaseAPIService: Refresh token response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    // Refresh token is expired or invalid, clear tokens
                    Logger.debug("BaseAPIService: Refresh token expired or invalid, clearing tokens")
                    appGroupManager.clearTokens()
                }
                return false
            }
            
            // Decode the response
            let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
            
            if refreshResponse.status == "OK" {
                // Save the new tokens
                appGroupManager.saveTokens(accessToken: refreshResponse.accessToken, refreshToken: refreshResponse.refreshToken)
                Logger.debug("BaseAPIService: Tokens refreshed and saved successfully")
                return true
            }
            
            return false
        } catch {
            Logger.debug("BaseAPIService: Error during token refresh: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Error Handling
    
    /// Converts any error to APIError type for consistent error handling
    /// - Parameter error: The error to convert
    /// - Returns: An APIError instance
    static func convertErrorToAPIError(_ error: Error) -> APIError {
        // If it's already an APIError, return it
        if let existingAPIError = error as? APIError {
            return existingAPIError
        }
        
        // Convert other errors to appropriate APIError type
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot, .clientCertificateRejected, .clientCertificateRequired:
                return .networkError(error)
            default:
                // For other URL errors, check if they're network-related
                if urlError.code.rawValue < 0 {
                    // Negative codes are typically network/system errors, not HTTP status codes
                    return .networkError(error)
                } else {
                    return .httpError(statusCode: urlError.code.rawValue)
                }
            }
        } else if let decodingError = error as? DecodingError {
            return .decodingError(error)
        } else {
            // For any other unknown errors, treat as service error
            return .invalidResponse
        }
    }
    
    /// Gets the appropriate error message string for UI display
    /// - Parameter error: The error to get the message for
    /// - Returns: A localized error message string
    static func getErrorMessageString(for error: Error) -> String {
        let apiError = convertErrorToAPIError(error)
        if apiError.is422Error {
            return "422"
        }
        return apiError.isNetworkError ? "network_error" : "service_error"
    }
}

// MARK: - API Error Types
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case http422(queryId: String, message: String)
    case decodingError(Error)
    case networkError(Error)
    
    var isNetworkError: Bool {
        switch self {
        case .invalidURL, .invalidResponse, .decodingError:
            return false
        case .httpError(let statusCode):
            return statusCode == 422 ? false : statusCode >= 500
        case .http422:
            return false
        case .networkError:
            return true
        }
    }
    var is422Error: Bool {
        switch self {
        case .invalidURL, .invalidResponse, .decodingError:
            return false
        case .httpError(let statusCode):
            return statusCode == 422 ? true : false
        case .http422:
            return true
        case .networkError:
            return false
        }
    }

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .http422(_, let message):
            return message
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Refresh Token Response Model
struct RefreshTokenResponse: Codable {
    let status: String
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}



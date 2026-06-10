import Foundation

// MARK: - Translation API Service
class TranslationAPIService {
    static let shared = TranslationAPIService()
    private let baseAPIService = BaseAPIService.shared
    private let appGroupManager = AppGroupManager.shared
    
    private init() {}
    
    func translateText(content: String, targetLanguage: String) async throws -> TranslationAPIResponse {
        Logger.debug("TranslationAPI: Starting translation for content: '\(content)' to language: '\(targetLanguage)'")

        // Try cached value first (valid for 5 minutes)
        let cacheKey = "\(content)_\(targetLanguage)"
        if let cache = appGroupManager.loadTranslationCache(for: cacheKey) {
            let age = Date().timeIntervalSince1970 - cache.timestamp
            if age <= 300 {
                Logger.debug("TranslationAPI: Using cached response (age: \(Int(age))s)")
                return cache.response
            }
        }
        
        guard var request = baseAPIService.createRequest(for: "translate") else {
            Logger.debug("TranslationAPI: Error - Failed to create request")
            throw APIError.invalidURL
        }
        
        let requestBody = TranslationRequest(content: content, targetLanguage: targetLanguage)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        Logger.debug("TranslationAPI: Making POST request to: \(request.url?.absoluteString ?? "unknown")")
        Logger.debug("TranslationAPI: Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        
        // Use executeRequestWithTokenRefresh for automatic 401 handling
        let (data, httpResponse) = try await baseAPIService.executeRequestWithTokenRefresh(request)
        
        Logger.debug("TranslationAPI: Received HTTP response with status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            Logger.debug("TranslationAPI: Error - HTTP error with status code: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 422 {
                // Try to decode error payload to extract query_id and message
                if let parsed = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let queryId = (parsed["query_id"] as? String) ?? ""
                    let message = (parsed["message"] as? String) ?? "HTTP 422"
                    Logger.debug("TranslationAPI: Parsed 422 error with query_id: \(queryId), message: \(message)")
                    throw APIError.http422(queryId: queryId, message: message)
                }
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        Logger.debug("TranslationAPI: Response data received, size: \(data.count) bytes")
        
        do {
            let translationResponse = try JSONDecoder().decode(TranslationAPIResponse.self, from: data)
            Logger.debug("TranslationAPI: Successfully decoded response - Status: \(translationResponse.status), Task: \(translationResponse.task), QueryID: \(translationResponse.queryId), Translated: '\(translationResponse.translated)', correctInput: '\(translationResponse.correctInput)'")
            
            // Save to cache with current timestamp
            appGroupManager.saveTranslationCache(for: cacheKey, response: translationResponse)
            return translationResponse
        } catch {
            Logger.debug("TranslationAPI: Error - Failed to decode response: \(error.localizedDescription)")
            Logger.debug("TranslationAPI: Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Request/Response Models
struct TranslationRequest: Codable {
    let content: String
    let targetLanguage: String
    
    enum CodingKeys: String, CodingKey {
        case content
        case targetLanguage = "target_lang"
    }
}

struct TranslationAPIResponse: Codable {
    let status: String
    let task: String
    let queryId: String
    let message: String?
    let translated: String
    let correctInput: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case task
        case queryId = "query_id"
        case message
        case translated
        case correctInput = "correct_input"
    }
}



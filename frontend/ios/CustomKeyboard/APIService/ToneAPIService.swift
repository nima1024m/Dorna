import Foundation

// MARK: - Tone API Service
class ToneAPIService {
    static let shared = ToneAPIService()
    private let baseAPIService = BaseAPIService.shared
    private let appGroupManager = AppGroupManager.shared
    
    private init() {}
    
    func adjustTone(content: String, targetTone: String, parentToneId: String? = nil) async throws -> ToneAPIResponse {
        var content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.debug("ToneAPI: Starting tone adjustment for content: '\(content)' with target tone: '\(targetTone)' parentToneId: \(parentToneId ?? "nil")")

        // If content equals last applied tone and tone type matches within 5 minutes, skip API
        if parentToneId == nil, let last = appGroupManager.loadLastAppliedTone() {
            let isSameText = last.text.trimmingCharacters(in: .whitespacesAndNewlines) == content.trimmingCharacters(in: .whitespacesAndNewlines)
            let isSameTone = (last.toneType?.lowercased() ?? "") == targetTone.lowercased()
            let age = Date().timeIntervalSince1970 - last.timestamp
            if isSameText && isSameTone && age <= 300 {
                Logger.debug("ToneAPI: Skipping API; content equals last applied and tone type matches within 5 minutes")
                return ToneAPIResponse(status: "ok", task: "tone", queryId: "cached-noop", adjusted: content)
            }
        }

//        // Try cached value first (valid for 5 minutes)
//        if parentToneId == nil, let cache = appGroupManager.loadToneCache(for: content, targetTone: targetTone) {
//            let age = Date().timeIntervalSince1970 - cache.timestamp
//            if age <= 300 {
//                Logger.debug("ToneAPI: Using cached response (age: \(Int(age))s)")
//                return cache.response
//            }
//        }

        guard var request = baseAPIService.createRequest(for: "tone") else {
            Logger.debug("ToneAPI: Error - Failed to create request")
            throw APIError.invalidURL
        }
        
        let requestBody = ToneRequest(content: content, targetTone: targetTone, parentToneId: parentToneId)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        Logger.debug("ToneAPI: Making POST request to: \(request.url?.absoluteString ?? "unknown")")
        Logger.debug("ToneAPI: Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        
        // Use executeRequestWithTokenRefresh for automatic 401 handling
        let (data, httpResponse) = try await baseAPIService.executeRequestWithTokenRefresh(request)
        
        Logger.debug("ToneAPI: Received HTTP response with status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            Logger.debug("ToneAPI: Error - HTTP error with status code: \(httpResponse.statusCode)")
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        Logger.debug("ToneAPI: Response data received, size: \(data.count) bytes")
        
        do {
            let toneResponse = try JSONDecoder().decode(ToneAPIResponse.self, from: data)
            Logger.debug("ToneAPI: Successfully decoded response - Status: \(toneResponse.status), Task: \(toneResponse.task), QueryID: \(toneResponse.queryId), Adjusted: '\(toneResponse.adjusted)'")
            
//            // Save to cache with current timestamp unless this is a rephrase request
//            if parentToneId == nil {
//                appGroupManager.saveToneCache(for: content, targetTone: targetTone, response: toneResponse)
//            }
            return toneResponse
        } catch {
            Logger.debug("ToneAPI: Error - Failed to decode response: \(error.localizedDescription)")
            Logger.debug("ToneAPI: Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Request/Response Models
struct ToneRequest: Codable {
    let content: String
    let targetTone: String
    let parentToneId: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case targetTone = "target_tone"
        case parentToneId = "parent_tone_id"
    }
}

struct ToneAPIResponse: Codable {
    let status: String
    let task: String
    let queryId: String
    let adjusted: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case task
        case queryId = "query_id"
        case adjusted
    }
}




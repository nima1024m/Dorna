//
//  TrackerAPIService.swift
//  CustomKeyboard
//
//  Created by Royal Macbook on 5/1/25.
//

import Foundation

class TrackerAPIService {
    static let shared = TrackerAPIService()
    private let baseAPIService = BaseAPIService.shared
    private let appGroupManager = AppGroupManager.shared
    private var trackBaseURL: String {
        // Derive track base from shared baseURL by swapping "/assistant" with "/track"
        return baseAPIService.baseURL.replacingOccurrences(of: "/assistant", with: "/track")
    }
    
    private init() {}
    
    func trackGrammarAction(correctionId: String, action: TrackerAction) {
        guard appGroupManager.getCollectDataConsent() else { return }
        // Call the tracking API in the background without blocking the UI
        Task.detached(priority: .background) { [weak self] in
            await self?.performGrammarTrackingRequest(correctionId: correctionId, action: action)
        }
    }
    
    func trackToneAction(toneId: String, action: TrackerAction) {
        guard appGroupManager.getCollectDataConsent() else { return }
        // Call the tracking API in the background without blocking the UI
        Task.detached(priority: .background) { [weak self] in
            await self?.performToneTrackingRequest(toneId: toneId, action: action)
        }
    }
    
    func trackTranslationAction(translateId: String, action: TrackerAction) {
        guard appGroupManager.getCollectDataConsent() else { return }
        // Call the tracking API in the background without blocking the UI
        Task.detached(priority: .background) { [weak self] in
            await self?.performTranslationTrackingRequest(translateId: translateId, action: action)
        }
    }
    
    private func performGrammarTrackingRequest(correctionId: String, action: TrackerAction) async {
        let fullURL = "\(trackBaseURL)/grammar"
        guard var request = baseAPIService.createRequestWithURL(for: fullURL) else {
            Logger.debug("TrackerAPIService: Failed to create request")
            return
        }
        
        let requestBody = GrammarTrackingRequest(
            correctionId: correctionId,
            action: action.rawValue
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            Logger.debug("GrammarAPI: Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
            
            // Use executeRequestWithTokenRefresh for automatic 401 handling
            let (data, httpResponse) = try await baseAPIService.executeRequestWithTokenRefresh(request)
            
            Logger.debug("TrackerAPIService: Response status code: \(httpResponse.statusCode)")
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            Logger.debug("TrackerAPIService: Response data: \(responseString)")
        } catch {
            Logger.debug("TrackerAPIService: Request failed - \(error)")
        }
    }
    
    private func performToneTrackingRequest(toneId: String, action: TrackerAction) async {
        let fullURL = "\(trackBaseURL)/tone"
        guard var request = baseAPIService.createRequestWithURL(for: fullURL) else {
            Logger.debug("TrackerAPIService: Failed to create tone request")
            return
        }
        
        let requestBody = ToneTrackingRequest(
            toneId: toneId,
            action: action.rawValue
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            Logger.debug("ToneTrackerAPI: Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
            
            // Use executeRequestWithTokenRefresh for automatic 401 handling
            let (data, httpResponse) = try await baseAPIService.executeRequestWithTokenRefresh(request)
            
            Logger.debug("TrackerAPIService: Tone response status code: \(httpResponse.statusCode)")
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            Logger.debug("TrackerAPIService: Tone response data: \(responseString)")
        } catch {
            Logger.debug("TrackerAPIService: Tone request failed - \(error)")
        }
    }
    
    private func performTranslationTrackingRequest(translateId: String, action: TrackerAction) async {
        let fullURL = "\(trackBaseURL)/translate"
        guard var request = baseAPIService.createRequestWithURL(for: fullURL) else {
            Logger.debug("TrackerAPIService: Failed to create translation request")
            return
        }
        
        let requestBody = TranslationTrackingRequest(
            translateId: translateId,
            action: action.rawValue
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            Logger.debug("TranslationTrackerAPI: Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
            
            // Use executeRequestWithTokenRefresh for automatic 401 handling
            let (data, httpResponse) = try await baseAPIService.executeRequestWithTokenRefresh(request)
            
            Logger.debug("TrackerAPIService: Translation response status code: \(httpResponse.statusCode)")
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            Logger.debug("TrackerAPIService: Translation response data: \(responseString)")
        } catch {
            Logger.debug("TrackerAPIService: Translation request failed - \(error)")
        }
    }
}

// MARK: - Supporting Types

enum TrackerAction: String, Codable {
    case approved = "approved"
    case rejected = "rejected"
}

struct GrammarTrackingRequest: Codable {
    let correctionId: String
    let action: String
    
    enum CodingKeys: String, CodingKey {
        case correctionId = "correction_id"
        case action
    }
}

struct ToneTrackingRequest: Codable {
    let toneId: String
    let action: String
    
    enum CodingKeys: String, CodingKey {
        case toneId = "tone_id"
        case action
    }
}

struct TranslationTrackingRequest: Codable {
    let translateId: String
    let action: String
    
    enum CodingKeys: String, CodingKey {
        case translateId = "translate_id"
        case action
    }
}

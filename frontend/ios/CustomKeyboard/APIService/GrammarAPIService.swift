import Foundation

// MARK: - Grammar API Service
class GrammarAPIService {
    static let shared = GrammarAPIService()
    private let baseAPIService = BaseAPIService.shared
    private let appGroupManager = AppGroupManager.shared
    private var debounceTask: Task<GrammarAPIResponse, Error>?
    private let debounceIntervalNanoseconds: UInt64 = 1_000_000_000
    
    private init() {}
    
    func checkGrammar(content: String, onAPICall: (() -> Void)? = nil) async throws -> GrammarAPIResponse {
        var content = content.trimmingCharacters(in: .whitespacesAndNewlines)

        Logger.debug("GrammarAPI: Starting grammar check for content: '\(content)'")

        // Try cached value first (valid for 5 minutes)
        if let cache = appGroupManager.loadGrammarCache(for: content) {
            let age = Date().timeIntervalSince1970 - cache.timestamp
            if age <= 300 {
                Logger.debug("GrammarAPI: Using cached response (age: \(Int(age))s)")
                return cache.response
            }
        }
        
        // If content equals last applied grammar within 5 minutes, only skip API if no fresh cache exists
        if let last = appGroupManager.loadLastAppliedGrammar() {
            let isSame = last.text.trimmingCharacters(in: .whitespacesAndNewlines) == content.trimmingCharacters(in: .whitespacesAndNewlines)
            let age = Date().timeIntervalSince1970 - last.timestamp
            if isSame && age <= 300 {
                Logger.debug("GrammarAPI: Content equals last applied within 5 minutes and no valid cache; returning no changes")
                // Return an empty no-change response contract compatible with caller
                return GrammarAPIResponse(status: "ok", task: "grammar", queryId: "cached-noop", corrections: [])
            }
        }
        
        // At this point, no valid cache and no short-circuit. Debounce the network call by 1 second.
        debounceTask?.cancel()
        onAPICall?()
        let task = Task<GrammarAPIResponse, Error> { [baseAPIService, appGroupManager] in
            try await Task.sleep(nanoseconds: debounceIntervalNanoseconds)
            onAPICall?()


            guard var request = baseAPIService.createRequest(for: "grammar") else {
                Logger.debug("GrammarAPI: Error - Failed to create request")
                throw APIError.invalidURL
            }
            
            let requestBody = GrammarRequest(content: content)
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            Logger.debug("GrammarAPI: Making POST request to: \(request.url?.absoluteString ?? "unknown")")
            Logger.debug("GrammarAPI: Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
            
            // Use executeRequestWithTokenRefresh for automatic 401 handling
            let (data, httpResponse) = try await baseAPIService.executeRequestWithTokenRefresh(request)
            
            Logger.debug("GrammarAPI: Received HTTP response with status code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                Logger.debug("GrammarAPI: Error - HTTP error with status code: \(httpResponse.statusCode)")
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            Logger.debug("GrammarAPI: Response data received, size: \(data.count) bytes")
            
            do {
                let grammarResponse = try JSONDecoder().decode(GrammarAPIResponse.self, from: data)
                Logger.debug("GrammarAPI: Successfully decoded response - Status: \(grammarResponse.status), Task: \(grammarResponse.task), QueryID: \(grammarResponse.queryId), Corrections count: \(grammarResponse.corrections.count)")
                
                // Log each correction
                for (index, correction) in grammarResponse.corrections.enumerated() {
                    Logger.debug("GrammarAPI: Correction \(index + 1) - Changed: \(correction.changed), Original: '\(correction.original)', Suggestion: '\(correction.suggestion)', Explanation: '\(correction.explanation)'")
                }
                
                // Save to cache with current timestamp
                appGroupManager.saveGrammarCache(for: content, response: grammarResponse)
                return grammarResponse
            } catch {
                Logger.debug("GrammarAPI: Error - Failed to decode response: \(error.localizedDescription)")
                Logger.debug("GrammarAPI: Raw response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw APIError.decodingError(error)
            }
        }
        debounceTask = task
        return try await task.value
    }
    
    deinit {
        // Cancel any pending debounce task to prevent memory leaks
        debounceTask?.cancel()
    }
}

// MARK: - Helper Extensions
extension GrammarAPIService {
    // Build a plain text suggestion by:
    // - keeping text inside <correct> and <spell>
    // - dropping text inside <wrong>
    // - keeping any plain text outside tags as-is
    func cleanedSuggestionText(from suggestion: String) -> String {
        var output = ""
        var currentIndex = suggestion.startIndex

        func consumeUntil(_ endTag: String) {
            if let range = suggestion[currentIndex...].range(of: endTag) {
                currentIndex = range.upperBound
            } else {
                currentIndex = suggestion.endIndex
            }
        }

        while currentIndex < suggestion.endIndex {
            if suggestion[currentIndex...].hasPrefix("<wrong>") {
                currentIndex = suggestion.index(currentIndex, offsetBy: 7)
                if let endRange = suggestion[currentIndex...].range(of: "</wrong>") {
                    currentIndex = endRange.upperBound
                } else {
                    // No closing tag; stop
                    break
                }
            } else if suggestion[currentIndex...].hasPrefix("<correct>") {
                currentIndex = suggestion.index(currentIndex, offsetBy: 9)
                if let endRange = suggestion[currentIndex...].range(of: "</correct>") {
                    output += String(suggestion[currentIndex..<endRange.lowerBound])
                    currentIndex = endRange.upperBound
                } else {
                    output += String(suggestion[currentIndex...])
                    break
                }
            } else if suggestion[currentIndex...].hasPrefix("<spell>") {
                currentIndex = suggestion.index(currentIndex, offsetBy: 7)
                if let endRange = suggestion[currentIndex...].range(of: "</spell>") {
                    output += String(suggestion[currentIndex..<endRange.lowerBound])
                    currentIndex = endRange.upperBound
                } else {
                    output += String(suggestion[currentIndex...])
                    break
                }
            } else if suggestion[currentIndex] == "<" {
                // Unknown tag - skip it conservatively
                // Try to jump past the next '>'
                if let closeIdx = suggestion[currentIndex...].firstIndex(of: ">") {
                    currentIndex = suggestion.index(after: closeIdx)
                } else {
                    break
                }
            } else {
                // Plain text
                if let nextTag = suggestion[currentIndex...].firstIndex(of: "<") {
                    output += String(suggestion[currentIndex..<nextTag])
                    currentIndex = nextTag
                } else {
                    output += String(suggestion[currentIndex...])
                    break
                }
            }
        }
        return output
    }
    // If suggestion text equals the user input (no tags present), it's effectively no change
    func isSuggestionSameAsInput(_ suggestion: String, input: String) -> Bool {
        if suggestion.contains("<wrong>") || suggestion.contains("<correct>") || suggestion.contains("<spell>") { return false }
        return suggestion.trimmingCharacters(in: .whitespacesAndNewlines) == input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parseSuggestionToWordOutputs(_ suggestion: String) -> [WordOutput] {
        var wordOutputs: [WordOutput] = []
        var currentIndex = suggestion.startIndex
        
        while currentIndex < suggestion.endIndex {
            if suggestion[currentIndex...].hasPrefix("<wrong>") {
                // Handle wrong word
                let wrongStart = suggestion.index(currentIndex, offsetBy: 7)
                if let wrongEnd = suggestion[wrongStart...].firstIndex(of: "<") {
                    let wrongWord = String(suggestion[wrongStart..<wrongEnd])
                    wordOutputs.append(WordOutput(value: wrongWord, state: .wrong))
                    
                    // Skip to end of wrong tag
                    if let wrongTagEnd = suggestion[wrongEnd...].firstIndex(of: ">") {
                        currentIndex = suggestion.index(after: wrongTagEnd)
                    } else {
                        currentIndex = wrongEnd
                    }
                } else {
                    currentIndex = wrongStart
                }
            } else if suggestion[currentIndex...].hasPrefix("<correct>") {
                // Handle corrected word
                let correctStart = suggestion.index(currentIndex, offsetBy: 9)
                if let correctEnd = suggestion[correctStart...].firstIndex(of: "<") {
                    let correctWord = String(suggestion[correctStart..<correctEnd])
                    wordOutputs.append(WordOutput(value: correctWord, state: .corrected))
                    
                    // Skip to end of correct tag
                    if let correctTagEnd = suggestion[correctEnd...].firstIndex(of: ">") {
                        currentIndex = suggestion.index(after: correctTagEnd)
                    } else {
                        currentIndex = correctEnd
                    }
                } else {
                    currentIndex = correctStart
                }
            } else if suggestion[currentIndex...].hasPrefix("<spell>") {
                // Handle spell-highlighted word
                let spellStart = suggestion.index(currentIndex, offsetBy: 7)
                if let spellEnd = suggestion[spellStart...].firstIndex(of: "<") {
                    let spellWord = String(suggestion[spellStart..<spellEnd])
                    wordOutputs.append(WordOutput(value: spellWord, state: .spell))
                    // Skip to end of spell tag
                    if let spellTagEnd = suggestion[spellEnd...].firstIndex(of: ">") {
                        currentIndex = suggestion.index(after: spellTagEnd)
                    } else {
                        currentIndex = spellEnd
                    }
                } else {
                    currentIndex = spellStart
                }
            } else {
                // Handle normal word (no tags)
                let nextWrongTag = suggestion[currentIndex...].firstIndex(of: "<")
                let nextCorrectTag = suggestion[currentIndex...].firstIndex(of: "<")
                
                let nextTag: String.Index?
                if let wrongTag = nextWrongTag, let correctTag = nextCorrectTag {
                    nextTag = min(wrongTag, correctTag)
                } else {
                    nextTag = nextWrongTag ?? nextCorrectTag
                }
                
                let wordEnd = nextTag ?? suggestion.endIndex
                let word = String(suggestion[currentIndex..<wordEnd]).trimmingCharacters(in: .whitespaces)
                
                if !word.isEmpty {
                    wordOutputs.append(WordOutput(value: word, state: .normal))
                }
                
                currentIndex = wordEnd
            }
        }
        
        return wordOutputs
    }
}

// MARK: - Request/Response Models
struct GrammarRequest: Codable {
    let content: String
}

struct GrammarAPIResponse: Codable {
    let status: String
    let task: String
    let queryId: String
    let corrections: [GrammarCorrection]
    
    enum CodingKeys: String, CodingKey {
        case status
        case task
        case queryId = "query_id"
        case corrections
    }
}

struct GrammarCorrection: Codable {
    let original: String
    let suggestion: String
    let explanation: String
    let changed: Bool
    let correctionId: String?
    
    enum CodingKeys: String, CodingKey {
        case original
        case suggestion
        case explanation
        case changed
        case correctionId = "correction_id"
    }
}



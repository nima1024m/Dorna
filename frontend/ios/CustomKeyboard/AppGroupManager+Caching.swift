//
//  AppGroupManager+Caching.swift
//  CustomKeyboard
//
//  Created by consolidation on 1/30/25.
//

import Foundation
import CryptoKit

// MARK: - AppGroupManager Caching Extension
extension AppGroupManager {
    
    // MARK: - Caching Support (App Group)

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Grammar cache entry
    struct GrammarCacheEntry: Codable {
        let contentHash: String
        let timestamp: Double
        let response: GrammarAPIResponse
    }

    // Tone cache entry
    struct ToneCacheEntry: Codable {
        let contentHash: String
        let targetTone: String
        let timestamp: Double
        let response: ToneAPIResponse
    }

    // Translation cache entry
    struct TranslationCacheEntry: Codable {
        let contentHash: String
        let targetLanguage: String
        let timestamp: Double
        let response: TranslationAPIResponse
    }

    private func grammarCacheKey(for content: String) -> String {
        return "grammarCache_" + sha256(content)
    }

    private func toneCacheKey(for content: String, targetTone: String) -> String {
        return "toneCache_" + sha256(content + "|" + targetTone.lowercased())
    }

    private func translationCacheKey(for content: String, targetLanguage: String) -> String {
        return "translationCache_" + sha256(content + "|" + targetLanguage.lowercased())
    }

    func saveGrammarCache(for content: String, response: GrammarAPIResponse, timestamp: Double = Date().timeIntervalSince1970) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return }
        let entry = GrammarCacheEntry(contentHash: sha256(content), timestamp: timestamp, response: response)
        if let data = try? JSONEncoder().encode(entry) {
            sharedDefaults.set(data, forKey: grammarCacheKey(for: content))
            sharedDefaults.synchronize()
        }
    }

    func loadGrammarCache(for content: String) -> GrammarCacheEntry? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return nil }
        guard let data = sharedDefaults.data(forKey: grammarCacheKey(for: content)) else { return nil }
        return try? JSONDecoder().decode(GrammarCacheEntry.self, from: data)
    }

    func saveToneCache(for content: String, targetTone: String, response: ToneAPIResponse, timestamp: Double = Date().timeIntervalSince1970) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return }
        let entry = ToneCacheEntry(contentHash: sha256(content), targetTone: targetTone.lowercased(), timestamp: timestamp, response: response)
        if let data = try? JSONEncoder().encode(entry) {
            sharedDefaults.set(data, forKey: toneCacheKey(for: content, targetTone: targetTone))
            sharedDefaults.synchronize()
        }
    }

    func loadToneCache(for content: String, targetTone: String) -> ToneCacheEntry? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return nil }
        guard let data = sharedDefaults.data(forKey: toneCacheKey(for: content, targetTone: targetTone)) else { return nil }
        return try? JSONDecoder().decode(ToneCacheEntry.self, from: data)
    }

    func saveTranslationCache(for cacheKey: String, response: TranslationAPIResponse, timestamp: Double = Date().timeIntervalSince1970) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return }
        let entry = TranslationCacheEntry(contentHash: sha256(cacheKey), targetLanguage: cacheKey.components(separatedBy: "_").last ?? "", timestamp: timestamp, response: response)
        if let data = try? JSONEncoder().encode(entry) {
            sharedDefaults.set(data, forKey: "translationCache_" + cacheKey)
            sharedDefaults.synchronize()
        }
    }

    func loadTranslationCache(for cacheKey: String) -> TranslationCacheEntry? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return nil }
        guard let data = sharedDefaults.data(forKey: "translationCache_" + cacheKey) else { return nil }
        return try? JSONDecoder().decode(TranslationCacheEntry.self, from: data)
    }

    // MARK: - Last Applied Tracking

    struct LastAppliedGrammarEntry: Codable {
        let text: String
        let timestamp: Double
    }

    struct LastAppliedToneEntry: Codable {
        let text: String
        let timestamp: Double
        let toneType: String?
    }

    private var lastAppliedGrammarKey: String { "lastAppliedGrammarText" }
    private var lastAppliedToneKey: String { "lastAppliedToneText" }

    func saveLastAppliedGrammar(text: String, timestamp: Double = Date().timeIntervalSince1970) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return }
        let entry = LastAppliedGrammarEntry(text: text, timestamp: timestamp)
        if let data = try? JSONEncoder().encode(entry) {
            sharedDefaults.set(data, forKey: lastAppliedGrammarKey)
            sharedDefaults.synchronize()
        }
    }

    func loadLastAppliedGrammar() -> LastAppliedGrammarEntry? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return nil }
        guard let data = sharedDefaults.data(forKey: lastAppliedGrammarKey) else { return nil }
        return try? JSONDecoder().decode(LastAppliedGrammarEntry.self, from: data)
    }

    func saveLastAppliedTone(text: String, toneType: String? = nil, timestamp: Double = Date().timeIntervalSince1970) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return }
        let entry = LastAppliedToneEntry(text: text, timestamp: timestamp, toneType: toneType)
        if let data = try? JSONEncoder().encode(entry) {
            sharedDefaults.set(data, forKey: lastAppliedToneKey)
            sharedDefaults.synchronize()
        }
    }

    func loadLastAppliedTone() -> LastAppliedToneEntry? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") else { return nil }
        guard let data = sharedDefaults.data(forKey: lastAppliedToneKey) else { return nil }
        return try? JSONDecoder().decode(LastAppliedToneEntry.self, from: data)
    }
    
    func isUserLoggedIn() -> Bool {
        if let accessToken = getAccessToken(), !accessToken.isEmpty {
            return true
        }
        return false
    }
}
//
//  AppGroupManager.swift
//  Shared between Runner and CustomKeyboard
//
//  Created by consolidation on 1/30/25.
//

import Foundation
import os

// MARK: - App Group Manager
class AppGroupManager {
    static let shared = AppGroupManager()
    private let appGroupID = "group.com.dorna.app"
    private var collectDataKey: String { "collectDataConsent" }
    
    private init() {}
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Keyboard Status Management
    
    func writeFullAccessStatus(_ hasFullAccess: Bool) {
        let timestamp = Date().timeIntervalSince1970
        sharedDefaults?.set(hasFullAccess, forKey: "keyboardFullAccessStatus")
        sharedDefaults?.set(timestamp, forKey: "keyboardFullAccessTimestamp")
        sharedDefaults?.synchronize()
        #if DEBUG
        NSLog("Debug - Keyboard extension: Full access status written to shared UserDefaults: \(hasFullAccess) at timestamp: \(timestamp)")
        #endif
    }
    
    func writeKeyboardActiveStatus(_ isActive: Bool) {
        sharedDefaults?.set(isActive, forKey: "keyboardIsActive")
        sharedDefaults?.synchronize()
        #if DEBUG
        NSLog("Debug - Keyboard extension: Active status written to shared UserDefaults: \(isActive)")
        #endif
    }
    
    func getFullAccessStatus() -> Bool? {
        return sharedDefaults?.object(forKey: "keyboardFullAccessStatus") as? Bool
    }
    
    func getFullAccessTimestamp() -> Double? {
        return sharedDefaults?.object(forKey: "keyboardFullAccessTimestamp") as? Double
    }
    
    func getKeyboardActiveStatus() -> Bool? {
        return sharedDefaults?.object(forKey: "keyboardIsActive") as? Bool
    }
    
    func getLastTimestamp() -> Double? {
        return sharedDefaults?.object(forKey: "keyboardLastTimestamp") as? Double
    }
    
    func clearFullAccessStatus() {
        // Commented out to preserve cached values
        // sharedDefaults?.removeObject(forKey: "keyboardFullAccessStatus")
        // sharedDefaults?.synchronize()
        // print("Debug - Cleared cached full access status")
    }
    
    func clearKeyboardActiveStatus() {
        // Commented out to preserve cached values
        // sharedDefaults?.removeObject(forKey: "keyboardIsActive")
        // sharedDefaults?.synchronize()
        // print("Debug - Cleared cached keyboard selection status")
    }
    
    func setForceRecheckFullAccess() {
        sharedDefaults?.set(true, forKey: "forceRecheckFullAccess")
        sharedDefaults?.synchronize()
    }
    
    func setForceRecheckKeyboardSelection() {
        sharedDefaults?.set(true, forKey: "forceRecheckKeyboardSelection")
        sharedDefaults?.synchronize()
    }
    
    func setLastRecheckRequest() {
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "lastRecheckRequest")
        sharedDefaults?.synchronize()
    }
    
    // Sets the full access status in app group
    func setFullAccessStatus(_ hasFullAccess: Bool) {
        sharedDefaults?.set(hasFullAccess, forKey: "keyboardFullAccessStatus")
        sharedDefaults?.synchronize()
        print("Debug - Main app: Set full access status to: \(hasFullAccess)")
    }
    
    func checkForForceRecheck() -> Bool {
        guard let sharedDefaults = sharedDefaults else { return false }
        
        var shouldRecheck = false
        
        if sharedDefaults.bool(forKey: "forceRecheckFullAccess") {
            NSLog("Debug - Force recheck flag detected, re-checking full access")
            shouldRecheck = true
            
            // Clear the flag
            sharedDefaults.removeObject(forKey: "forceRecheckFullAccess")
            sharedDefaults.synchronize()
        }
        
        if sharedDefaults.bool(forKey: "forceRecheckKeyboardSelection") {
            NSLog("Debug - Force keyboard selection recheck flag detected")
            shouldRecheck = true
            
            // Clear the flag
            sharedDefaults.removeObject(forKey: "forceRecheckKeyboardSelection")
            sharedDefaults.synchronize()
        }
        
        // Check for timestamp-based recheck requests
        if let lastRequest = sharedDefaults.object(forKey: "lastRecheckRequest") as? Double {
            let currentTime = Date().timeIntervalSince1970
            if currentTime - lastRequest < 10.0 { // Within 10 seconds
                NSLog("Debug - Recent recheck request detected, re-checking full access")
                shouldRecheck = true
                
                // Clear the timestamp
                sharedDefaults.removeObject(forKey: "lastRecheckRequest")
                sharedDefaults.synchronize()
            }
        }
        
        return shouldRecheck
    }
    
    // MARK: - Utility Functions
    
    // Test function to check if we can read/write to shared UserDefaults
    func canWriteToSharedDefaults() -> Bool {
        print("Debug - Testing UserDefaults access for app group: \(appGroupID)")
        
        guard let sharedDefaults = sharedDefaults else {
            print("Debug - Could not create UserDefaults with suite name: \(appGroupID)")
            return false
        }
        
        print("Debug - Successfully created UserDefaults with suite name: \(appGroupID)")
        
        // Test write
        let testKey = "test_write_\(Date().timeIntervalSince1970)"
        let testValue = "test_value_\(Date().timeIntervalSince1970)"
        sharedDefaults.set(testValue, forKey: testKey)

        // Test read
        let readValue = sharedDefaults.string(forKey: testKey)
        let readSuccess = readValue == testValue
        print("Debug - Read \(testValue): \(readSuccess), read value: \(readValue ?? "nil")")
        
        // Clean up
        sharedDefaults.removeObject(forKey: testKey)
        sharedDefaults.synchronize()
        
        let finalResult = readSuccess
        print("Debug - Can write to shared UserDefaults: \(finalResult)")
        
        return finalResult
    }
    
    // Clears all app group data
    func clearAllAppGroupData() {
        guard let sharedDefaults = sharedDefaults else {
            print("Debug - Could not access shared UserDefaults")
            return
        }
        
        // Get all keys from shared UserDefaults
        let allKeys = sharedDefaults.dictionaryRepresentation().keys
        
        // Remove all keys
        for key in allKeys {
            sharedDefaults.removeObject(forKey: key)
            print("Debug - Removed key: \(key)")
        }
        
        // Synchronize changes
        sharedDefaults.synchronize()
        print("Debug - Cleared all app group data")
    }

    // MARK: - Collect Data Consent

    func setCollectDataConsent(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: collectDataKey)
        sharedDefaults?.synchronize()
        print("Debug - collectDataConsent set to: \(enabled)")
    }

    func getCollectDataConsent() -> Bool {
        // Default to true if not set, to mirror current Flutter default
        return sharedDefaults?.object(forKey: collectDataKey) as? Bool ?? true
    }
    
    // MARK: - Auto Correction Consent
    
    private var autoCorrectionKey: String { "autoCorrectionEnabled" }
    
    func setAutoCorrectionEnabled(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: autoCorrectionKey)
        sharedDefaults?.synchronize()
        print("Debug - autoCorrectionEnabled set to: \(enabled)")
    }
    
    func getAutoCorrectionEnabled() -> Bool {
        // Default to false
        return sharedDefaults?.object(forKey: autoCorrectionKey) as? Bool ?? false
    }

    // MARK: - Token Management

    private var accessTokenKey: String { "access_token" }
    private var refreshTokenKey: String { "refresh_token" }
    private var tokenTimestampKey: String { "token_timestamp" }

    func getAccessToken() -> String? {
        return sharedDefaults?.string(forKey: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        return sharedDefaults?.string(forKey: refreshTokenKey)
    }

    func getTokenTimestamp() -> Double? {
        return sharedDefaults?.object(forKey: tokenTimestampKey) as? Double
    }

    func saveTokens(accessToken: String, refreshToken: String, timestamp: Double? = nil) {
        let tokenTimestamp = timestamp ?? Date().timeIntervalSince1970
        sharedDefaults?.set(accessToken, forKey: accessTokenKey)
        sharedDefaults?.set(refreshToken, forKey: refreshTokenKey)
        sharedDefaults?.set(tokenTimestamp, forKey: tokenTimestampKey)
        sharedDefaults?.synchronize()
        print("Debug - Both tokens saved to app group with timestamp: \(tokenTimestamp)")
    }

    func clearTokens() {
        sharedDefaults?.removeObject(forKey: accessTokenKey)
        sharedDefaults?.removeObject(forKey: refreshTokenKey)
        sharedDefaults?.removeObject(forKey: tokenTimestampKey)
        sharedDefaults?.synchronize()
        print("Debug - Tokens cleared from app group")
    }

    // MARK: - Favorite Tones Management

    private var favoriteTonesKey: String { "favoriteTones" }

    func getFavoriteTones() -> [String] {
        guard let sharedDefaults = sharedDefaults else { return [] }
        return sharedDefaults.stringArray(forKey: favoriteTonesKey) ?? []
    }

    func addFavoriteTone(_ toneName: String) {
        guard let sharedDefaults = sharedDefaults else { return }
        
        var favorites = getFavoriteTones()
        
        // Check if already exists
        if favorites.contains(toneName) {
            return
        }
        
        // If we already have 2 favorites, remove the first one
        if favorites.count >= 2 {
            favorites.removeFirst()
        }
        
        // Add the new favorite
        favorites.append(toneName)
        
        sharedDefaults.set(favorites, forKey: favoriteTonesKey)
        sharedDefaults.synchronize()
    }

    func removeFavoriteTone(_ toneName: String) {
        guard let sharedDefaults = sharedDefaults else { return }
        
        var favorites = getFavoriteTones()
        favorites.removeAll { $0 == toneName }
        
        sharedDefaults.set(favorites, forKey: favoriteTonesKey)
        sharedDefaults.synchronize()
    }

}
//
//  AutoCorrectionEngine.swift
//  CustomKeyboard
//
//  Created by Royal Macbook on 12/3/25.
//

import UIKit

class AutoCorrectionEngine {
    static let shared = AutoCorrectionEngine()
    private let checker = UITextChecker()
    
    // State
    private var lastAutoCorrection: (original: String, corrected: String)? = nil
    private var ignoredCorrection: String? = nil
    
    // Validates if a word is misspelled and provides a correction if available, considering context
    func getCorrection(text: String, range: NSRange, language: String) -> String? {
        if text.isEmpty { return nil }
        
        // Check if the word is misspelled within the provided text context
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: text,
            range: range,
            startingAt: range.location,
            wrap: false,
            language: language
        )
        
        // Ensure we found a misspelling that overlaps with our target range
        if misspelledRange.location != NSNotFound &&
           misspelledRange.location >= range.location &&
           misspelledRange.location < range.location + range.length {
            
            // Get guesses for the misspelled word using the full text as context
            if let guesses = checker.guesses(forWordRange: misspelledRange, in: text, language: language),
               let bestGuess = guesses.first {
                return bestGuess
            }
        }
        
        return nil
    }
    
    // Helper to check if a language is supported by UITextChecker
    func isLanguageSupported(_ language: String) -> Bool {
        return UITextChecker.availableLanguages.contains(language)
    }
    
    // MARK: - Auto Correction Logic
    
    func clearAutoCorrectionState() {
        lastAutoCorrection = nil
        ignoredCorrection = nil
    }
    
    func attemptAutoCorrect(proxy: UITextDocumentProxy, localeIdentifier: String, onDidCorrect: @escaping () -> Void) -> Bool {
        // Check if autocorrection is enabled
        if !AppGroupManager.shared.getAutoCorrectionEnabled() {
            return false
        }
        
        guard let before = proxy.documentContextBeforeInput else { return false }
        
        let languageCode = Locale(identifier: localeIdentifier).languageCode ?? localeIdentifier
        
        // Only apply to English for now, or verify support
        let isEnglish = languageCode.hasPrefix("en")
        if !isEnglish { return false }
        
        // Regex to find last word
        let pattern = "[A-Za-z']+$"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.matches(in: before, range: NSRange(location: 0, length: before.utf16.count)).last else {
            return false
        }
        
        let nsBefore = before as NSString
        let word = nsBefore.substring(with: match.range)
        
        if word == ignoredCorrection {
            return false
        }
        
        // Pass full context (before) and the range of the word to correct
        guard let correction = getCorrection(text: before, range: match.range, language: languageCode),
              correction != word else {
            return false
        }
        
        // Delete original
        for _ in 0..<word.count {
            proxy.deleteBackward()
        }
        
        // Insert correction
        proxy.insertText(correction)
        
        // Store state
        lastAutoCorrection = (original: word, corrected: correction)
        
        // Callback for UI/Mirror updates
        onDidCorrect()
        
        return true
    }
    
    func handleAutoCorrectRevert(proxy: UITextDocumentProxy, onDidRevert: @escaping (_ original: String, _ corrected: String) -> Void) -> Bool {
        guard let last = lastAutoCorrection else { return false }
        guard let before = proxy.documentContextBeforeInput else { return false }
        
        // Expect "Corrected "
        let expected = last.corrected + " "
        if before.hasSuffix(expected) {
            // Remove "Corrected "
            for _ in 0..<expected.count {
                proxy.deleteBackward()
            }
            // Insert "Original"
            proxy.insertText(last.original)
            
            ignoredCorrection = last.original
            lastAutoCorrection = nil
            
            // Callback for UI/Mirror updates with the words for precise mirror update
            onDidRevert(last.original, last.corrected)
            
            return true
        }
        
        return false
    }
}

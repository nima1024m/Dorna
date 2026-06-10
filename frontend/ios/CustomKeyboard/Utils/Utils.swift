//
//  Utils.swift
//  CustomKeyboard
//
//

import UIKit
import Foundation

class Utils {
    
    // Detect if a character is a Persian letter (Farsi alphabet only; excludes digits/punctuation)
    static func isPersianCharacter(_ character: Character) -> Bool {
        // Canonical Persian letters used in Farsi
        // Note: Includes Persian-specific letters and common alef/hamza forms used in Farsi
        let persianLetters = "ءاآأإبپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی"
        let allowedScalars = Set(persianLetters.unicodeScalars)
        // All scalars of the character must be in allowed set
        return character.unicodeScalars.allSatisfy { allowedScalars.contains($0) }
    }
    
    // Clean translated text by removing [] chars for wrong tags but keeping the word content
    static func cleanTranslatedText(_ text: String) -> String {
        // Remove [] brackets but keep the content inside
        let pattern = "\\[([^\\]]*)\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: text.count)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
        }
        return text
    }
    
    // Open the main app from keyboard extension
    static func openMainAppForSignIn(from responder: UIResponder) {
        Logger.debug("openMainAppForSignIn")
        // Try to open the main app using URL scheme
        if let url = URL(string: "dorna://openapp/?isForSignIn=true") {
            // Use the responder chain to open URL from keyboard extension
            if #available(iOS 18.0, *) {
                let selector = sel_registerName("openURL:options:completionHandler:")
                if let target = findResponder(from: responder, for: selector) as? UIApplication {
                    target.open(url, options: .init(), completionHandler: nil)
                } else if let scene = findResponder(from: responder, for: selector) as? UIScene {
                    scene.open(url, options: .init(), completionHandler: nil)
                }
            } else {
                let selector = sel_registerName("openURL:")
                if let target = findResponder(from: responder, for: selector) {
                    _ = target.perform(selector, with: url)
                }
            }
        }
    }
    
    // Helper to find responder in the responder chain
    static func findResponder(from startResponder: UIResponder, for selector: Selector) -> UIResponder? {
        var responder: UIResponder? = startResponder
        while let r = responder {
            if r.responds(to: selector) {
                return r
            }
            responder = r.next
        }
        return nil
    }
}


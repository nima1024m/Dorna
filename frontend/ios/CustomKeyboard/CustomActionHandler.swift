//
//  CustomActionHandler.swift
//  Runner
//
//  Created by Royal Macbook  on 11/5/25.
//
import KeyboardKit
import SwiftUI

// Custom action handler to handle language switch button press
class CustomActionHandler: KeyboardAction.StandardActionHandler {
    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction) {
        // Handle all gesture types, not just .release

        // Handle language switch
        if case .custom(let title) = action, title == "languageSwitch" {
            if gesture == .release {
                let currentLocales = keyboardController?.state.keyboardContext.locales ?? []
                let currentLocale = keyboardController?.state.keyboardContext.locale

                if let currentLocale = currentLocale,
                   let index = currentLocales.firstIndex(of: currentLocale),
                   index + 1 < currentLocales.count {
                    keyboardController?.state.keyboardContext.locale = currentLocales[index + 1]
                } else if let firstLocale = currentLocales.first {
                    keyboardController?.state.keyboardContext.locale = firstLocale
                }
                
                // Update callout service for the new locale
                if let kvc = keyboardController as? KeyboardViewController {
                    kvc.updateCalloutServiceForCurrentLocale()
                }
                
                if let kvc = keyboardController as? KeyboardViewController {

                if(kvc.selectedToolbarItem == .translate){

                 if kvc.state.keyboardContext.locale.identifier == Locale.persian.identifier {
                     kvc.selectedTranslation = TranslationType.persian.rawValue
                 } else {
                     kvc.selectedTranslation = TranslationType.english.rawValue
                 }
                 kvc.onClearTranslationTap()
                }
            }
            }
            return
        }
        

        // If the primary/return key is shown with a custom applyTranslation override, trigger apply
        if case .primary = action {
            if gesture == .release {
                if let kvc = keyboardController as? KeyboardViewController {
                    let override = kvc.state.keyboardContext.returnKeyTypeOverride
                    if case .custom(let title) = override, title == "applyTranslation" {
                        kvc.applyTemporaryTranslation()
                        // Track the translation approval before applying
                        if let translateId = kvc.currentTranslationQueryId {
                            kvc.trackerAPIService.trackTranslationAction(translateId: translateId, action: .approved)
                            }

                        return
                    }
                    
                    // Handle normal return key press in translate mode
                    if kvc.selectedToolbarItem == .translate {
                        return
                    }
                }
            }
        }
        if gesture == .release {

            if let keyboardViewController = keyboardController as? KeyboardViewController {
                if keyboardViewController.selectedToolbarItem == .translate {
                    keyboardViewController.state.keyboardContext.returnKeyTypeOverride = .return
                }
            }


        // Handle character actions
        if case .character = action {

            if let keyboardViewController = keyboardController as? KeyboardViewController {
                keyboardViewController.clearAutoCorrectionState()
                
                if keyboardViewController.grammarNoSuggestion == true {
                   keyboardViewController.grammarNoSuggestion = false
                   }
                if keyboardViewController.selectedToolbarItem == .translate {
                    // Route to internal translation input instead of host app
                    if case .character(let char) = action {
                        // Special handling for zero-width space callout selections - remove dotted circle
                        let cleanedChar = char.replacingOccurrences(of: "◌", with: "")
                        keyboardViewController.insertTextAtCursor(cleanedChar)
                        // Don't refresh the entire view - just update the binding
                        return
                    }
                }
                keyboardViewController.updateDocumentTextFromKeystroke()
            }
        }

        // Handle space key for translation input
        if case .space = action {
            if let keyboardViewController = keyboardController as? KeyboardViewController {
                // Attempt auto-correction before inserting space (except in translate mode)
                if keyboardViewController.selectedToolbarItem != .translate {
                    _ = keyboardViewController.attemptAutoCorrect()
                }
                
                if keyboardViewController.grammarNoSuggestion == true {
                   keyboardViewController.grammarNoSuggestion = false
                   }

                if keyboardViewController.selectedToolbarItem == .translate {
                    keyboardViewController.insertTextAtCursor(" ")
                    // Don't refresh the entire view - just update the binding
                    return
                }
                keyboardViewController.updateDocumentTextFromKeystroke()
            }
        }
        }
        // Handle backspace (delete) actions
        if case .backspace = action {

            if let keyboardViewController = keyboardController as? KeyboardViewController {
                // Check if we should revert an auto-correction
                if keyboardViewController.handleAutoCorrectRevert() {
                    return
                }
                
                if keyboardViewController.grammarNoSuggestion == true {
                   keyboardViewController.grammarNoSuggestion = false
                   }

                if keyboardViewController.selectedToolbarItem == .translate {
                    if gesture == .press || gesture == .repeatPress{
                        keyboardViewController.deleteTextAtCursor()
                        keyboardViewController.state.keyboardContext.returnKeyTypeOverride = .return
                    }
                    return
                }
                keyboardViewController.updateDocumentTextFromKeystroke()
            }
        }

        // Handle special callout character selections for normal keyboard input
        if case .character(let char) = action, gesture == .release {
            // Special handling for zero-width space callout selections - remove dotted circle
            if char.contains("◌") {
                let cleanedChar = char.replacingOccurrences(of: "◌", with: "")
                if let keyboardViewController = keyboardController as? KeyboardViewController {
                keyboardViewController.textDocumentProxy.insertText(cleanedChar)
                return
                }
            }
        }
        
        // Call super for any unhandled cases
        super.handle(gesture, on: action)
    }
}

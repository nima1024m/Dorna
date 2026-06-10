//
//  CalloutService.swift
//  Runner
//
//  Created by Royal Macbook  on 11/5/25.
//
import KeyboardKit
import SwiftUI

// Custom style service to set callout font weight to bold
class CalloutStyleService: KeyboardStyle.StandardStyleService {
    override var calloutStyle: KeyboardCallout.CalloutStyle? {
        var style = KeyboardCallout.CalloutStyle.standard
        style.actionItemFont = .title2(weight: .light)
        style.inputItemFont = .init(.largeTitle, .light)

        if UIAccessibility.isBoldTextEnabled{
            style.actionItemFont = .title2(weight: .medium)
            style.inputItemFont = .init(.largeTitle, .medium)
        }

        return style
    }
}

// Custom callout service for Persian keyboard with Arabic character mappings
class PersianCalloutService: KeyboardCallout.BaseCalloutService {
    
    override func calloutActions(for action: KeyboardAction) -> [KeyboardAction] {
        // Handle character actions for Persian/Arabic character mappings
        if case .character(let char) = action {
            return getPersianCalloutActions(for: char)
        }
        
        // Fall back to parent implementation for other actions
        return super.calloutActions(for: action)
    }
    
    private func getPersianCalloutActions(for char: String) -> [KeyboardAction] {
        // Persian/Arabic character mappings for long-press
        let characterMappings: [String: [String]] = [
            "ا": ["ا", "آ", "ء", "أ", "إ"],
            "ب": ["ب"],
            "ت": ["ت", "ة"],
            "ث": ["ث"],
            "ج": ["ج"],
            "ح": ["ح"],
            "خ": ["خ"],
            "د": ["د"],
            "ذ": ["ذ"],
            "ر": ["ر"],
            "ز": ["ز"],
            "س": ["س"],
            "ش": ["ش"],
            "ص": ["ص"],
            "ض": ["ض"],
            "ط": ["ط"],
            "ظ": ["ظ"],
            "ع": ["ع"],
            "غ": ["غ"],
            "ف": ["ف"],
            "ق": ["ق"],
            "ک": ["ک", "كْ"],
            "گ": ["گ"],
            "ل": ["ل"],
            "م": ["م"],
            "ن": ["ن"],
            "و": ["و","ؤْ"],
            "ه": ["ه", "هٔ", "ةْ"],
            "ی": ["ی", "ئ", "ي"],
            "پ": ["پ", "پّ", "پَ", "پُ", "پِ", "پْ"],
            "چ": ["چ"],
            "ژ": ["ژ"],
            "۰": ["۰", "0"],
            "۱": ["۱", "1"],
            "۲": ["۲", "2"],
            "۳": ["۳", "3"],
            "۴": ["۴", "4"],
            "۵": ["۵", "5"],
            "۶": ["۶", "6"],
            "۷": ["۷", "7"],
            "۸": ["۸", "8"],
            "۹": ["۹", "9"],
            "؟": ["؟"],
            "،": ["،", ","],
            "؛": ["؛"],
            "!": ["!", "¡"],
            ".": [".", "…"],
            "-": ["-", "–", "—", "•"],
            "(": ["﴿"],
            ")": ["﴾"],
            "[": ["["],
            "]": ["]"],
            "{": ["{"],
            "}": ["}"],
            "<": ["<"],
            ">": [">"],
            "=": ["=", "≠", "≈"],
            "+": ["+"],
            "*": ["*"],
            "/": ["/", "\\"],
            "\\": ["\\"],
            "|": ["|"],
            "~": ["~"],
            "^": ["^"],
            "%": ["%", "‰"],
            "$": ["$", "﷼", "¢", "£", "₩", "₽", "€", "¥"],
            "@": ["@"],
            "#": ["#"],
            "&": ["&", "§"],
            "\"": ["\""],
            "'": ["'", ""],
            "`": ["`", ""],
            "٪": ["٪", "%"],
            "“": ["“", "”", "“", "„", "«", "»"],
            "‘": ["“", "'", "‘", "`"],
           "»" : ["“", "\"", "„", "'"],
           "«": ["\"", "”", "'"],
//            String.zeroWidthSpace: ["ـ","ُ◌","ِ◌","َ◌","ّ◌","ٌ◌","ً◌","ٍ◌","ْ◌","ٓ◌","ٰ◌","ٖ◌"],
            String.zeroWidthSpace: ["ـ","ُ◌","ِ◌","َ◌","ّ◌","ً◌","ٍ◌","ٓ◌"],
        ]
        
        // Return character actions for the mapped characters
        if let mappings = characterMappings[char] {
            return mappings.map { .character($0) }
        }
        
        // Return empty array for characters without mappings
        return []
    }
    
    override func triggerFeedbackForSelectionChange() {
        // Provide haptic feedback when user selects different characters
        // This will be handled by the standard feedback service
        super.triggerFeedbackForSelectionChange()
    }
}



//
//  ColorScheme.swift
//  CustomKeyboard
//
//  Created by Royal Macbook  on 5/1/25.
//

import SwiftUI
import UIKit

// MARK: - Color Scheme Manager
class ColorSchemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    
    static let shared = ColorSchemeManager()
    
    private init() {}
    
    func updateDarkMode(_ isDark: Bool) {
        isDarkMode = isDark
    }
}

// MARK: - Color Definitions
struct AppColors {
    
    // MARK: - Primary Colors
    struct Primary {
        static func blue(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.11, green: 0.46, blue: 0.74) : Color(red: 0.11, green: 0.46, blue: 0.74)
        }
        static func blueDark(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.09, green: 0.38, blue: 0.62) : Color(red: 0.09, green: 0.38, blue: 0.62)
        }
        static func blueLight(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.15, green: 0.55, blue: 0.85) : Color(red: 0.15, green: 0.55, blue: 0.85)
        }
    }

    // MARK: - Overlay / Backdrop Colors
    struct Overlay {
        // Hex 232E36 with dynamic opacity
        static func sheetBackdrop(isDarkMode: Bool = false) -> Color {
            let base = Color(red: 0x23/255.0, green: 0x2E/255.0, blue: 0x36/255.0)
            return isDarkMode ? base.opacity(0.50) : base.opacity(0.20)
        }
    }

    // MARK: - Tone Colors
    struct Tone {
        static func formal(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.32, green: 0.48, blue: 0.91) : Color(red: 0.12, green: 0.23, blue: 0.54)
        }
        static func formalBackground(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.32, green: 0.47, blue: 0.91).opacity(0.12) : Color(red: 0.12, green: 0.23, blue: 0.54).opacity(0.12)
        }
        static func friendly(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 1, green: 0.47, blue: 0.09) : Color(red: 1, green: 0.47, blue: 0.09)
        }
        static func friendlyBackground(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 1, green: 0.47, blue: 0.09).opacity(0.12) : Color(red: 1, green: 0.47, blue: 0.09).opacity(0.12)
        }
        static func concise(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.94, green: 0.32, blue: 0.36) : Color(red: 0.94, green: 0.32, blue: 0.36)
        }
        static func conciseBackground(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.94, green: 0.32, blue: 0.36).opacity(0.12) : Color(red: 0.94, green: 0.32, blue: 0.36).opacity(0.12)
        }
    }
    
    // MARK: - Grammar Colors
    struct Grammar {
        static func wrong(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0xD8/255.0, green: 0x00/255.0, blue: 0x27/255.0) : Color(red: 0xD8/255.0, green: 0x00/255.0, blue: 0x27/255.0)
        }
        static func corrected(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0x17/255.0, green: 0xBD/255.0, blue: 0x62/255.0) : Color(red: 0x17/255.0, green: 0xBD/255.0, blue: 0x62/255.0)
        }
        static func spell(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 1, green: 0.67, blue: 0.20) : Color(red: 1, green: 0.67, blue: 0.20)
        }
        static func normal(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.white : Color.black
        }
        static func applyAll(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.09, green: 0.74, blue: 0.38) : Color(red: 0.09, green: 0.74, blue: 0.38)
        }
    }
    
    // MARK: - Translation Colors
    struct Translation {
        static func wrong(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0xD8/255.0, green: 0x00/255.0, blue: 0x27/255.0) : Color(red: 0xD8/255.0, green: 0x00/255.0, blue: 0x27/255.0)
        }
        static func spell(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 1, green: 0.67, blue: 0.20) : Color(red: 1, green: 0.67, blue: 0.20)
        }
    }
    
    // MARK: - Text Colors
    struct Text {
        static func primary(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.79, green: 0.83, blue: 0.86) : Color(red: 0.14, green: 0.18, blue: 0.21)
        }
        static func secondary(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.79, green: 0.83, blue: 0.86).opacity(0.50) : Color(red: 0.14, green: 0.18, blue: 0.21).opacity(0.50)
        }
        static func placeholder(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.28, green: 0.30, blue: 0.31) : Color(red: 0.28, green: 0.30, blue: 0.31)
        }
        static func placeholderLight(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.79, green: 0.83, blue: 0.86).opacity(0.50) : Color(red: 0.28, green: 0.30, blue: 0.31).opacity(0.5)
        }
        static func disabled(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.67, green: 0.73, blue: 0.78).opacity(0.40) : Color(red: 0.67, green: 0.73, blue: 0.78).opacity(0.40)
        }
    }
    
    // MARK: - Background Colors
    struct Background {
        static func keyboard(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color(red: 0.91, green: 0.92, blue: 0.93)
        }
        static func card(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.24, green: 0.24, blue: 0.24) : Color.white
        }
        static func cardSecondary(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.96, green: 0.96, blue: 0.96) : Color(red: 0.96, green: 0.96, blue: 0.96)
        }
        static func input(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 1, green: 1, blue: 1).opacity(0.15) : Color.white.opacity(0.5)
        }
        static func toneTabs(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.22) : Color(red: 0.96, green: 0.96, blue: 0.96)
        }
    }
    
    // MARK: - Border Colors
    struct Border {
        static func `default`(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.gray.opacity(0.4) : Color.gray.opacity(0.4)
        }
        static func primary(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.blue : Color.blue
        }
        static func error(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.red : Color.red
        }
        static func input(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.42, green: 0.42, blue: 0.42) : Color(red: 0.67, green: 0.73, blue: 0.78).opacity(0.40)
        }
        static func inputActive(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.79, green: 0.83, blue: 0.86).opacity(0.50) : Color(red: 0.14, green: 0.18, blue: 0.21).opacity(0.50)
        }
    }
    
    // MARK: - Loading Colors
    struct Loading {
        static func spinner(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.54, green: 0.54, blue: 0.55) : Color(red: 0.54, green: 0.54, blue: 0.55)
        }
        static func dots(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(red: 0.79, green: 0.83, blue: 0.86).opacity(0.50) : Color(red: 0.28, green: 0.30, blue: 0.31)
        }
    }
    
    // MARK: - Action Colors
    struct Action {
        static func success(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.green : Color.green
        }
        static func error(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.red : Color.red
        }
        static func warning(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.orange : Color.orange
        }
        static func info(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.blue : Color.blue
        }
    }
    
    // MARK: - System Colors
    struct System {
        static func primary(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.primary : Color.primary
        }
        static func secondary(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color.secondary : Color.secondary
        }
        static func background(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(.systemBackground) : Color(.systemBackground)
        }
        static func secondaryBackground(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(.secondarySystemBackground) : Color(.secondarySystemBackground)
        }
        static func groupedBackground(isDarkMode: Bool = false) -> Color {
            return isDarkMode ? Color(.systemGroupedBackground) : Color(.systemGroupedBackground)
        }
    }
}

// MARK: - Color Helper Extensions
extension Color {
    
    // Helper to get dynamic color based on dark mode
    func dynamic(isDarkMode: Bool, lightColor: Color, darkColor: Color) -> Color {
        return isDarkMode ? darkColor : lightColor
    }
    
    // Helper for opacity variations
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
}

// MARK: - UIKit Color Extensions
extension UIColor {
    
    // Convert SwiftUI Color to UIColor
    static func from(_ color: Color) -> UIColor {
        return UIColor(color)
    }
    
    // Dynamic color helpers for UIKit
    static func dynamicText(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? UIColor.white : UIColor(red: 0.14, green: 0.18, blue: 0.21, alpha: 1.0)
    }
    
    static func dynamicPlaceholder(isDarkMode: Bool) -> UIColor {
        return isDarkMode ? UIColor.white.withAlphaComponent(0.5) : UIColor(red: 0.28, green: 0.30, blue: 0.31, alpha: 0.5)
    }
}

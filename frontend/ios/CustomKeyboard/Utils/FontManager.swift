//
//  FontManager.swift
//  CustomKeyboard
//
//  Created by Royal Macbook on 5/1/25.
//

import Foundation
import UIKit
import SwiftUI
import CoreText
import os

class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    // SF Pro Display PostScript names (these are what UIFont/Font.custom expect)
    private let sfProDisplayBoldPS = "SFProDisplay-Bold"
    private let sfProDisplayMediumPS = "SFProDisplay-Medium"
    private let sfProDisplayRegularPS = "SFProDisplay-Regular"
    private let sfProDisplayLightPS = "SF-Pro-Display-Light"
    private let sfProDisplaySemiboldPS = "SFProDisplay-Semibold"

    // Optional file names if fonts are included as loose files in the bundle
    // Note: Files inside asset catalogs are not accessible via Bundle URLs.
    private let sfProDisplayBoldFile = "SFPRODISPLAYBOLD"
    private let sfProDisplayMediumFile = "SFPRODISPLAYMEDIUM"
    private let sfProDisplayRegularFile = "SFPRODISPLAYREGULAR"
    private let sfProDisplayLightFile = "SF-Pro-Display-Light"
    private let sfProDisplaySemiboldFile = "SF-Pro-Display-Semibold"

    // Check if fonts are loaded
    var areFontsLoaded: Bool {
        // Consider fonts loaded if UIFont can instantiate the postscript names
        let testSize: CGFloat = 12
        let available = [
            UIFont(name: sfProDisplayRegularPS, size: testSize),
            UIFont(name: sfProDisplayMediumPS, size: testSize),
            UIFont(name: sfProDisplayBoldPS, size: testSize),
            UIFont(name: sfProDisplayLightPS, size: testSize),
            UIFont(name: sfProDisplaySemiboldPS, size: testSize)
        ].allSatisfy { $0 != nil }
        return available
    }
    
    // Load fonts from bundle
    func loadFonts() {
        let bundle = Bundle(for: KeyboardViewController.self)
        
        // If already available via UIAppFonts, nothing to do.
        if areFontsLoaded { return }

        // Try to register from loose files, if present in bundle.
        let candidates: [(fileBase: String, ext: String)] = [
            (sfProDisplayBoldFile, "OTF"),
            (sfProDisplayMediumFile, "OTF"),
            (sfProDisplayRegularFile, "OTF"),
            (sfProDisplayLightFile, "OTF"),
            (sfProDisplaySemiboldFile, "OTF")
        ]

        // Common subdirectories to try – only works if fonts are copied as files.
        let subdirs: [String?] = [nil, "Fonts", "fonts"]

        for (fileBase, ext) in candidates {
            var found = false
            for sub in subdirs {
                let url = bundle.url(forResource: fileBase, withExtension: ext, subdirectory: sub)
                if let url = url {
                    loadFont(from: url)
                    found = true
                    break
                }
            }
            if !found {
                Logger.debug("FontManager: Font file not found in bundle for \(fileBase).\(ext). If the font is inside an asset catalog, it won't be accessible by URL. Make sure the OTF is added as a resource file to the CustomKeyboard target or rely on Info.plist UIAppFonts.")
            }
        }

        // If still not available, try to load from asset catalog (as data assets)
        if !areFontsLoaded {
            let assetCandidates = [sfProDisplayBoldFile, sfProDisplayMediumFile, sfProDisplayRegularFile, sfProDisplayLightFile, sfProDisplaySemiboldFile]
            for name in assetCandidates {
                if let dataAsset = NSDataAsset(name: name, bundle: bundle) {
                    loadFont(fromData: dataAsset.data)
                } else {
                    // Try case variants, since asset set names can differ in case
                    if let dataAsset = NSDataAsset(name: name.capitalized, bundle: bundle) {
                        loadFont(fromData: dataAsset.data)
                    } else if let dataAsset = NSDataAsset(name: name.lowercased(), bundle: bundle) {
                        loadFont(fromData: dataAsset.data)
                    }
                }
            }
        }
    }
    
    // Load individual font
    private func loadFont(from url: URL) {
        guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
            Logger.debug("FontManager: Could not create font data provider")
            return
        }
        
        guard let font = CGFont(fontDataProvider) else {
            Logger.debug("FontManager: Could not create font")
            return
        }
        
        // Avoid re-registering if a font with the same PostScript name is already available
        if let psName = font.postScriptName as String?, UIFont(name: psName, size: 12) != nil {
            Logger.debug("FontManager: Font already registered: \(psName). Skipping registration.")
            return
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            if let error = error?.takeRetainedValue() {
                Logger.debug("FontManager: Error registering font: \(error)")
            }
        } else {
            Logger.debug("FontManager: Successfully loaded font: \(url.lastPathComponent)")
        }
    }

    // Load and register font from raw data (e.g., asset catalog data asset)
    private func loadFont(fromData data: Data) {
        guard let provider = CGDataProvider(data: data as CFData) else {
            Logger.debug("FontManager: Could not create data provider from asset data")
            return
        }
        guard let cgFont = CGFont(provider) else {
            Logger.debug("FontManager: Could not create CGFont from asset data")
            return
        }
        // Avoid re-registering if a font with the same PostScript name is already available
        if let psName = cgFont.postScriptName as String?, UIFont(name: psName, size: 12) != nil {
            Logger.debug("FontManager: Font already registered from data: \(psName). Skipping registration.")
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            if let error = error?.takeRetainedValue() {
                Logger.debug("FontManager: Error registering data font: \(error)")
            }
        } else {
            if let name = cgFont.postScriptName as String? {
                Logger.debug("FontManager: Successfully registered font from data: \(name)")
            } else {
                Logger.debug("FontManager: Successfully registered font from data")
            }
        }
    }
    
    // Get UIFont with specified weight
    func sfProDisplay(size: CGFloat, weight: FontWeight = .regular) -> UIFont {
        let fontName: String
        
        switch weight {
        case .bold:
            fontName = sfProDisplayBoldPS
        case .medium:
            fontName = sfProDisplayMediumPS
        case .regular:
            fontName = sfProDisplayRegularPS
        case .light:
            fontName = sfProDisplayLightPS
        case .semibold:
            fontName = sfProDisplaySemiboldPS
        }
        
        if let font = UIFont(name: fontName, size: size) {
            return font
        } else {
            Logger.debug("FontManager: Font not found: \(fontName), falling back to system font")
            return UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
        }
    }
    
    // Font weight enum
    enum FontWeight {
        case regular
        case medium
        case bold
        case light
        case semibold

        var uiFontWeight: UIFont.Weight {
            switch self {
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .bold:
                return .bold
            case .light:
                return .light
            case .semibold:
                return .semibold
            }
        }

        var swiftUIFontWeight: Font.Weight {
            switch self {
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .bold:
                return .bold
            case .light:
                return .light
            case .semibold:
                return .semibold
            }
        }
    }

    /// Debug helper to Logger.debug available SF Pro Display fonts in the bundle
    func logAvailableFonts() {
        Logger.debug("FontManager: Installed font families:")
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family).sorted()
            if !names.isEmpty {
                Logger.debug("  \(family): \(names)")
            }
        }
        let test = areFontsLoaded ? "YES" : "NO"
        Logger.debug("FontManager: Are SF Pro Display fonts loaded? \(test)")
    }
    
    // MARK: - Device Detection
    
    /// Determines if the current device is a tablet (iPad)
    /// Returns true if the shortest side of the screen is 600 points or more
    static func isTablet() -> Bool {
        let screenBounds = UIScreen.main.bounds
        let shortestSide = min(screenBounds.width, screenBounds.height)
        return shortestSide >= 600
    }
}

// SwiftUI Font extension using FontManager
extension Font {
    static func sfProDisplay(size: CGFloat, weight: FontManager.FontWeight = .regular) -> Font {
        // Prefer PS names directly; if unavailable, fall back to system
        let ps: String
        switch weight {
        case .bold:
            ps = "SFProDisplay-Bold"
        case .medium:
            ps = "SFProDisplay-Medium"
        case .regular:
            ps = "SFProDisplay-Regular"
        case .light:
            ps = "SF-Pro-Display-Light"
        case .semibold:
            ps = "SFProDisplay-Semibold"
        }

        if UIFont(name: ps, size: size) != nil {
            return .custom(ps, size: size)
        } else {
            return .system(size: size, weight: weight.swiftUIFontWeight)
        }
    }
}

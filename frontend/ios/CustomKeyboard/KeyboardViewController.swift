//
//  KeyboardViewController.swift
//  CustomKeyboard
//
//  Created by Royal Macbook  on 5/1/25.
//

import UIKit
import KeyboardKit
import SwiftUI
import os


// Enum to track which toolbar item was tapped
enum ToolbarItem: String, CaseIterable {
    case translate = "translate"
    case grammar = "grammar"
    case tone = "tone"
}

// Enum to track which type of tone API call was made
enum ToneAPICallType {
    case normal
    case rephrase
}

// Enum to track background grammar check status
enum BackgroundGrammarState: Equatable {
    case idle           // Blue - not checked yet
    case checking       // Blue - currently checking
    case hasErrors(Int) // Red with counter - errors found
    case noErrors       // Green with tick - all good
}

class KeyboardViewController: KeyboardInputViewController, ObservableObject {
    @Published var selectedToolbarItem: ToolbarItem?
    @Published var documentText: String = ""
    @Published var isGrammarLoading: Bool = false
    @Published var isBackgroundGrammarLoading: Bool = false
    @Published var displayText: String = ""
    @Published var showGrammarSuggestion: Bool = false
    @Published var grammarWordOutputs: [WordOutput] = []
    @Published var grammarSuggestionsList: [[WordOutput]] = []
    @Published var isToneLoading: Bool = false
    @Published var toneAdjustedText: String = ""
    @Published var showToneSuggestion: Bool = false
    @Published var selectedTone: String = ToneType.formal.rawValue
    @Published var toneErrorMessage: String = ""
    @Published var toneNoSuggestion: Bool = false
    @Published var grammarErrorMessage: String = ""
    @Published var grammarNoSuggestion: Bool = false
    @Published var isTranslationLoading: Bool = false
    @Published var isGrammarApplyLoading: Bool = false
    @Published var isToneApplyLoading: Bool = false
    @Published var translatedText: String = ""
    @Published var showTranslationSuggestion: Bool = false
    @Published var selectedTranslation: String = TranslationType.english.rawValue
    @Published var translationErrorMessage: String = ""
    @Published var translationNoSuggestion: Bool = false
    @Published var translationInputText: String = ""
    @Published var translationCursorPosition: Int = 0
    @Published var translationResetToken: UUID = UUID()
    @Published var temporaryTranslatedText: String = "" // Temporary translation text
    @Published var previousTranslatedText: String = "" // Store previous translated text
    @Published var showTranslationApplyButton: Bool = false // Show apply button instead of done
    @Published var favoriteTones: [String] = [] // Stored favorite tones
    @Published var predictedWords: [String] = [] // Ranked predictions for current word
    @Published var showSignInTooltip: Bool = false // Show sign-in tooltip when user is not logged in
    @Published var backgroundGrammarState: BackgroundGrammarState = .idle // Background grammar check status
    private var isShowingNextWordSuggestions: Bool = false // Only true right after applyPrediction
    private var backgroundGrammarWorkItem: DispatchWorkItem?
    private var backgroundGrammarCorrections: [GrammarCorrection] = []
    private var updateDocumentTextWorkItem: DispatchWorkItem?
    private var toneAPIDebounceWorkItem: DispatchWorkItem?
    private var previousDocumentText: String = ""
    private let appGroupManager = AppGroupManager.shared
    private let grammarAPIService = GrammarAPIService.shared
    private let toneAPIService = ToneAPIService.shared
    private let translationAPIService = TranslationAPIService.shared
    let trackerAPIService = TrackerAPIService.shared
    private var timestampTimer: Timer?
    private var currentGrammarCorrections: [GrammarCorrection] = []
    private var currentToneQueryId: String? = nil
    var currentTranslationQueryId: String? = nil
    private var lastToneAPICallType: ToneAPICallType = .normal
    private var currentReturnKeyTypeOverride: Keyboard.ReturnKeyType? = nil
    private var isCapturingFullText: Bool = false
    private var isCapturedFullTextForGrammar: Bool = false
    private var hasGrammarSuggestionFromFullText: Bool = false
    private var typedCount: Int = 0
    private var currentToneOriginalText: String = ""
    
    // Task tracking for cancellation
    private var getFullTextTask: Task<String, Never>? = nil
    private var deleteFullTextTask: Task<Void, Never>? = nil
    private var replaceFullTextTask: Task<Void, Never>? = nil

    // Callout service management
    private let defaultCalloutService = KeyboardCallout.BaseCalloutService()
    private let persianCalloutService = PersianCalloutService()
    // AutoSuggestEngine for word predictions
    private var suggestEngine: AutoSuggestEngine? = nil
    private var currentSuggestLanguageKey: String? = nil
    private var getSuggestionsWorkItem: DispatchWorkItem?
    
    // AutoCorrectionEngine
    let autoCorrectionEngine = AutoCorrectionEngine.shared
    
    // MirrorTextEngine for tracking full text
    private var mirrorEngine: MirrorTextEngine?
    
    // Current full text property
    private(set) var currentFullText: String = "" {
        didSet {
            Logger.debugFullText("currentFullText updated: count=\(currentFullText.count), text=\(currentFullText)")
        }
    }
    private var currentFullSelectedText: String = ""

    // MARK: - Auto Correction
    
    func clearAutoCorrectionState() {
        autoCorrectionEngine.clearAutoCorrectionState()
    }
    
    func attemptAutoCorrect() -> Bool {
        let proxy = self.textDocumentProxy
        let localeId = self.state.keyboardContext.locale.identifier
        
        return autoCorrectionEngine.attemptAutoCorrect(proxy: proxy, localeIdentifier: localeId) { [weak self] in
            // Sync mirror engine
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self?.mirrorEngine?.performImmediateSync()
                self?.updateCurrentFullTextFromMirror()
            }
        }
    }
    
    func handleAutoCorrectRevert() -> Bool {
        let proxy = self.textDocumentProxy
        
        return autoCorrectionEngine.handleAutoCorrectRevert(proxy: proxy) { [weak self] original, corrected in
            guard let self = self, let mirror = self.mirrorEngine else { return }
            
            // Directly update mirror: replace "corrected " with "original"
            let expectedSuffix = corrected + " "
            let cursorPos = mirror.cursorPosition
            
            // The cursor should be right after where "corrected " was, but proxy operations already happened
            // After proxy deletes "corrected " and inserts "original", the actual text ends with "original"
            // We need to update mirror to match: remove "corrected " from before cursor and add "original"
            
            // Calculate where the corrected word started in mirror (before the revert)
            let correctedWordStart = cursorPos - expectedSuffix.count
            if correctedWordStart >= 0 && correctedWordStart + expectedSuffix.count <= mirror.mirrorText.count {
                let startIndex = mirror.mirrorText.index(mirror.mirrorText.startIndex, offsetBy: correctedWordStart)
                let endIndex = mirror.mirrorText.index(startIndex, offsetBy: expectedSuffix.count)
                
                // Verify the mirror has the corrected word + space at that position
                let segment = String(mirror.mirrorText[startIndex..<endIndex])
                if segment == expectedSuffix {
                    // Replace "corrected " with "original"
                    mirror.mirrorText.replaceSubrange(startIndex..<endIndex, with: original)
                    // Update cursor position: it should be after "original"
                    mirror.cursorPosition = correctedWordStart + original.count
                    self.updateCurrentFullTextFromMirror()
                    return
                }
            }
            
            // Fallback: if mirror state doesn't match expected, do a full sync
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.mirrorEngine?.performImmediateSync()
                self.updateCurrentFullTextFromMirror()
            }
        }
    }

    // MARK: - Callout Service Management
    
    func updateCalloutServiceForCurrentLocale() {
        let currentLocale = state.keyboardContext.locale
        
        if currentLocale.identifier == Locale.persian.identifier {
            // Use Persian callout service for Persian locale
            services.calloutService = persianCalloutService
            state.calloutContext.calloutService = persianCalloutService
        } else {
            // Use default callout service for all other locales (English, etc.)
            services.calloutService = defaultCalloutService
            state.calloutContext.calloutService = defaultCalloutService
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
                    // Load custom fonts
            FontManager.shared.loadFonts()

            let context = state.feedbackContext
            context.settings.isHapticFeedbackEnabled = false
            // Load favorite tones from app group
            loadFavoriteTones()

            // Create a Persian input set
            let persianAlphabetic = InputSet(rows: [
                .init(chars: ["ض","ص","ق","ف","غ","ع","ه","خ","ح","ج","چ"]),
                .init(chars: ["ش","س","ی","ب","ل","ا","ت","ن","م","ک","گ"]),
                .init(chars: ["ظ","ط","ژ","ز","ر","ذ","د","پ","و","ث"]),
            ])
            let persianNumeric = InputSet(
                rows: [
                    .init(chars: "۱۲۳۴۵۶۷۸۹۰"),
                    .init(
                        chars: "-/:؛()\("$")@«»",
                        deviceVariations: [.pad: "@#\("۰")&*()‘“"]
                    ),
                    .init(chars: ".،؟!٫", deviceVariations: [.pad: "%-+=/;:!?"])
                ]
            )
            let persianSymbolic = InputSet(
                rows: [
                    .init(chars: "[]{}#٪^*+=", deviceVariations: [.pad: "1234567890"]),
                    .init(
                        chars: "_\\|~<>&•‘“",
                        deviceVariations: [.pad: "_^[]{}"]
                    ),
                    .init(chars: ".،؟!٫", deviceVariations: [.pad: "§|~…\\<>!?"])
                    ]
            )

            // Create a custom layout service for Persian without a shift button
            let persianService = PersianLayoutService(
                alphabeticInputSet: persianAlphabetic,
                numericInputSet: persianNumeric,
                symbolicInputSet: persianSymbolic
            )
            // Register it for the Persian locale
            persianService.localeKey = Locale.persian.identifier

            // Insert the Persian service into the language switch layout service
            services.layoutService = LanguageSwitchLayoutService(
                baseService: services.layoutService,
                localizedServices: [persianService]
            )

            // Set callout service based on current locale
            updateCalloutServiceForCurrentLocale()

        }


        state.keyboardContext.locales = [.persian, .english]

        // Check when the keyboard is about to be dismissed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        // Initialize AutoSuggestEngine for current locale - use userInitiated for faster startup
        // The engine now uses progressive loading internally, so initial response is fast
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            Task { [weak self] in
                guard let self = self else { return }
                if self.suggestEngine == nil {
                    let localeId = self.state.keyboardContext.locale.identifier
                    let engine = await AutoSuggestProvider.shared.getEngine(for: localeId)
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        if let e = engine {
                            self.suggestEngine = e
                            self.currentSuggestLanguageKey = Locale(identifier: localeId).languageCode ?? localeId
                        }
                    }
                }
            }
        }
        
                // Set custom action handler
        services.actionHandler = CustomActionHandler(controller: self)
        
        // Set custom style service for bold callouts
        services.styleService = CalloutStyleService(keyboardContext: self.state.keyboardContext)
        

    }
    
    override func viewWillSetupKeyboardView() {
        setupKeyboardView { controller in
            RootKeyboardView(controller: controller as! KeyboardViewController)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop periodic sync timer in mirror engine
        self.mirrorEngine?.stopPeriodicSync()
        self.mirrorEngine = nil

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Initialize mirror text with current documentText
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Get initial document text
            let beforeText = self.textDocumentProxy.documentContextBeforeInput ?? ""
            let afterText = self.textDocumentProxy.documentContextAfterInput ?? ""
            let initialText = beforeText + afterText

            // Stop periodic sync timer in mirror engine
            self.mirrorEngine?.stopPeriodicSync()
            self.mirrorEngine = nil

            // Initialize MirrorTextEngine for tracking full text
            self.mirrorEngine = MirrorTextEngine(proxy: self.textDocumentProxy)

            // Initialize mirror with documentText if available, otherwise use before+after
            let textToInit = !self.documentText.isEmpty ? self.documentText : initialText
            
            if let mirror = self.mirrorEngine, !textToInit.isEmpty {
                let cursorPos = min(textToInit.count, beforeText.count)
                mirror.setFullText(textToInit, cursorAt: cursorPos)
                self.updateCurrentFullTextFromMirror()
                Logger.debug("MirrorTextEngine: initialized with documentText, length: \(textToInit.count), cursor: \(cursorPos)")
            } else {
                // Fallback: perform sync
                self.mirrorEngine?.performImmediateSync()
                self.updateCurrentFullTextFromMirror()
            }
        }
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        // Update document text immediately when selection changes
        updateDocumentText()
        // Use handleCursorChange for cursor-only updates - safer than full sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.mirrorEngine?.handleCursorChange(proxy: self.textDocumentProxy)
            self.updateCurrentFullTextFromMirror()
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateDocumentText()
        // Sync mirror engine when text changes externally (paste, cut, etc.)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.mirrorEngine?.performImmediateSync()
            self.updateCurrentFullTextFromMirror()
        }
        // Other updates can still be dispatched if needed
        DispatchQueue.main.async {
            self.updatePredictions()
        }
    }
    
    // Override insertText to track in mirror engine
    override func insertText(_ text: String) {
        let selectedText = textDocumentProxy.selectedText
        Logger.debugFullText("insertText=\(text)")

        super.insertText(text)
        
        // Update mirror engine for selection replacement
        if let selected = selectedText, !selected.isEmpty {
            mirrorEngine?.deleteSelection(length: selected.count)
        }

        // Update mirror engine
        mirrorEngine?.handleInsert(text: text)
        updateCurrentFullTextFromMirror()
    }
    
    // Override deleteBackward to track in mirror engine
    override func deleteBackward() {
        let selectedText = textDocumentProxy.selectedText ?? ""

        super.deleteBackward()
        
        // Update mirror engine
        if  !selectedText.isEmpty {
             mirrorEngine?.deleteSelection(length: selectedText.count)
             self.textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
        } else {
             mirrorEngine?.handleDeleteBackward()
        }
        updateCurrentFullTextFromMirror()
    }
    
    // Helper to update currentFullText from mirror engine
    private func updateCurrentFullTextFromMirror() {
        guard let mirror = mirrorEngine else { return }
        currentFullText = mirror.mirrorText
        Logger.debugFullText("currentFullText updated from mirror: count=\(currentFullText.count)")
    }
    
    // Helper to update mirror when entire text is replaced (used by grammar, tone, translation)
    private func updateMirrorAfterTextReplacement(newText: String) {
        guard let mirror = mirrorEngine else { return }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let cursorPos = min(newText.count, before.count)
        mirror.setFullText(newText, cursorAt: cursorPos)
        updateCurrentFullTextFromMirror()
        Logger.debug("MirrorTextEngine: updated after text replacement, new length: \(newText.count), cursor: \(cursorPos)")
    }

    // Handle paste events
    override func paste(_ sender: Any?) {
        super.paste(sender)

        // If in translation mode, handle paste for translation input
        if selectedToolbarItem == .translate {
            // Get the pasted text from the pasteboard
            if let pastedText = UIPasteboard.general.string {
                // Insert the pasted text at the current cursor position in translation input
                insertTextAtCursor(pastedText)
                return
            }
        }
        
        // Update document text after paste for non-translation modes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateDocumentText()
            // Sync mirror engine after paste
            self.mirrorEngine?.performImmediateSync()
            self.updateCurrentFullTextFromMirror()
        }
    }

   //move cursor to the end of the document
    func moveCursorToEnd() async {
        let proxy = self.textDocumentProxy
        let endSafetyLimit = 500
        var endSafety = 0
        var isEmptySafety = 0
        var countSafety = 20

        while true {
            let after = proxy.documentContextAfterInput ?? ""
            proxy.adjustTextPosition(byCharacterOffset: after.count == 0 ? countSafety : after.count)
            try? await Task.sleep(nanoseconds: 250_000_000)

            if after.isEmpty {
                isEmptySafety += 1
                countSafety -= 5
            } else {
                isEmptySafety = 0
                countSafety = 20

            }

//            Logger.debugFullText("after: \(after) count: \(after.count)  isEmptySafety: \(isEmptySafety) countSafety: \(countSafety)")
            endSafety += 1


            if isEmptySafety > 4 || countSafety < 1 || endSafety >= endSafetyLimit { break }
        }
    }

    func getFullText() async -> String {
        let proxy = self.textDocumentProxy
        var currentSelectedText = proxy.selectedText ?? ""

        // Capture original cursor position info
        let originalBeforeLength = proxy.documentContextBeforeInput?.count ?? 0

        await moveCursorToEnd()

        // 2) Walk from end to start, collecting full before each time to avoid small chunk issues
        var collectedText = ""
        var safetyCounter = 0
        let safetyLimit = 50_000

        while true {
            // Check for cancellation
            if Task.isCancelled {
                // Restore cursor to original position before returning
                proxy.adjustTextPosition(byCharacterOffset: originalBeforeLength)
                self.isCapturingFullText = false

                return collectedText
            }
            
            let before = proxy.documentContextBeforeInput ?? ""
            if before.isEmpty { break }

            let moveCount = before.count
            let chunk = before
            collectedText = chunk + collectedText

            proxy.adjustTextPosition(byCharacterOffset: -moveCount)
            try? await Task.sleep(nanoseconds: 250_000_000) // Increased sleep for better reliability

            safetyCounter += 1
            if safetyCounter > safetyLimit { break }
        }

        // 3) Restore cursor to original position
        proxy.adjustTextPosition(byCharacterOffset: originalBeforeLength)
        try? await Task.sleep(nanoseconds: 50_000_000)
        await moveCursorToEnd()

        // Sync mirror engine with scanned full text
        DispatchQueue.main.async {
            // Update mirror engine with scanned full text and cursor position
            if let mirror = self.mirrorEngine {
                let cursorPos = min(collectedText.count, originalBeforeLength)
                mirror.setFullText(collectedText, cursorAt: cursorPos)
            }
            self.updateCurrentFullTextFromMirror()
            Logger.debugFullText("currentFullText updated after getFullText scan: count=\(self.currentFullText.count)")
        }

        if !currentSelectedText.isEmpty {
           var selectedText = reconstructSelectedText(fullText: collectedText, rawSelectedText: currentSelectedText)
           self.currentFullSelectedText = selectedText
           return selectedText
        } else{
           self.currentFullSelectedText = ""
        }

        // Return exact text, without trimming to avoid losing whitespace/newlines
        return collectedText
    }
    func deleteFullText() async {
        let proxy = self.textDocumentProxy

        // Capture original cursor position info
        let originalBeforeLength = proxy.documentContextBeforeInput?.count ?? 0

        await moveCursorToEnd()
        var safetyCounter = 0
        let safetyLimit = 50_000
        var safetyDeleteRetry = 16
            var safetyDeleteRetryCount = 0

        while true {
            // Check for cancellation
            if Task.isCancelled {
                return
            }
            
            let before = proxy.documentContextBeforeInput ?? ""
            if before.isEmpty { 
                for _ in 0..<safetyDeleteRetry {
                      if Task.isCancelled {
                          return
                       }

                    safetyDeleteRetryCount += 1
                    proxy.adjustTextPosition(byCharacterOffset: -1)
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    if proxy.documentContextBeforeInput?.isEmpty == false {
                        break
                    }
                }
                if proxy.documentContextBeforeInput?.isEmpty == true {
                    break
                }

                 }

            for char in before {
                proxy.deleteBackward()
            }
            if proxy.documentContextAfterInput?.isEmpty == false {
            proxy.adjustTextPosition(byCharacterOffset: 1)
            }
            try? await Task.sleep(nanoseconds: 250_000_000) // Increased sleep for better reliability

            safetyCounter += 1
            if safetyCounter > safetyLimit || safetyDeleteRetryCount >= safetyDeleteRetry { break }
        }
    }

    func replaceOnFullText(replacements: [(original: String, replaceText: String)]) async {
        self.isCapturingFullText = true

        Logger.debug("replaceOnFullText start count=\(replacements.count)")

        let proxy = self.textDocumentProxy

        // Capture original cursor position info
        let originalBeforeLength = proxy.documentContextBeforeInput?.count ?? 0

        await moveCursorToEnd()

        var safetyCounter = 0
        let safetyLimit = 50_000

        var foundCount = 0
        while true {
           if Task.isCancelled {
                self.isCapturingFullText = false
               return
           }

            var replaceCount = 0
            let before = proxy.documentContextBeforeInput ?? ""
            if before.isEmpty { break }

            let moveCount = before.count

            // search on before to see have any original in it(case sensitive)
            for (index, replacement) in replacements.enumerated() {
            let cleanedSuggestion = grammarAPIService.cleanedSuggestionText(from: replacement.replaceText)

                    var correctedText = before
                        if let range = correctedText.range(of: replacement.original) {
                            correctedText = correctedText.replacingCharacters(in: range, with: cleanedSuggestion)
                         if correctedText != before {
                         foundCount += 1
                             replaceCount = self.replaceEntireDocumentText(with: correctedText, originalText: before)
                             try? await Task.sleep(nanoseconds: 250_000_000)
                             }
                             }


            }

            proxy.adjustTextPosition(byCharacterOffset: -moveCount - (replaceCount))
            try? await Task.sleep(nanoseconds: 250_000_000) // Increased sleep for better reliability

            safetyCounter += 1
            if safetyCounter > safetyLimit || foundCount == replacements.count { break }
        }
        // 3) Restore cursor to original position
        proxy.adjustTextPosition(byCharacterOffset: originalBeforeLength)
        try? await Task.sleep(nanoseconds: 50_000_000)
        self.isCapturingFullText = false



    }
    
    /**
     Reconstructs the full selected text from the potentially truncated version returned by the proxy.
     
     - Parameters:
        - fullText: The entire scraped text from the document.
        - rawSelectedText: The text returned by proxy.selectedText (may be truncated).
     - Returns: The reconstructed string if successful, otherwise rawSelectedText.
     */
    func reconstructSelectedText(fullText: String, rawSelectedText: String) -> String {
        Logger.debug("reconstructSelectedText: start, fullText count=\(fullText.count), rawSelectedText count=\(rawSelectedText.count)")
        
        // 1. Exact Match Check
        if fullText.contains(rawSelectedText) {
            Logger.debug("reconstructSelectedText: Exact match found.")
            return rawSelectedText
        }
        
        // 2. Reconstruction (Truncation Handling)
        let totalCount = rawSelectedText.count
        
        // Define extraction length (e.g., 20 chars), but guard against short strings
        let extractionLength = min(8, totalCount / 2)
        
        if extractionLength <= 0 {
            Logger.debug("reconstructSelectedText: Text too short for reconstruction.")
            // String is too short to split into prefix/suffix meaningfully for reconstruction
            return rawSelectedText
        }
        
        let prefix = String(rawSelectedText.prefix(extractionLength))
        let suffix = String(rawSelectedText.suffix(extractionLength))
        Logger.debug("reconstructSelectedText: prefix=\(prefix), suffix=\(suffix)")
        
        // 3. Select All Heuristic
        // If the prefix matches the start of fullText AND the suffix matches the end of fullText,
        // we assume the user selected the entire document.
        if fullText.hasPrefix(prefix) && fullText.hasSuffix(suffix) {
            Logger.debug("reconstructSelectedText: Select All heuristic triggered. Returning fullText.")
            return fullText
        }
        
        // 4. Search for locations in fullText
        // We look for the first occurrence of prefix
        guard let prefixRange = fullText.range(of: prefix) else {
            Logger.debug("reconstructSelectedText: Prefix not found in fullText.")
            return rawSelectedText
        }
        
        // We look for the suffix. To be valid, it must appear AFTER the prefix.
        // We search in the substring starting from the end of the found prefix.
        let searchRangeForSuffix = prefixRange.upperBound..<fullText.endIndex
        
        guard let suffixRange = fullText.range(of: suffix, range: searchRangeForSuffix) else {
            Logger.debug("reconstructSelectedText: Suffix not found after prefix in fullText.")
            return rawSelectedText
        }
        
        // 5. Validation & Extraction
        // The reconstructed text is from the start of the prefix to the end of the suffix
        let reconstructedRange = prefixRange.lowerBound..<suffixRange.upperBound
        let reconstructedText = String(fullText[reconstructedRange])
        
        Logger.debug("reconstructSelectedText: Reconstruction successful. Length: \(reconstructedText.count)")
        return reconstructedText
    }

    func updateDocumentText(myDocumentText: String?=nil) {
        // Debounce: Cancel previous work item if still pending
        updateDocumentTextWorkItem?.cancel()
        if self.selectedToolbarItem == .translate || self.isCapturingFullText == true {
            return
        }
        if (myDocumentText != nil) {
            self.previousDocumentText = ""
        }
        let before = self.textDocumentProxy.documentContextBeforeInput ?? ""
        let after = self.textDocumentProxy.documentContextAfterInput ?? ""

        if (after + before).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty  && myDocumentText == nil{
            self.updateDocumentTextRaw()
        }


        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Prioritize selected text over before/after context
                if (myDocumentText == nil) {
                    self.updateDocumentTextRaw()
                }

                // Handle grammar loading state
                if self.selectedToolbarItem == .grammar {
                    let trimmedText = self.documentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedText.isEmpty && trimmedText.count >= 4 && self.documentText != self.previousDocumentText {
                        self.previousDocumentText = self.documentText
                        let selectedText = self.textDocumentProxy.selectedText ?? ""

                        if !selectedText.isEmpty || myDocumentText != nil {
                        Task {
                            await self.callGrammarAPI()
                        }
                        }
                    } else {
                        self.displayText = self.documentText
                        self.previousDocumentText = self.documentText
                    }
                } else if self.selectedToolbarItem == .tone {
                    let trimmedText = self.documentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedText.isEmpty && trimmedText.count >= 4 && self.documentText != self.previousDocumentText {
                        let selectedText = self.textDocumentProxy.selectedText ?? ""
                        if !selectedText.isEmpty || myDocumentText != nil {

                        self.isToneLoading = true
                        self.previousDocumentText = self.documentText
                        // Call tone API with debounce
                        self.callToneAPIWithDebounce()
                        }
                    } else {
                        self.displayText = self.documentText
                        self.previousDocumentText = self.documentText
                    }
                } else {
                    self.displayText = self.documentText
                    self.previousDocumentText = self.documentText
                    self.showGrammarSuggestion = false
                    self.grammarWordOutputs = []
                    self.grammarSuggestionsList = []
                    self.grammarErrorMessage = ""
                    self.isGrammarLoading = false
                    self.showToneSuggestion = false
                    self.toneAdjustedText = ""
                    self.toneErrorMessage = ""
                    self.toneNoSuggestion = false
                    self.isToneLoading = false
                    self.isToneApplyLoading = false
                    self.lastToneAPICallType = .normal // Reset to default
                }

        if(self.selectedToolbarItem != .translate) {
                self.refreshKeyboardView()

            }
            }
        }
        updateDocumentTextWorkItem = workItem
        if self.selectedToolbarItem == .grammar {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0, execute: workItem)
        }
        else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
        }

    }

    // Lightweight updater used for key type/delete actions to avoid heavy work
    func updateDocumentTextRaw() {
              if let selectedText = self.textDocumentProxy.selectedText, !selectedText.isEmpty {
                  self.documentText = selectedText
              } else {
                  let before = self.textDocumentProxy.documentContextBeforeInput ?? ""
                  let after = self.textDocumentProxy.documentContextAfterInput ?? ""
                  self.documentText = before + after
              }
              if self.documentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                 self.backgroundGrammarState = .idle
                 self.backgroundGrammarCorrections = []

              }

              Logger.debug("self.documentText=\(self.documentText)")
    }
    func updateDocumentTextFromKeystroke() {
         Logger.debug("updateDocumentTextFromKeystroke")
         self.updateDocumentTextRaw()
         
         // Sync mirror engine and update currentFullText after keystroke
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
             self.mirrorEngine?.performImmediateSync()
             self.updateCurrentFullTextFromMirror()
         }

         self.displayText = self.documentText
         self.previousDocumentText = self.documentText
         self.updatePredictions()
         
         // Trigger background grammar check when not in special modes
         if self.selectedToolbarItem == nil {
             self.triggerBackgroundGrammarCheck()
         }

         self.typedCount = self.typedCount + 1
         //if user typed a lot then capture full text
         if self.typedCount >= 80 {
             self.isCapturedFullTextForGrammar = false
         }
    }

    // Update predictions based on current cursor and locale
    private func updatePredictions() {
        getSuggestionsWorkItem?.cancel()
        if self.isCapturingFullText || suggestEngine == nil {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isCapturingFullText || self.suggestEngine == nil{
                return
            }

            // Only show predictions in normal keyboard (not translate/grammar/tone)
            if self.selectedToolbarItem != nil {
                if !self.predictedWords.isEmpty {
                    DispatchQueue.main.async {
                        self.predictedWords = []
                    }
                }
                return
            }

            // Only support predictions for English or Persian (use robust language code checks)
            let localeId = self.state.keyboardContext.locale.identifier
            let languageCode = Locale(identifier: localeId).languageCode ?? localeId
            let isEnglish = languageCode == "en" || localeId.lowercased().hasPrefix("en")
            let isPersian = languageCode == "fa" || localeId.lowercased().hasPrefix("fa")
            if !(isEnglish || isPersian) {
                if !self.predictedWords.isEmpty {
                    DispatchQueue.main.async {
                        self.predictedWords = []
                    }
                }
                return
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                let before = self.textDocumentProxy.documentContextBeforeInput ?? ""
                // Ensure engine matches current language (lazy reload with fast progressive loading)
                let languageKey = Locale(identifier: self.state.keyboardContext.locale.identifier).languageCode ?? self.state.keyboardContext.locale.identifier
                if self.currentSuggestLanguageKey != languageKey {
                    Task { [weak self] in
                        guard let self = self else { return }
                        let localeId = self.state.keyboardContext.locale.identifier
                        let engine = await AutoSuggestProvider.shared.getEngine(for: localeId)
                        await MainActor.run { [weak self] in
                            guard let self = self else { return }
                            if let e = engine {
                                self.suggestEngine = e
                                self.currentSuggestLanguageKey = languageKey
                            }
                        }
                    }
                    // Return early, predictions will come in next cycle after engine is ready
                    return
                }
                // Extract the current word prefix before the cursor
                
            let pattern = isEnglish ? "[A-Za-z']+$" : "[\\s\\S]+"
                let regex = try? NSRegularExpression(pattern: pattern)
                let nsBefore = before as NSString
                let range = NSRange(location: 0, length: nsBefore.length)
                let match = regex?.matches(in: before, options: [], range: range).last

                let prefix: String = {
                    guard let m = match else { return "" }
                    let r = m.range
                    guard r.location != NSNotFound else { return "" }
                    return nsBefore.substring(with: r)
                }()

                if prefix.isEmpty {
                    // Check if we have a trailing space indicating end of word, to trigger next-word suggestions
                    let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && (before.hasSuffix(" ") || before.hasSuffix("\n")) {
                         let lastWord = trimmed.components(separatedBy: .whitespacesAndNewlines).last ?? trimmed
                         let nextSuggestions = self.suggestEngine?.suggestNextWord(contextBefore: before, lastWord: lastWord, limit: 10) ?? []
                         if !nextSuggestions.isEmpty {
                             DispatchQueue.main.async {
                                 self.predictedWords = nextSuggestions
                                 self.isShowingNextWordSuggestions = true
                             }
                             return
                         }
                    }

                    // Keep contextual next-word suggestions if we're in that mode
                    if self.isShowingNextWordSuggestions { return }
                    if !self.predictedWords.isEmpty {
                        DispatchQueue.main.async {
                            self.predictedWords = []
                        }
                    }
                    return
                }

                // Normalize prefix per language (lowercase for English, no-op for Persian)
                var normalizedPrefix = isEnglish ? prefix.lowercased() : prefix
                //split on space and get las word
                normalizedPrefix = normalizedPrefix.components(separatedBy: " ").last ?? normalizedPrefix
                
                // Handle Persian/Arbitrary case where prefix matches but normalizedPrefix becomes empty due to trailing space
                if normalizedPrefix.isEmpty && (before.hasSuffix(" ") || before.hasSuffix("\n")) {
                    let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                         let lastWord = trimmed.components(separatedBy: .whitespacesAndNewlines).last ?? trimmed
                         let nextSuggestions = self.suggestEngine?.suggestNextWord(contextBefore: before, lastWord: lastWord, limit: 10) ?? []
                         if !nextSuggestions.isEmpty {
                             DispatchQueue.main.async {
                                 self.predictedWords = nextSuggestions
                                 self.isShowingNextWordSuggestions = true
                             }
                             return
                         }
                    }
                }
                
                // Once user starts typing, switch off contextual next-word mode
                self.isShowingNextWordSuggestions = false
                let suggestions = self.suggestEngine?.suggest(prefix: normalizedPrefix, limit: 10) ?? []
                let limited = Array(suggestions.prefix(10))

                DispatchQueue.main.async {
                    self.predictedWords = limited
                }
            }
        }
        getSuggestionsWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: workItem)
    }

    // Apply selected prediction: replace current word prefix with full suggestion and add space
    private func applyPrediction(word: String) {
        let proxy = self.textDocumentProxy
        let before = proxy.documentContextBeforeInput ?? ""
        let localeId = self.state.keyboardContext.locale.identifier
        let languageCode = Locale(identifier: localeId).languageCode ?? localeId
        let isEnglish = languageCode == "en" || localeId.lowercased().hasPrefix("en")
        let isPersian = languageCode == "fa" || localeId.lowercased().hasPrefix("fa")
        let pattern = isEnglish ? "[A-Za-z']+$" : "[\\s\\S]+"
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsBefore = before as NSString
        let range = NSRange(location: 0, length: nsBefore.length)
        let match = regex?.matches(in: before, options: [], range: range).last
        var originalPrefix: String? = nil
        if let m = match {
            let r = m.range
            if r.location != NSNotFound {
                originalPrefix = nsBefore.substring(with: r)
                originalPrefix = originalPrefix?.components(separatedBy: " ").last ?? originalPrefix
                originalPrefix?.removeAll(where: { $0 == "\n"})

                if let prefix = originalPrefix {
                    // Sync mirror cursor position first to ensure accuracy
                    if let mirror = self.mirrorEngine {
                        // Sync cursor position with actual document cursor
                        let beforeCount = before.count
                        mirror.cursorPosition = min(mirror.mirrorText.count, beforeCount)
                        
                        // Update mirror engine: delete the prefix
                        let prefixCount = prefix.count
                        for _ in 0..<prefixCount {
                            if mirror.cursorPosition > 0 && mirror.mirrorText.count > 0 {
                                let removeIndex = mirror.mirrorText.index(mirror.mirrorText.startIndex, offsetBy: max(0, mirror.cursorPosition - 1))
                                mirror.mirrorText.remove(at: removeIndex)
                                mirror.cursorPosition = max(0, mirror.cursorPosition - 1)
                            }
                        }
                        Logger.debug("MirrorTextEngine: applyPrediction - deleted prefix '\(prefix)' (\(prefixCount) chars), text length: \(mirror.mirrorText.count), cursor: \(mirror.cursorPosition)")
                    }
                    
                    for _ in 0..<prefix.count { proxy.deleteBackward() }
                }
            }
        }

        // Restore casing based on the user's original prefix
        let casedWord: String
        if let orig = originalPrefix, !orig.isEmpty {
            casedWord = suggestEngine?.matchCasing(of: orig, to: word) ?? word
        } else {
            casedWord = word
        }

        let textToInsert = casedWord + " "
        
        // Update mirror engine: insert the word + space
        if let mirror = self.mirrorEngine {
            let insertIndex = mirror.mirrorText.index(mirror.mirrorText.startIndex, offsetBy: min(mirror.cursorPosition, mirror.mirrorText.count))
            mirror.mirrorText.insert(contentsOf: textToInsert, at: insertIndex)
            mirror.cursorPosition += textToInsert.count
            Logger.debugFullText("MirrorTextEngine: applyPrediction - inserted '\(textToInsert)' at cursor, text length: \(mirror.mirrorText.count), cursor: \(mirror.cursorPosition)")
            updateCurrentFullTextFromMirror()
        }
        
        proxy.insertText(textToInsert)
        
        // After applying a suggestion and adding a space, propose next-word suggestions based on context.
        let updatedBefore = proxy.documentContextBeforeInput ?? ""
        let nextSuggestions = suggestEngine?.suggestNextWord(contextBefore: updatedBefore, lastWord: casedWord, limit: 6) ?? []
        self.predictedWords = nextSuggestions
        self.isShowingNextWordSuggestions = !nextSuggestions.isEmpty
        self.refreshKeyboardView()
        // Trigger background grammar check when not in special modes
        if self.selectedToolbarItem == nil {
            self.triggerBackgroundGrammarCheck()
        }
         self.typedCount = self.typedCount + casedWord.count
         //if user typed a lot then capture full text
         if self.typedCount >= 80 {
             self.isCapturedFullTextForGrammar = false
         }


}


     func keyboardView(controller: KeyboardInputViewController) -> some View{
        return KeyboardView(
            state: controller.state,
            services: controller.services,
            buttonContent: { params in
                if case .character(let char) = params.item.action,
                   char == String.zeroWidthSpace {
                    VStack(spacing: 1) {
                        Image(systemName: "arrowtriangle.down.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 8,height: 5)
                        VStack(spacing: 1) {
                            ForEach(0..<5, id: \.self) { _ in
                                Circle()
                                    .frame(width: 2, height: 2)
                            }
                        }
                    }
                } else if case .custom(let title) = params.item.action, title == "languageSwitch" {
                    // Language switch button with globe icon
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.primary)
                } else if case .custom(let title) = params.item.action, title == "applyTranslation" {
                    // Apply translation button - blue box with centered white checkmark
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.Primary.blue(isDarkMode: controller.traitCollection.userInterfaceStyle == .dark))
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if case .primary = params.item.action,
                          self.state.keyboardContext.returnKeyTypeOverride == .custom(title: "applyTranslation") {
                    // Replace system return key UI when overridden to applyTranslation
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.Primary.blue(isDarkMode: controller.traitCollection.userInterfaceStyle == .dark))
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if case .primary = params.item.action,
                          //multiline inputs usually use the default return key
                          (self.textDocumentProxy.returnKeyType == .default && self.textDocumentProxy.keyboardType?.keyboardType == .alphabetic) {
                    // Show a return-style icon for multiline text inputs
                    Image(systemName: "arrow.turn.down.left")
                        .resizable()
                        .scaledToFit()
                         .font(.system(size: 18, weight: .light))
                        .frame(width: 18, height: 18)
                        .foregroundColor(.primary)

                }
                 else if case .character(let char) = params.item.action,
                          !Utils.isPersianCharacter(Character(char)),
                          UIAccessibility.isBoldTextEnabled {
                    // Bold English character keys when iOS Bold Text is enabled
                    if #available(iOSApplicationExtension 16.0, *) {
                        params.view.fontWeight(.medium)
                    } else {
                    }
                }
                 else {
                    params.view
                }
            },
            buttonView: { params in params.view },
            collapsedView: { $0.view },
            emojiKeyboard: { params in
                CompleteEmojiView(actionHandler: controller.services.actionHandler,
                isDarkMode: controller.traitCollection.userInterfaceStyle == .dark,
                onClose: { self.refreshKeyboardView() }
                )
                    .frame(maxWidth: .infinity)
                    .frame(height: CGFloat(params.style.totalHeight+80))
            },
            toolbar: { $0.view }
        )
        .offset(y: 1.2)
    }

fileprivate func createKeyboardViewContent(controller: KeyboardInputViewController) -> some View {
        VStack(spacing: 0) {
            // Check if keyboard type is numeric - if so, show appropriate numeric views
            if controller.textDocumentProxy.keyboardType == .decimalPad ||
               controller.textDocumentProxy.keyboardType == .phonePad ||
               controller.textDocumentProxy.keyboardType == .numberPad {
                // Use KeyboardKit's dedicated NumberPad view in number pad mode
                // Customize: Remove ABC key and enlarge buttons by increasing height
                Keyboard.NumberPad(
                    actions: [
                        .init(characters: "123"),
                        .init(characters: "456"),
                        .init(characters: "789"),
                        [.none,.character("0"), .backspace]
                    ],
                    actionHandler: controller.services.actionHandler,
                    styleService: controller.services.styleService,
                    keyboardContext: controller.state.keyboardContext
                )
                .padding(10)
                .frame(height: 225)
            } else
            if !self.hasFullAccess && (self.selectedToolbarItem == .grammar || self.selectedToolbarItem == .tone || self.selectedToolbarItem == .translate) {
                                FullAccessErrorView(
                                    isDarkMode: controller.traitCollection.userInterfaceStyle == .dark,
                                    backgroundColor: AppColors.Background.keyboard(isDarkMode: controller.traitCollection.userInterfaceStyle == .dark),
                                    onBackTap: {
                                        // Cancel getFullText task when navigating back from grammar
                                        self.getFullTextTask?.cancel()
                                        self.getFullTextTask = nil
                                        self.replaceFullTextTask?.cancel()
                                        self.replaceFullTextTask = nil

                                        self.selectedToolbarItem = nil
                                        self.showGrammarSuggestion = false
                                        self.grammarWordOutputs = []
                                        self.grammarSuggestionsList = []
                                        self.grammarErrorMessage = ""
                                        self.isGrammarLoading = false
                                        self.isGrammarApplyLoading = false
                                        self.refreshKeyboardView()
                                    }
                                )
                            }

           else if self.selectedToolbarItem == .grammar {
                // Show Grammar View with integrated suggestion functionality
                GrammarView(
                    onBackTap: {
                        // Cancel getFullText task when navigating back from grammar
                        self.getFullTextTask?.cancel()
                        self.getFullTextTask = nil
                        self.replaceFullTextTask?.cancel()
                        self.replaceFullTextTask = nil
                        self.selectedToolbarItem = nil
                        self.refreshKeyboardView()
                    },
                    onApplyTap: { [weak self] index in
                        self?.replaceFullTextTask?.cancel()
                        self?.replaceFullTextTask = Task {
                            await self?.applyGrammarCorrection(at: index)
                        }
                    }
,
                    onCloseTap: {
                    index in
                        self.removeGrammarSuggestion(at: index)

                    },
                    onApplyAllTap: {
                        self.replaceFullTextTask?.cancel()
                        self.replaceFullTextTask = Task {
                                            [weak self] in
                                            guard let self = self else { return }
                                            await self.applyAllGrammarCorrections()
                        }
                    },
                    onRetryTap: {
                        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                        if(!isLoggedIn){
                            Utils.openMainAppForSignIn(from: self)
                            return
                        }
                        // Clear error state and retry grammar API call
                        self.grammarErrorMessage = ""
                        self.refreshKeyboardView()
                        Task {
                            await self.callGrammarAPI()
                        }
                    },
                    text: self.displayText,
                    isLoading: self.isGrammarLoading || self.isBackgroundGrammarLoading,
                    isApplyLoading: self.isGrammarApplyLoading,
                    showSuggestion: self.showGrammarSuggestion,
                    wordOutputs: self.grammarWordOutputs,
                    suggestionsList: self.grammarSuggestionsList,
                    grammarErrorMessage: self.grammarErrorMessage,
                    grammarNoSuggestion: self.grammarNoSuggestion,
                    backgroundColor: AppColors.Background.keyboard(isDarkMode: controller.traitCollection.userInterfaceStyle == .dark),
                    isDarkMode: controller.traitCollection.userInterfaceStyle == .dark
                )
            } else if self.selectedToolbarItem == .tone {
                // Show Tone View
                ToneView(
                    onBackTap: {
                        // Cancel any ongoing task
                        self.deleteFullTextTask?.cancel()
                        self.deleteFullTextTask = nil
                        self.getFullTextTask?.cancel()
                        self.getFullTextTask = nil

                        self.selectedToolbarItem = nil
                        self.showToneSuggestion = false
                        self.toneAdjustedText = ""
                        self.toneErrorMessage = ""
                        self.toneNoSuggestion = false
                        self.isToneLoading = false
                        self.isToneApplyLoading = false
                        self.currentToneQueryId = nil
                        self.lastToneAPICallType = .normal // Reset to default
                        self.refreshKeyboardView()
                    },
                    onApplyTap: { index in
                                self.deleteFullTextTask?.cancel()
                                self.deleteFullTextTask = Task { [weak self] in
                                    guard let self = self else { return }
                                    await self.applyToneCorrection()
                                }
                    },
                    onCloseTap: { index in
                        // Cancel any ongoing deleteFullText task
                        self.deleteFullTextTask?.cancel()
                        
                        // Track the tone rejection before closing
                        if let toneId = self.currentToneQueryId {
                            self.trackerAPIService.trackToneAction(toneId: toneId, action: .rejected)
                        }
                        
                        self.showToneSuggestion = false
                        self.toneAdjustedText = ""
                        self.toneErrorMessage = ""
                        self.toneNoSuggestion = false
                        self.isToneLoading = false
                        self.isToneApplyLoading = false
                        self.selectedToolbarItem = nil
                        self.currentToneQueryId = nil
                        self.lastToneAPICallType = .normal // Reset to default
                        self.refreshKeyboardView()
                    },
                    onRephraseTap: { _ in
                        Task {
                            await self.rephraseTone()
                        }
                    },
                    onRetryTap: {
                        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                        if(!isLoggedIn){
                            Utils.openMainAppForSignIn(from: self)
                            return
                        }
                        // Clear error state and retry the same type of tone API call
                        self.toneErrorMessage = ""
                        self.refreshKeyboardView()
                        Task {
                            switch self.lastToneAPICallType {
                            case .normal:
                                await self.callToneAPI()
                            case .rephrase:
                                await self.rephraseTone()
                            }
                        }
                    },
                    text: self.displayText,
                    isLoading: self.isToneLoading,
                    isApplyLoading: self.isToneApplyLoading,
                    toneAdjustedText: self.toneAdjustedText,
                    toneErrorMessage: self.toneErrorMessage,
                    toneNoSuggestion: self.toneNoSuggestion,
                    backgroundColor: AppColors.Background.keyboard(isDarkMode: controller.traitCollection.userInterfaceStyle == .dark) ,
                    selectedTone: Binding(
                        get: { self.selectedTone },
                        set: { 
                        self.selectedTone = $0
                        // Reset tone states when tone changes
                        self.showToneSuggestion = false
                        self.toneAdjustedText = ""
                        self.toneErrorMessage = ""
                        self.toneNoSuggestion = false
                        self.isToneLoading = false
                        self.isToneApplyLoading = false
                        self.lastToneAPICallType = .normal // Reset to default when tone changes
                        
                        // Update UI immediately before calling API
                        self.refreshKeyboardView()

                        Logger.debug("selected tone self.documentText=\(self.documentText)")
                        // Trigger tone API call when tone changes
                    let trimmedText = self.documentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedText.isEmpty && trimmedText.count >= 4 {
                            self.isToneLoading = true
                            self.currentToneQueryId = nil
                            self.refreshKeyboardView()

                            self.callToneAPIWithDebounce()
                        }
                        }
                    ),
                    isDarkMode: controller.traitCollection.userInterfaceStyle == .dark
                )
            } else if self.selectedToolbarItem == .translate {
                // Show Translation View and keyboard beneath
                TranslationView(
                    resetToken: self.translationResetToken,
                    onBackTap: {

                     if !self.temporaryTranslatedText.isEmpty{
                        self.applyTemporaryTranslation()
                     }

                        self.selectedToolbarItem = nil
                        self.showTranslationSuggestion = false
                        self.translatedText = ""
                        self.translationErrorMessage = ""
                        self.translationNoSuggestion = false
                        self.isTranslationLoading = false
                        self.translationInputText = "" // Clear translation input when going back
                        self.translationCursorPosition = 0
                        self.temporaryTranslatedText = ""
                        self.previousTranslatedText = ""
                        self.showTranslationApplyButton = false

                        // Reset keyboard context
                        self.state.keyboardContext.returnKeyTypeOverride = self.currentReturnKeyTypeOverride
                        self.refreshKeyboardView()
                        // Move cursor one character back to force document text update
                        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -2)

                        // Update document text after cursor adjustment
                        self.updateDocumentText()

                    },
                    onClearTap: {
                       // Track the translation rejection before clearing
                       if let translateId = self.currentTranslationQueryId {
                           self.trackerAPIService.trackTranslationAction(translateId: translateId, action: .rejected)
                       }


                        self.onClearTranslationTap()
                    },
                    onTranslationReceived: { translatedText, queryId in
                        // Store the translation query ID for tracking
                        self.currentTranslationQueryId = queryId
                        // Handle translation result from TranslationView
                        self.handleTranslationResult(translatedText)
                        // Clear any previous error on success
                        if !self.translationErrorMessage.isEmpty {
                            self.translationErrorMessage = ""
                            self.refreshKeyboardView()
                        }
                    },
                    onTranslationError: { message in
                        self.translationErrorMessage = message
                        // Ensure apply button stays visible state consistent
                        self.showTranslationApplyButton = false
                        self.refreshKeyboardView()
                    },
                    onClearError: {
                        if !self.translationErrorMessage.isEmpty {
                            self.translationErrorMessage = ""
                            self.refreshKeyboardView()
                        }
                    },
                    openMainApp: {
                     Utils.openMainAppForSignIn(from: self)
                    },
                    text: self.displayText,
                    isLoading: Binding(
                        get: { self.isTranslationLoading },
                        set: { self.isTranslationLoading = $0 }
                    ),
                    translatedText: self.translatedText,
                    translationErrorMessage: self.translationErrorMessage,
                    translationNoSuggestion: self.translationNoSuggestion,
                    backgroundColor: AppColors.Background.keyboard(isDarkMode: controller.traitCollection.userInterfaceStyle == .dark),
                    selectedTranslation: Binding(
                        get: { self.selectedTranslation },
                        set: { 
                            self.selectedTranslation = $0
                            // Use the optimized method instead of refreshing the entire keyboard
                            self.updateTranslationUI()
                        }
                    ),
                    inputBinding: Binding(
                        get: { self.translationInputText },
                        set: {
                            self.translationInputText = $0
                        }
                    ),
                    cursorPosition: Binding(
                        get: { self.translationCursorPosition },
                        set: {
                            self.translationCursorPosition = $0
                        }
                    ),
                    isDarkMode: controller.traitCollection.userInterfaceStyle == .dark
                )
                if self.translationErrorMessage.isEmpty {
                keyboardView(controller: controller)
                .frame(height: 200)
                .padding(.bottom, 33.6)
                }
             } else {
                                 // Show normal keyboard view
                 KeyboardToolbarView(
                    controller: self,
                    onLogoTap: {
                        self.services.feedbackService.triggerHapticFeedback(KeyboardFeedback.Haptic.lightImpact)
                        // Check if user is logged in, if not show sign-in tooltip
                        if !AppGroupManager.shared.isUserLoggedIn() {
                            self.showSignInTooltip = true
                            self.refreshKeyboardView()
                        }
                    },
                    onTranslateTap: {
                        self.selectedToolbarItem = .translate
                        // Set translation source based on current keyboard locale
                        let currentLocale = self.state.keyboardContext.locale
                        if currentLocale.identifier == Locale.persian.identifier {
                            self.selectedTranslation = TranslationType.persian.rawValue
                        } else {
                            self.selectedTranslation = TranslationType.english.rawValue
                        }

                        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                        if !isLoggedIn {
                            self.translationErrorMessage = "signInRequired"
                            self.refreshKeyboardView()
                            return
                        }

                        // Ensure translation input is ready and focused
                        self.translationInputText = ""
                        self.translationCursorPosition = 0
                        self.currentReturnKeyTypeOverride = self.state.keyboardContext.returnKeyTypeOverride
                        self.state.keyboardContext.returnKeyTypeOverride = .return
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.refreshKeyboardView()
                        }
                    },
                    onGrammarTap: {
                        // Cancel any existing getFullText task
                        self.getFullTextTask?.cancel()

                        self.selectedToolbarItem = .grammar
                        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                        if !isLoggedIn {

                             // Cancel any pending background check
                            self.backgroundGrammarWorkItem?.cancel()
                            self.grammarErrorMessage = "signInRequired"
                            self.refreshKeyboardView()
                            return
                        }
                        let proxy = self.textDocumentProxy
                        let selectedText = proxy.selectedText ?? ""

                        Logger.debug("self.selectedToolbarItem=\(self.selectedToolbarItem)")
                        if self.grammarNoSuggestion == false && self.hasFullAccess && (!self.isCapturedFullTextForGrammar || !selectedText.isEmpty){
                            // Cancel any pending background check
                            self.backgroundGrammarWorkItem?.cancel()

                            self.getFullTextTask?.cancel()
                            self.getFullTextTask = Task { [weak self] in
                                guard let self = self else { return "" }
                                await MainActor.run {
                                  self.showGrammarSuggestion = false
                                  self.grammarWordOutputs = []
                                  self.grammarSuggestionsList = []
                                  self.grammarErrorMessage = ""
                                  self.isGrammarLoading = false
                                  self.grammarNoSuggestion = false
                                  self.isGrammarApplyLoading = false
                                  self.previousDocumentText = ""
                                  self.displayText = self.documentText
                                  self.typedCount = 0
                                  }


                                // Get the current document text
                                let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
                                let afterText = textDocumentProxy.documentContextAfterInput ?? ""
                                let full = beforeText + afterText
                                
                                self.isCapturingFullText = true
                                self.isGrammarLoading = full.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
                                
                                let fullText = await self.getFullText()
                                await MainActor.run {
                                    
                                    self.documentText = fullText
                                    Logger.debugFullText("self.documentText=\(self.documentText.count) (from getFullText)=\(self.documentText)")
                                    self.isCapturingFullText = false

                                    self.updateDocumentText(myDocumentText: self.documentText)
                                }
                                return fullText
                            }
                        }

                        self.refreshKeyboardView()
                    },
                    onFormalTap: {
                        self.selectedTone = ToneType.formal.rawValue
                        self.selectedToolbarItem = .tone
                        self.showToneSuggestion = false
                        self.toneAdjustedText = ""
                        self.toneErrorMessage = ""
                        self.toneNoSuggestion = false
                        self.isToneLoading = false
                        self.isToneApplyLoading = false
                        self.lastToneAPICallType = .normal
                        self.predictedWords = []
                        self.isShowingNextWordSuggestions = false
                        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                        if !isLoggedIn {
                            self.toneErrorMessage = "signInRequired"
                            self.refreshKeyboardView()
                            return
                        }

                        self.getFullTextTask?.cancel()
                        if self.hasFullAccess {
                        self.getFullTextTask = Task { [weak self] in
                            guard let self = self else { return "" }
                            // Get the current document text
                            let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
                            let afterText = textDocumentProxy.documentContextAfterInput ?? ""
                            let full = beforeText + afterText
                            
                            self.isCapturingFullText = true
                            self.isToneLoading = full.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
                            
                            let fullText = await self.getFullText()
                            await MainActor.run {
                                
                                self.documentText = fullText
                                Logger.debugFullText("self.documentText=\(self.documentText.count) (from getFullText)=\(self.documentText)")
                                self.isCapturingFullText = false
                                
                                self.updateDocumentText(myDocumentText: self.documentText)
                            }
                            return fullText
                        }
                        }
                        self.refreshKeyboardView()
                    },
                    onFriendlyTap: {
                        self.selectedTone = ToneType.friendly.rawValue
                        self.selectedToolbarItem = .tone
                        self.showToneSuggestion = false
                        self.toneAdjustedText = ""
                        self.toneErrorMessage = ""
                        self.toneNoSuggestion = false
                        self.isToneLoading = false
                        self.isToneApplyLoading = false
                        self.lastToneAPICallType = .normal // Reset to default
                        self.predictedWords = []
                        self.isShowingNextWordSuggestions = false
                        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                        if !isLoggedIn {
                            self.toneErrorMessage = "signInRequired"
                            self.refreshKeyboardView()
                            return
                        }

                        self.getFullTextTask?.cancel()
                        if self.hasFullAccess {
                        self.getFullTextTask = Task { [weak self] in
                            guard let self = self else { return "" }
                            // Get the current document text
                            let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
                            let afterText = textDocumentProxy.documentContextAfterInput ?? ""
                            let full = beforeText + afterText
                            
                            self.isCapturingFullText = true
                            self.isToneLoading = full.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
                            
                            let fullText = await self.getFullText()
                            await MainActor.run {
                                
                                self.documentText = fullText
                                Logger.debugFullText("self.documentText=\(self.documentText.count) (from getFullText)=\(self.documentText)")
                                self.isCapturingFullText = false
                                
                                self.updateDocumentText(myDocumentText: self.documentText)
                            }
                            return fullText
                        }
                        }
                        self.refreshKeyboardView()
                    },
                    onConciseTap: {
                        self.selectedTone = ToneType.concise.rawValue
                        self.selectedToolbarItem = .tone
                        self.showToneSuggestion = false
                        self.toneAdjustedText = ""
                        self.toneErrorMessage = ""
                        self.toneNoSuggestion = false
                        self.isToneLoading = false
                        self.isToneApplyLoading = false
                        self.lastToneAPICallType = .normal // Reset to default
                        self.predictedWords = []
                        self.isShowingNextWordSuggestions = false
                        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                        if !isLoggedIn {
                            self.toneErrorMessage = "signInRequired"
                            self.refreshKeyboardView()
                            return
                        }

                        self.getFullTextTask?.cancel()
                        if self.hasFullAccess {
                        self.getFullTextTask = Task { [weak self] in
                            guard let self = self else { return "" }
                            // Get the current document text
                            let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
                            let afterText = textDocumentProxy.documentContextAfterInput ?? ""
                            let full = beforeText + afterText
                            
                            self.isCapturingFullText = true
                            self.isToneLoading = full.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
                            
                            let fullText = await self.getFullText()
                            await MainActor.run {
                                
                                self.documentText = fullText
                                Logger.debugFullText("self.documentText=\(self.documentText.count) (from getFullText)=\(self.documentText)")
                                self.isCapturingFullText = false
                                
                                self.updateDocumentText(myDocumentText: self.documentText)
                            }
                            return fullText
                        }
                        }
                        self.refreshKeyboardView()
                    },
                     onPredictionTap: { selected in
                         self.applyPrediction(word: selected)
                     },
                     favoriteTones: self.favoriteTones,
                     currentLocale: self.state.keyboardContext.locale,
                     isDarkMode: controller.traitCollection.userInterfaceStyle == .dark
                 )
                keyboardView(controller: controller)
            }
        }
        .background(AppColors.Background.keyboard(isDarkMode: controller.traitCollection.userInterfaceStyle == .dark))
        .overlay(alignment: .leading) {
            if self.showSignInTooltip {
                SignInTooltipView(
                    isDarkMode: controller.traitCollection.userInterfaceStyle == .dark,
                    onDismiss: {
                        self.showSignInTooltip = false
                        self.refreshKeyboardView()
                    },
                    onSignInTap: {
                        // Open the main app using URL scheme
                        Utils.openMainAppForSignIn(from: self)
                        // Dismiss tooltip after opening app
                        self.showSignInTooltip = false
                        self.refreshKeyboardView()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: self.showSignInTooltip)
    }
    
    func refreshKeyboardView() {
        Logger.debug("refreshKeyboardView")
        // No-op: UI updates are handled by SwiftUI state changes
    }

    @objc private func keyboardWillResignActive() {
        // Cancel any pending prediction work to avoid use-after-free
        getSuggestionsWorkItem?.cancel()
        // Cancel any pending background grammar check
        backgroundGrammarWorkItem?.cancel()
    }

    private func writeTimestamp() {
        let timestamp = Date().timeIntervalSince1970
        if let sharedDefaults = UserDefaults(suiteName: "group.com.dorna.app") {
            sharedDefaults.set(timestamp, forKey: "keyboardLastTimestamp")
            sharedDefaults.synchronize()
        }
    }
    
    private func loadFavoriteTones() {
        let favorites = appGroupManager.getFavoriteTones()
        DispatchQueue.main.async {
            self.favoriteTones = favorites
        }
    }
    
    // MARK: - Background Grammar Check
    
    private func triggerBackgroundGrammarCheck() {
        // Cancel any pending background check
        backgroundGrammarWorkItem?.cancel()

        // Don't check if in a special mode or if text is too short
        guard selectedToolbarItem == nil else { return }
        
        let trimmedText = currentFullText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.count >= 4 else {
            // Reset to idle if text is too short
            if case .idle = backgroundGrammarState {
                // Already idle, do nothing
            } else {
                DispatchQueue.main.async {
                    self.backgroundGrammarState = .idle
                }
            }
            return
        }
        
        // Check if user is logged in
        let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
        guard isLoggedIn else {
            DispatchQueue.main.async {
                self.backgroundGrammarState = .idle
            }
            return
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task {
                await self.performBackgroundGrammarCheck()
            }
        }
        
        backgroundGrammarWorkItem = workItem
        // Debounce for 2 seconds after user stops typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    private func performBackgroundGrammarCheck() async {

        let textToCheck = currentFullText
        self.isBackgroundGrammarLoading = true

        do {
            let response = try await grammarAPIService.checkGrammar(content: textToCheck, onAPICall: nil)
            self.hasGrammarSuggestionFromFullText = false

            await MainActor.run {
                handleGrammarResponse(response: response)
            }
            } catch {
            // On error, reset to idle state (don't show error in background mode)
//            await MainActor.run {
//                self.backgroundGrammarState = .idle
//                self.backgroundGrammarCorrections = []
//            }
            Logger.debug("Background grammar check failed: \(error.localizedDescription)")
        }

        self.isBackgroundGrammarLoading = false
    }
    
    private func callGrammarAPI() async {
        self.getFullTextTask?.cancel()
        self.replaceFullTextTask?.cancel()
        self.backgroundGrammarWorkItem?.cancel()

        // Reset error states before calling API
        await MainActor.run {
            self.grammarErrorMessage = ""
            self.grammarNoSuggestion = false
        }
        let textToCheck = documentText

        do {
            let response = try await grammarAPIService.checkGrammar(content: documentText, onAPICall: { [weak self] in
                Task { @MainActor in
                    self?.isGrammarLoading = true
                    self?.refreshKeyboardView()
                }
            })
            
            await MainActor.run {
                self.isGrammarLoading = false
                self.isGrammarApplyLoading = false
                self.displayText = self.documentText
                self.isCapturedFullTextForGrammar = true

                handleGrammarResponse(response: response)

                self.hasGrammarSuggestionFromFullText = !self.currentGrammarCorrections.isEmpty

            }
        } catch {
            await MainActor.run {
                // Convert all errors to APIError for consistent handling
                let apiError = BaseAPIService.convertErrorToAPIError(error)
                Logger.debug("Grammar API error type: \(type(of: error))")

                let typeName = String(describing: type(of: error))
                if typeName == "CancellationError" || apiError.localizedDescription.contains("cancelled") {
                    return
                }
                self.isGrammarLoading = false
                self.isGrammarApplyLoading = false
                self.displayText = self.documentText
                self.showGrammarSuggestion = false
                self.grammarWordOutputs = []
                self.grammarSuggestionsList = []
                self.backgroundGrammarState = .idle
                self.backgroundGrammarCorrections = []


                // Set error message based on APIError type
                self.grammarErrorMessage = BaseAPIService.getErrorMessageString(for: error)
                
                self.refreshKeyboardView()
                
                // Log error for debugging
                Logger.debug("Grammar API error: \(apiError.localizedDescription)")
            }
        }
    }

    func handleGrammarResponse(response: GrammarAPIResponse){
                // Filter only corrections where changed is true
                let validCorrections = response.corrections.filter { 
                    $0.changed && ($0.suggestion.contains("<correct>") || $0.suggestion.contains("<wrong>") || $0.suggestion.contains("<spell>"))
                }
                self.currentGrammarCorrections = validCorrections

                if validCorrections.count == 1 {
                    // Single suggestion - if same as input, mark no suggestion
                    let suggestion = validCorrections[0].suggestion
                    if self.grammarAPIService.isSuggestionSameAsInput(suggestion, input: self.documentText) {
                        self.grammarWordOutputs = []
                        self.grammarSuggestionsList = []
                        self.showGrammarSuggestion = false
                        self.grammarNoSuggestion = true
                    } else {
                        self.grammarWordOutputs = self.grammarAPIService.parseSuggestionToWordOutputs(suggestion)
                        self.grammarSuggestionsList = []
                        self.showGrammarSuggestion = true
                        self.grammarNoSuggestion = false
                    }
                } else if validCorrections.count > 1 {
                    // Multiple suggestions - filter out ones that equal input
                    let filtered = validCorrections.filter { !self.grammarAPIService.isSuggestionSameAsInput($0.suggestion, input: self.documentText) }
                    if filtered.isEmpty {
                        self.grammarWordOutputs = []
                        self.grammarSuggestionsList = []
                        self.showGrammarSuggestion = false
                        self.grammarNoSuggestion = true
                    } else {
                        self.currentGrammarCorrections = filtered
                        self.grammarSuggestionsList = filtered.map { correction in
                            self.grammarAPIService.parseSuggestionToWordOutputs(correction.suggestion)
                        }
                        self.grammarWordOutputs = []
                        self.showGrammarSuggestion = true
                        self.grammarNoSuggestion = false
                    }
                } else {
                    // No corrections found
                    self.grammarWordOutputs = []
                    self.grammarSuggestionsList = []
                    self.showGrammarSuggestion = false
                    self.grammarNoSuggestion = true
                }

                self.updateBackgroundGrammareState()

                self.refreshKeyboardView()

    }

   private func updateBackgroundGrammareState(){
                let totalCorrections: Int
                if self.grammarSuggestionsList.isEmpty {
                   let filtered = self.grammarWordOutputs.filter { $0.state == .corrected || $0.state == .spell }
                   totalCorrections = filtered.count
                } else{
                    let flattened = self.grammarSuggestionsList.flatMap { $0 }
                    let filtered = flattened.filter { $0.state == .corrected || $0.state == .spell }
                    totalCorrections = filtered.count
                }

                // Further filter out corrections that are same as input
                let meaningfulCorrections = self.currentGrammarCorrections

                self.backgroundGrammarCorrections = meaningfulCorrections

                if meaningfulCorrections.isEmpty {
                    self.backgroundGrammarState = .noErrors
                } else {
                    if totalCorrections > 0 {
                        self.backgroundGrammarState = .hasErrors(totalCorrections)
                    } else {
                        self.backgroundGrammarState = .idle
                    }

                }

   }
    
    private func callToneAPI() async {
        self.getFullTextTask?.cancel()
        self.deleteFullTextTask?.cancel()

        // Track that this is a normal tone API call
        self.lastToneAPICallType = .normal
        let selectedText = self.textDocumentProxy.selectedText ?? ""
        var currentText = self.currentFullText
        if(!self.currentFullSelectedText.isEmpty){
            currentText = self.currentFullSelectedText
        }
        if(!selectedText.isEmpty){
            currentText = selectedText
        }
        if(currentText.isEmpty || self.documentText.isEmpty){
           await MainActor.run {
               self.isToneLoading = false
               self.isToneApplyLoading = false
               self.displayText = currentText
               self.toneNoSuggestion = true
               self.showToneSuggestion = false
               self.toneAdjustedText = ""
               self.refreshKeyboardView()
           }
           return
        }



        // Early exit: if current text equals last applied tone for the same tone type within 5 minutes, skip API
        if let last = appGroupManager.loadLastAppliedTone() {
            let sameText = last.text.trimmingCharacters(in: .whitespacesAndNewlines) == currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            let sameTone = (last.toneType?.lowercased() ?? "") == selectedTone.lowercased()
            let age = Date().timeIntervalSince1970 - last.timestamp
            if sameText && sameTone && age <= 300 {
                await MainActor.run {
                    self.isToneLoading = false
                    self.isToneApplyLoading = false
                    self.displayText = currentText
                    self.toneNoSuggestion = true
                    self.showToneSuggestion = false
                    self.toneAdjustedText = ""
                    self.refreshKeyboardView()
                }
                return
            }
        }
        do {
            self.currentToneOriginalText = currentText
            let response = try await toneAPIService.adjustTone(content: currentText, targetTone: selectedTone.lowercased())
            
            await MainActor.run {
                self.isToneLoading = false
                self.isToneApplyLoading = false
                self.displayText = currentText
                
                // Check if there's a meaningful suggestion (not empty or same as original)
                if response.adjusted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                   response.adjusted.trimmingCharacters(in: .whitespacesAndNewlines) == currentText.trimmingCharacters(in: .whitespacesAndNewlines) {
                    self.toneNoSuggestion = true
                    self.showToneSuggestion = false
                    self.toneAdjustedText = ""
                } else {
                    self.toneNoSuggestion = false
                    self.showToneSuggestion = true
                    self.toneAdjustedText = response.adjusted
                    self.currentToneQueryId = response.queryId
                }
                
                self.refreshKeyboardView()
            }
        } catch {
            await MainActor.run {
                self.isToneLoading = false
                self.isToneApplyLoading = false
                self.displayText = currentText
                self.showToneSuggestion = false
                self.toneAdjustedText = ""
                
                // Convert all errors to APIError for consistent handling
                let apiError = BaseAPIService.convertErrorToAPIError(error)
                
                // Set error message based on APIError type
                self.toneErrorMessage = BaseAPIService.getErrorMessageString(for: error)
                
                self.refreshKeyboardView()
                
                // Log error for debugging
                Logger.debug("Tone API error: \(apiError.localizedDescription)")
            }
        }
    }
    
    private func callToneAPIWithDebounce() {
        // Cancel previous debounce work item if still pending
        toneAPIDebounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // Only call API if text is not empty and has at least 4 characters
            let trimmedText = self.documentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedText.isEmpty && trimmedText.count >= 4 && self.selectedToolbarItem == .tone {
                Task {
                    await self.callToneAPI()
                }
            } else {
                self.isToneLoading = false
                self.isToneApplyLoading = false
                self.refreshKeyboardView()
            }
        }
        
        toneAPIDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    private func rephraseTone() async {
        self.getFullTextTask?.cancel()
        self.deleteFullTextTask?.cancel()
        if(self.currentToneOriginalText.isEmpty){
            await MainActor.run {
                self.isToneLoading = false
                self.isToneApplyLoading = false
                self.displayText = ""
                self.toneNoSuggestion = true
                self.showToneSuggestion = false
                self.toneAdjustedText = ""
                self.refreshKeyboardView()
            }
            return
        }

        // Track that this is a rephrase tone API call
        self.lastToneAPICallType = .rephrase
        self.isToneLoading = true
        self.refreshKeyboardView()
        
        do {
            let response = try await toneAPIService.adjustTone(
                content: self.currentToneOriginalText,
                targetTone: self.selectedTone.lowercased(),
                parentToneId: self.currentToneQueryId
            )
            await MainActor.run {
                self.isToneLoading = false
                self.isToneApplyLoading = false
                self.displayText = self.currentToneOriginalText
                if response.adjusted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    response.adjusted.trimmingCharacters(in: .whitespacesAndNewlines) == self.currentToneOriginalText.trimmingCharacters(in: .whitespacesAndNewlines) {
                    self.toneNoSuggestion = true
                    self.showToneSuggestion = false
                    self.toneAdjustedText = ""
                } else {
                    self.toneNoSuggestion = false
                    self.showToneSuggestion = true
                    self.toneAdjustedText = response.adjusted
                    self.currentToneQueryId = response.queryId
                }
                self.refreshKeyboardView()
            }
        } catch {
            await MainActor.run {
                self.isToneLoading = false
                self.isToneApplyLoading = false
                self.displayText = self.currentToneOriginalText
                self.showToneSuggestion = false
                self.toneAdjustedText = ""
                
                // Convert all errors to APIError for consistent handling
                let apiError = BaseAPIService.convertErrorToAPIError(error)
                
                // Set error message based on APIError type
                self.toneErrorMessage = BaseAPIService.getErrorMessageString(for: error)
                
                self.refreshKeyboardView()
                Logger.debug("Tone API rephrase error: \(apiError.localizedDescription)")
            }
        }
    }

    private func applyGrammarCorrection(at index: Int) async {

        if grammarSuggestionsList.isEmpty {
            // Single suggestion case: apply the single correction globally
            guard let correction = currentGrammarCorrections.first else { 
                return
            }
            
            // Track the approval
            if let correctionId = correction.correctionId {
                trackerAPIService.trackGrammarAction(correctionId: correctionId, action: .approved)
            }
            
            _ = await applyGrammarCorrections([correction])
            
            // Reset the grammar view for single suggestion
            self.showGrammarSuggestion = false
            self.grammarWordOutputs = []
            self.grammarSuggestionsList = []
            self.grammarErrorMessage = ""
            self.grammarNoSuggestion = true
            self.isGrammarLoading = false
            self.selectedToolbarItem = nil
            
            // Reset background grammar after applying
            self.backgroundGrammarState = .noErrors
            self.backgroundGrammarCorrections = []
        } else {
            // Multiple suggestions case - apply specific correction globally
            guard index < currentGrammarCorrections.count else { 
                return
            }
            let correction = currentGrammarCorrections[index]
            
            // Track the approval
            if let correctionId = correction.correctionId {
                trackerAPIService.trackGrammarAction(correctionId: correctionId, action: .approved)
            }
            
            let appliedText = await applyGrammarCorrections([correction])
            
            // Remove the applied suggestion from the list and corrections
            grammarSuggestionsList.remove(at: index)
            currentGrammarCorrections.remove(at: index)
            
            // If no more suggestions, hide the grammar view
            if grammarSuggestionsList.isEmpty {
                self.showGrammarSuggestion = false
                self.grammarWordOutputs = []
                self.grammarSuggestionsList = []
                self.grammarErrorMessage = ""
                self.grammarNoSuggestion = true
                self.isGrammarLoading = false
                self.selectedToolbarItem = nil
                
                // Reset background grammar after applying all
                self.backgroundGrammarState = .noErrors
                self.backgroundGrammarCorrections = []
            } else {
                // Cache remaining suggestions for the current text so reopening grammar shows them
                let contentToCache = appliedText ?? self.composeCurrentFullText()
                self.cacheRemainingGrammarSuggestions(for: contentToCache)
                self.updateBackgroundGrammareState()
            }
        }

        self.refreshKeyboardView()
    }
    
    private func applyGrammarCorrections(_ correctionsToApply: [GrammarCorrection]) async -> String? {
        self.isGrammarApplyLoading = true
        self.refreshKeyboardView()

        // Get the current document text
        let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
        let afterText = textDocumentProxy.documentContextAfterInput ?? ""
        let fullText = beforeText + afterText
        
        var correctedText = fullText
        var notFoundReplacements = [GrammarCorrection]()

//        // First, try to apply corrections to the current document text
       for correction in correctionsToApply {
           let cleanedSuggestion = grammarAPIService.cleanedSuggestionText(from: correction.suggestion)
           if !correction.original.isEmpty {
               if let range = correctedText.range(of: correction.original) {
                   correctedText = correctedText.replacingCharacters(in: range, with: cleanedSuggestion)
                if correctedText != fullText {
                Logger.debug("fullText=\(fullText) correction.original=\(correction.original)")
                    replaceEntireDocumentText(with: correctedText, originalText: fullText)
                    self.appGroupManager.saveLastAppliedGrammar(text: correctedText)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.updateDocumentText()
                    }
                }
              
               } else {
                   notFoundReplacements.append(correction)
               }
           }
       }
       Logger.debug("notFoundReplacements: \(notFoundReplacements.count)")
        // If not found replacements in not empty, use getFullTextWithReplacements
        if !notFoundReplacements.isEmpty {
            let replacementPairs = notFoundReplacements.compactMap { correction -> (String, String)? in
                let cleanedSuggestion = grammarAPIService.cleanedSuggestionText(from: correction.suggestion)
                return correction.original.isEmpty ? nil : (correction.original, cleanedSuggestion)
            }

            if !replacementPairs.isEmpty {
                    self.isGrammarApplyLoading = true
                    self.refreshKeyboardView()

                    await replaceOnFullText(replacements: [replacementPairs.first!])
                    // Remove the first pair after replacement
                    notFoundReplacements.removeFirst()
                    // Recursively apply remaining corrections
                    if !notFoundReplacements.isEmpty {
                       await applyGrammarCorrections(notFoundReplacements)
                    } else {
                        await moveCursorToEnd()
                        self.isGrammarApplyLoading = false
                        self.refreshKeyboardView()
                    }


                return nil // Return nil since the replacement is handled asynchronously
            } else {
                await moveCursorToEnd()
                self.isGrammarApplyLoading = false
                self.refreshKeyboardView()
            }
        } else {
            await moveCursorToEnd()
            self.isGrammarApplyLoading = false
            self.refreshKeyboardView()
        }
        return nil
    }
    
    private func removeGrammarSuggestion(at index: Int) {
        if grammarSuggestionsList.isEmpty {
            // Single suggestion case - just hide the view
            guard let correction = currentGrammarCorrections.first else { return }
            
            // Track the rejection
            if let correctionId = correction.correctionId {
                trackerAPIService.trackGrammarAction(correctionId: correctionId, action: .rejected)
            }
            
            self.showGrammarSuggestion = false
            self.grammarWordOutputs = []
            self.grammarSuggestionsList = []
            self.grammarErrorMessage = ""
            self.grammarNoSuggestion = false
            self.isGrammarLoading = false
            self.isGrammarApplyLoading = false
            self.selectedToolbarItem = nil
            
            // Reset background grammar when dismissing
            self.backgroundGrammarState = .idle
            self.backgroundGrammarCorrections = []
        } else {
            // Multiple suggestions case - remove specific suggestion
            guard index < grammarSuggestionsList.count else { return }
            
            // Track the rejection before removing
            if index < currentGrammarCorrections.count {
                let correction = currentGrammarCorrections[index]
                if let correctionId = correction.correctionId {
                    trackerAPIService.trackGrammarAction(correctionId: correctionId, action: .rejected)
                }
                currentGrammarCorrections.remove(at: index)
            }
            grammarSuggestionsList.remove(at: index)
            
            // If no more suggestions, hide the grammar view
            if grammarSuggestionsList.isEmpty {
                self.showGrammarSuggestion = false
                self.grammarWordOutputs = []
                self.grammarSuggestionsList = []
                self.grammarErrorMessage = ""
                self.grammarNoSuggestion = false
                self.isGrammarLoading = false
                self.isGrammarApplyLoading = false
                self.selectedToolbarItem = nil
                
                // Reset background grammar when dismissing all
                self.backgroundGrammarState = .idle
                self.backgroundGrammarCorrections = []
            } else {
                // Cache remaining suggestions for the current text
                let contentToCache = self.composeCurrentFullText()
                self.cacheRemainingGrammarSuggestions(for: contentToCache)
                self.updateBackgroundGrammareState()
            }
        }

        //if user remove a suggestion we must get full text again
        if self.hasGrammarSuggestionFromFullText {
            self.isCapturedFullTextForGrammar = false
        }
        
        self.refreshKeyboardView()
    }
    
    private func applyAllGrammarCorrections() async {
        // Track all corrections as approved before applying
        for correction in currentGrammarCorrections {
            if let correctionId = correction.correctionId {
                trackerAPIService.trackGrammarAction(correctionId: correctionId, action: .approved)
            }
        }
        
        // Apply all grammar corrections: replace each original with its cleaned suggestion across the whole text
        _ = await applyGrammarCorrections(currentGrammarCorrections)
        self.grammarSuggestionsList = []
        self.grammarWordOutputs = []
        self.grammarErrorMessage = ""
        self.grammarNoSuggestion = true
        self.isGrammarLoading = false
//        self.displayText = ""
        
        // Reset background grammar after applying all
        self.backgroundGrammarState = .noErrors
        self.backgroundGrammarCorrections = []

        self.refreshKeyboardView()
    }

    // Compose current full document text from before/after input
    private func composeCurrentFullText() -> String {
        let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
        let afterText = textDocumentProxy.documentContextAfterInput ?? ""
        return beforeText + afterText
    }

    // Cache remaining grammar suggestions for a given content
    private func cacheRemainingGrammarSuggestions(for content: String) {
        guard !currentGrammarCorrections.isEmpty else { return }
        let response = GrammarAPIResponse(status: "ok", task: "grammar", queryId: "remaining-local", corrections: currentGrammarCorrections)
        appGroupManager.saveGrammarCache(for: content, response: response)
    }
    
    private func applyToneCorrection() async{
        isToneApplyLoading = true
        self.refreshKeyboardView()

        // Track the tone approval before applying
        if let toneId = currentToneQueryId {
            trackerAPIService.trackToneAction(toneId: toneId, action: .approved)
        }

        // Get the current document text
        let beforeText = textDocumentProxy.documentContextBeforeInput ?? ""
        let afterText = textDocumentProxy.documentContextAfterInput ?? ""
        var isFullTextReplaced = self.currentFullSelectedText == self.currentFullText || self.currentFullSelectedText.isEmpty

        // Need to find the text in the full document
        let fullText = self.currentFullText

        // Find range of self.currentToneOriginalText in fullText
        if let range = fullText.range(of: self.currentToneOriginalText) {
            // Calculate distance from end of fullText to end of match
            let distanceFromEnd = fullText.distance(from: range.upperBound, to: fullText.endIndex)

            // Move cursor to end of document
            await moveCursorToEnd()

            // Move backward to the end of the match
            if distanceFromEnd > 0 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: -distanceFromEnd)
            }

            // Delete the original text backward
            for _ in 0..<self.currentToneOriginalText.count {
                textDocumentProxy.deleteBackward()
            }

            // Insert new text
            textDocumentProxy.insertText(toneAdjustedText)

            // Update mirror engine
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
               // Since we know exactly what we did (full text - range + new text), we could optimize
               // But syncing from a fresh state is safer
                self.mirrorEngine?.performImmediateSync()
                self.updateCurrentFullTextFromMirror()
            }

             } else {
                 Logger.debug("applyToneCorrection: Target text not found in full text, falling back to replaceEntireDocumentText")
                 // Fallback: This will wipe everything, but it's better than doing nothing if search failed
                 replaceEntireDocumentText(with: toneAdjustedText, originalText: self.currentToneOriginalText)
             }
        if isFullTextReplaced{
           self.isCapturedFullTextForGrammar = true
           self.grammarNoSuggestion = true
           self.backgroundGrammarState = .noErrors
           self.backgroundGrammarCorrections = []

        } else{
          self.grammarNoSuggestion = false
          // Reset background grammar after applying
          self.backgroundGrammarState = .idle
          self.backgroundGrammarCorrections = []
          triggerBackgroundGrammarCheck()
        }

        
//        // Track last applied tone with tone type
//        self.appGroupManager.saveLastAppliedTone(text: toneAdjustedText, toneType: selectedTone.lowercased())
        
        // Update document text after applying tone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateDocumentText()
        }
        
        // Reset tone view
        self.showToneSuggestion = false
        self.toneAdjustedText = ""
        self.toneErrorMessage = ""
        self.toneNoSuggestion = false
        self.isToneLoading = false
        self.isToneApplyLoading = false
        self.selectedToolbarItem = nil
        self.refreshKeyboardView()
    }

    private func replaceEntireDocumentText(with newText: String, originalText: String = "",isForTranslate: Bool = false) -> Int {
    Logger.debug("replaceEntireDocumentText originalText=\(originalText) newText=\(newText) ")
        //reset to getting full text if user apply changes on his text
        self.isCapturedFullTextForGrammar = false
        self.hasGrammarSuggestionFromFullText = false

        if !originalText.isEmpty && isForTranslate{
                    for _ in 0..<originalText.count {
                        textDocumentProxy.deleteBackward()
                    }
                    textDocumentProxy.insertText(newText)

                    // Update mirror engine after text replacement
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.updateMirrorAfterTextReplacement(newText: newText)
                    }
                    return 0

                }

        // 1. Try selected text matches originalText
        if let selected = textDocumentProxy.selectedText, selected == originalText {
            textDocumentProxy.insertText(newText)
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 self.updateMirrorAfterTextReplacement(newText: newText)
             }
            return 0
        }
        
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        
        if !originalText.isEmpty {
             let combined = before + after
             // Find all occurrences
             var searchStartIndex = combined.startIndex
             var bestRange: Range<String.Index>?
             var minDistance = Int.max
             let cursorIdx = combined.index(combined.startIndex, offsetBy: before.count)
             var safety = 0
             
             while let range = combined.range(of: originalText, range: searchStartIndex..<combined.endIndex) {
                 // Check if range overlaps or touches cursor
                 if range.lowerBound <= cursorIdx && cursorIdx <= range.upperBound {
                     bestRange = range
                     minDistance = 0
                     break
                 }
                 
                 let startDist = abs(combined.distance(from: range.lowerBound, to: cursorIdx))
                 let endDist = abs(combined.distance(from: range.upperBound, to: cursorIdx))
                 let dist = min(startDist, endDist)
                 
                 if dist < minDistance {
                     minDistance = dist
                     bestRange = range
                 }
                 safety = safety + 1
                 if range.upperBound < combined.endIndex {
                    // Advance by 1 to find overlapping matches
                    searchStartIndex = combined.index(range.lowerBound, offsetBy: 1) 
                 } else {
                     break
                 }
                 //break infinite loop
                 if safety > 300 {
                    break
                 }
             }
             
             if let range = bestRange {
                 // Found match. Move cursor to range.upperBound
                 let matchEndIndex = range.upperBound
                 let distance = combined.distance(from: cursorIdx, to: matchEndIndex)
                 
                 if distance != 0 {
                     textDocumentProxy.adjustTextPosition(byCharacterOffset: distance)
                 }
                 
                 for _ in 0..<originalText.count {
                     textDocumentProxy.deleteBackward()
                 }
                 
                 textDocumentProxy.insertText(newText)
                 
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateMirrorAfterTextReplacement(newText: newText)
                 }
                 return 0
             }
        }

        // Fallback: if originalText is empty, replace everything (legacy behavior)
        if originalText.isEmpty {
            let beforeCount = textDocumentProxy.documentContextBeforeInput?.count ?? 0
            let afterCount = textDocumentProxy.documentContextAfterInput?.count ?? 0
            // Move cursor to the end of the current context to make all deletions consistent
            if afterCount > 0 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: afterCount)
            }
            // Delete the entire content
            let totalCount = beforeCount + afterCount
            if totalCount > 0 {
                for _ in 0..<totalCount {
                    textDocumentProxy.deleteBackward()
                }
            }
            // Insert replacement
            textDocumentProxy.insertText(newText)

            // Update mirror engine after text replacement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateMirrorAfterTextReplacement(newText: newText)
            }
            return 0
        }
        
        // Fallback to original behavior if originalText not provided or empty
        let beforeCount = textDocumentProxy.documentContextBeforeInput?.count ?? 0
        let afterCount = textDocumentProxy.documentContextAfterInput?.count ?? 0
        // Move cursor to the end of the current context to make all deletions consistent
        if afterCount > 0 {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: afterCount)
        }
        // Delete the entire content (both before and after relative to original caret)
        let totalCount = beforeCount + afterCount
        if totalCount > 0 {
            for _ in 0..<totalCount {
                textDocumentProxy.deleteBackward()
            }
        }
        // Insert replacement
        textDocumentProxy.insertText(newText)

        // Update mirror engine after text replacement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateMirrorAfterTextReplacement(newText: newText)
        }
        return 0
    }
    
    // Add this new method after the existing methods
    private func updateTranslationUI() {
        // Only update translation-related UI components without rebuilding the entire keyboard
        // This method will be called when translation type changes
        DispatchQueue.main.async {
            // Update keyboard context for translation mode if needed
            if self.selectedToolbarItem == .translate {
                // Switch keyboard language (locale) to match translation type
                if self.selectedTranslation == TranslationType.persian.rawValue {
                    self.state.keyboardContext.locale = .persian
                } else {
                    self.state.keyboardContext.locale = .english
                }
                let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                if !isLoggedIn {
                    self.translationErrorMessage = "signInRequired"
                    self.refreshKeyboardView()
                    return
                }

                self.state.keyboardContext.returnKeyTypeOverride = .return
                
                // Update callout service for the new locale
                self.updateCalloutServiceForCurrentLocale()
                
                self.onClearTranslationTap()
            }
            
            // Clear translation input when language changes
            self.translationInputText = ""
            self.translationCursorPosition = 0
            
            // Reset translation states when translation type changes
            self.showTranslationSuggestion = false
            self.translatedText = ""
            self.translationErrorMessage = ""
            self.translationNoSuggestion = false
            self.isTranslationLoading = false
            
            // Clear temporary translation when language changes
            self.clearTemporaryTranslation()
        }
    }
    
    // Handle translation results from TranslationView
    private func handleTranslationResult(_ translatedText: String) {
        // If there's already a temporary translation, replace it
        if !temporaryTranslatedText.isEmpty {
            replaceTemporaryTranslation(translatedText)
        } else {
            // Insert the translated text temporarily for the first time
            insertTemporaryTranslation(translatedText)
        }
        
        // Show apply button
        showTranslationApplyButton = true
        
        // Update keyboard context to show apply button instead of done
        state.keyboardContext.returnKeyTypeOverride = .custom(title: "applyTranslation")
            }
    
    // Insert temporary translation text
    private func insertTemporaryTranslation(_ text: String) {
        // Store the previously inserted quoted translation before updating
        if !temporaryTranslatedText.isEmpty {
            previousTranslatedText = (selectedTranslation == TranslationType.english.rawValue ? "\u{202B}\"" : "\"") + temporaryTranslatedText + "\""
        }
        
        // Save unquoted in state, but insert quoted into the document
        temporaryTranslatedText = text
        textDocumentProxy.insertText((selectedTranslation == TranslationType.english.rawValue ? "\u{202B}\"" : "\"") + text + "\"")
    }
    
    // Replace existing temporary translation with new one
    private func replaceTemporaryTranslation(_ newText: String) {
        // Store the previously inserted quoted translation before updating
        if !temporaryTranslatedText.isEmpty {
            previousTranslatedText = (selectedTranslation == TranslationType.english.rawValue ? "\u{202B}\"" : "\"") + temporaryTranslatedText + "\""
        }
        
        // Update the temporary translation text (unquoted in state)
        temporaryTranslatedText = newText
        
        // Replace the quoted text in the document with new quoted text
        let newQuotedText = (selectedTranslation == TranslationType.english.rawValue ? "\u{202B}\"" : "\"") + newText + "\""
        replaceEntireDocumentText(with: newQuotedText, originalText: previousTranslatedText, isForTranslate: true)
    }
    
    // Clear temporary translation and restore original text
    private func clearTemporaryTranslation() {
        if !temporaryTranslatedText.isEmpty {
            // Delete the previously inserted quoted translation from the document
            let originalQuotedText = (selectedTranslation == TranslationType.english.rawValue ? "\u{202B}\"" : "\"") + temporaryTranslatedText + "\""
            replaceEntireDocumentText(with: "", originalText: originalQuotedText, isForTranslate: true)
            temporaryTranslatedText = ""
            previousTranslatedText = ""
            translationErrorMessage = ""
            showTranslationApplyButton = false
            
            // Reset keyboard context
            state.keyboardContext.returnKeyTypeOverride = .return
                    }
    }
    
    // Apply the temporary translation permanently
    func applyTemporaryTranslation() {
        if !temporaryTranslatedText.isEmpty {
            // Clean the translated text by removing [] chars for wrong tags
            let cleanedText = Utils.cleanTranslatedText(temporaryTranslatedText)
            
            // Replace the quoted temporary translation with the unquoted final text
            let originalQuotedText = (selectedTranslation == TranslationType.english.rawValue ? "\u{202B}\"" : "\"") + temporaryTranslatedText + "\""
            replaceEntireDocumentText(with: cleanedText+" ", originalText: originalQuotedText, isForTranslate: true)

            // Clear the temporary state
            temporaryTranslatedText = ""
            showTranslationApplyButton = false

            // Clear translation input field
            translationInputText = ""
            translationCursorPosition = 0
            self.grammarNoSuggestion = false

            // Reset keyboard context
            state.keyboardContext.returnKeyTypeOverride = .return
                    }
    }
    

    // Cursor-aware text insertion for translation input
    // translationCursorPosition is an index from the beginning: 0 means start of text
     func insertTextAtCursor(_ text: String) {
        let currentText = translationInputText
        let length = currentText.count
        let pos = max(0, min(translationCursorPosition, length))
        let beforeCursor = String(currentText.prefix(pos))
        let afterCursor = String(currentText.suffix(length - pos))
        let newText = beforeCursor + text + afterCursor
        translationInputText = newText
        translationCursorPosition = pos + text.count

        if translationInputText.count < 4 {
        clearTemporaryTranslation()
        }
    }
    
    // Cursor-aware text deletion for translation input
    // Deletes the character immediately before the cursor (from beginning)
     func deleteTextAtCursor() {
        let currentText = translationInputText
        let length = currentText.count
        if length == 0 { return }
        let pos = max(0, min(translationCursorPosition, length))
        if pos == 0 { return }
        let deleteIndex = pos - 1
        let beforeDelete = String(currentText.prefix(deleteIndex))
        let afterDelete = String(currentText.suffix(length - pos))
        translationInputText = beforeDelete + afterDelete
        translationCursorPosition = pos - 1

         if translationInputText.count < 4 {
            clearTemporaryTranslation()
            if !self.translationErrorMessage.isEmpty {
                self.translationErrorMessage = ""
                self.refreshKeyboardView()
            }

         }

    }
   func onClearTranslationTap(){
        // Clear input and reset translation-related states
        translationInputText = ""
        translationCursorPosition = 0
        translationResetToken = UUID()
        showTranslationSuggestion = false
        translatedText = ""
        translationErrorMessage = ""
        translationNoSuggestion = false
        isTranslationLoading = false
        clearTemporaryTranslation() // Clear temporary translation when clearing

   }
    
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Stop periodic sync timer in mirror engine
        mirrorEngine?.stopPeriodicSync()
        mirrorEngine = nil
        // Cancel any pending work items
        updateDocumentTextWorkItem?.cancel()
        toneAPIDebounceWorkItem?.cancel()
        backgroundGrammarWorkItem?.cancel()
        // Cancel all running tasks to prevent memory leaks
        getFullTextTask?.cancel()
        deleteFullTextTask?.cancel()
        replaceFullTextTask?.cancel()
        // Cancel any pending suggestion loading work to avoid firing on deallocated controller
        getSuggestionsWorkItem?.cancel()
        // Invalidate the timestamp timer
        timestampTimer?.invalidate()
        // Clear engine references; caches will be reused
        suggestEngine = nil
        currentSuggestLanguageKey = nil
        // Ensure engines are released on controller deallocation (actor-safe)
        Task { await AutoSuggestProvider.shared.unload() }

    }
}

fileprivate struct RootKeyboardView: View {
    @ObservedObject var controller: KeyboardViewController
    @EnvironmentObject var context: KeyboardContext
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        controller.createKeyboardViewContent(controller: controller)
    }
}

import SwiftUI
import UIKit
import os
import KeyboardKit

// MARK: - Dynamic Text Styling
struct TextPatternStyle {
    let text: String
    let color: UIColor
    let font: UIFont?
    let backgroundColor: UIColor?
    let underlineStyle: NSUnderlineStyle?
    let strikethroughStyle: NSUnderlineStyle?
    
    init(text: String, 
         color: UIColor, 
         font: UIFont? = nil, 
         backgroundColor: UIColor? = nil,
         underlineStyle: NSUnderlineStyle? = nil,
         strikethroughStyle: NSUnderlineStyle? = nil) {
        self.text = text
        self.color = color
        self.font = font
        self.backgroundColor = backgroundColor
        self.underlineStyle = underlineStyle
        self.strikethroughStyle = strikethroughStyle
    }
}

enum TranslationType: String, CaseIterable {
    case english = "English"
    case persian = "Persian"
}
struct SpinningCircle: View {
    @State private var isAnimating = false
    let isDarkMode: Bool

    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.7) // arc instead of full circle
            .stroke(AppColors.Loading.spinner(isDarkMode: isDarkMode), lineWidth: 2)
            .frame(width: 18, height: 18)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// Reusable translation type tabs widget
struct TranslationSwitchView: View {
    @Binding var selectedTranslation: String

    var body: some View {
        let sourceLanguageLabel = selectedTranslation == TranslationType.english.rawValue ? "English" : "Persian"
        let targetLanguageLabel = selectedTranslation == TranslationType.english.rawValue ? "Persian" : "English"

        HStack(spacing: 8) {
            Text(sourceLanguageLabel)
                .font(Font.sfProDisplay(size: 17, weight: .regular))
                .foregroundColor(.primary)
                .frame(maxWidth: 55, alignment: .trailing)
                .scaledToFit()
                .padding(.trailing, 1)


            Button(action: {
                if selectedTranslation == TranslationType.english.rawValue {
                    selectedTranslation = TranslationType.persian.rawValue
                } else {
                    selectedTranslation = TranslationType.english.rawValue
                }
            }) {
                Group {
                    let bundle = Bundle(for: KeyboardViewController.self)
                    if let imagePath = bundle.path(forResource: "ic_switch", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 26, height: 26)
                    } else {
                        Image(systemName: "arrow.2.circlepath")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                    }
                }
                .padding(6)
            }

            Text(targetLanguageLabel)
                .font(Font.sfProDisplay(size: 17, weight: .regular))
                .foregroundColor(.primary)
                .frame(maxWidth: 55, alignment: .trailing)
                .scaledToFit()



        }
    }
}
class NoActionTextField: UITextField {
    var allowPaste: Bool = false
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Allow paste if explicitly enabled, otherwise disable all actions
        if allowPaste && action == #selector(paste(_:)) {
            return true
        }
        return false // disables Copy, Select, Select All, etc.
    }

            // Handle paste when allowed
    override func paste(_ sender: Any?) {
        if allowPaste {
            // Post notification for paste event before calling super
            if let pastedText = UIPasteboard.general.string {
                NotificationCenter.default.post(
                    name: NSNotification.Name("TextFieldDidPaste"),
                    object: self,
                    userInfo: ["pastedText": pastedText]
                )
            }
            super.paste(sender)
        }
        // Otherwise do nothing
    }

            // 2) Conditionally enable/disable long-press gesture based on paste allowance
    override func didMoveToWindow() {
        super.didMoveToWindow()
        gestureRecognizers?.forEach { gr in
            if gr is UILongPressGestureRecognizer { 
                gr.isEnabled = allowPaste 
            }
        }
    }

        // Optional: make sure system doesn’t try to present selection UI
        override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] { [] }
        override func caretRect(for position: UITextPosition) -> CGRect { super.caretRect(for: position) } // keep caret; or return .zero to hide

        // Make width flexible so SwiftUI frame can constrain it; height remains intrinsic
        override var intrinsicContentSize: CGSize {
            let base = super.intrinsicContentSize
            return CGSize(width: UIView.noIntrinsicMetric, height: base.height)
        }
}

// UIKit-backed field that doesn't summon the system keyboard and handles cursor properly
struct NonSystemTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isRTL: Bool
    @Binding var isFocused: Bool
    @Binding var cursorPosition: Int
    var allowPaste: Bool = false
    let isDarkMode: Bool
    var textPatternStyles: [TextPatternStyle] = [] // Dynamic styling configuration

    func makeUIView(context: Context) -> UITextField {
        let tf = NoActionTextField(frame: .zero)
        tf.allowPaste = allowPaste
        tf.borderStyle = .none
        tf.inputView = UIView() // prevent system keyboard
        tf.keyboardType = .alphabet
        tf.returnKeyType = .default
        tf.autocapitalizationType = .none
        // Ensure long text scrolls horizontally instead of shrinking
        tf.adjustsFontSizeToFitWidth = false
        tf.minimumFontSize = 1
        // Prefer obeying external width constraints and keep internal scroll
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.required, for: .horizontal)

        tf.textAlignment = isRTL ? .right : .left
        tf.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        tf.textColor = UIColor.from(AppColors.Text.primary(isDarkMode: isDarkMode))
        tf.font = FontManager.shared.sfProDisplay(size: 16, weight: .medium)

        // Set initial attributed text with dynamic styling
        tf.attributedText = createAttributedText(from: text, isDarkMode: isDarkMode, patternStyles: textPatternStyles)
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.from(AppColors.Text.placeholderLight(isDarkMode: isDarkMode)),
                .font: FontManager.shared.sfProDisplay(size: 16, weight: .medium),
                .obliqueness: 0.2
                    ]
                )

        tf.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        
        // Add target for cursor position tracking
        tf.addTarget(context.coordinator, action: #selector(Coordinator.cursorPositionChanged(_:)), for: .editingDidBegin)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.cursorPositionChanged(_:)), for: .editingChanged)
        
        // Track focus changes
        tf.addTarget(context.coordinator, action: #selector(Coordinator.didBeginEditing(_:)), for: .editingDidBegin)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.didEndEditing(_:)), for: .editingDidEnd)
        
        // Add notification observer for paste events when allowed
        if allowPaste {
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(Coordinator.handlePasteNotification(_:)),
                name: NSNotification.Name("TextFieldDidPaste"),
                object: tf
            )
        }
        
        // Ensure focus
        DispatchQueue.main.async {
            tf.becomeFirstResponder()
        }
        
        return tf
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update text if it actually changed and is different from current
        if uiView.text != text { 
            // Create attributed text with dynamic styling
            let attributedText = createAttributedText(from: text, isDarkMode: isDarkMode, patternStyles: textPatternStyles)
            uiView.attributedText = attributedText
            
            // Programmatic text change: set caret to bound cursorPosition
            if let newPosition = uiView.position(from: uiView.beginningOfDocument, offset: cursorPosition),
               let newRange = uiView.textRange(from: newPosition, to: newPosition) {
                uiView.selectedTextRange = newRange
            }
            // Ensure UIKit propagates change immediately
            uiView.sendActions(for: .editingChanged)
        } else {
            // No programmatic text change: reflect user caret movement back to binding
            if let selectedRange = uiView.selectedTextRange {
                let cursorPos = uiView.offset(from: uiView.beginningOfDocument, to: selectedRange.start)
                if cursorPos != cursorPosition {
                    cursorPosition = cursorPos
                }
            }
        }
        
        // Update placeholder when language changes
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }

        // Update text alignment and semantic content attribute when RTL changes
        uiView.textAlignment = isRTL ? .right : .left
        uiView.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        // Update attributed text with current styling
        uiView.attributedText = createAttributedText(from: text, isDarkMode: isDarkMode, patternStyles: textPatternStyles)
        
        // Update paste allowance
        if let noActionTextField = uiView as? NoActionTextField {
            noActionTextField.allowPaste = allowPaste
        }
        
        // Maintain focus according to binding
        if isFocused {
            if !uiView.isFirstResponder {
                DispatchQueue.main.async { uiView.becomeFirstResponder() }
            }
        } else {
            if uiView.isFirstResponder {
                DispatchQueue.main.async { uiView.resignFirstResponder() }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { 
        Coordinator(text: $text, cursorPosition: $cursorPosition, isFocused: $isFocused) 
    }
    
    // Helper function to create attributed text with dynamic styling
    private func createAttributedText(from text: String, isDarkMode: Bool, patternStyles: [TextPatternStyle]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let baseColor = UIColor.from(AppColors.Text.primary(isDarkMode: isDarkMode))
        let font = FontManager.shared.sfProDisplay(size: 16, weight: .medium)
        
        // Set base attributes for the entire text
        attributedString.addAttributes([
            .foregroundColor: baseColor,
            .font: font
        ], range: NSRange(location: 0, length: text.count))
        
        // Apply dynamic pattern styles
        for patternStyle in patternStyles {
            let searchText = patternStyle.text.lowercased()
            let textToSearch = text.lowercased()
            var searchRange = textToSearch.startIndex
            
            while searchRange < textToSearch.endIndex {
                if let range = textToSearch.range(of: searchText, range: searchRange..<textToSearch.endIndex) {
                    let nsRange = NSRange(range, in: text)
                    
                    // Apply all specified attributes
                    var attributes: [NSAttributedString.Key: Any] = [:]
                    
                    // Color
                    attributes[.foregroundColor] = patternStyle.color
                    
                    // Font (if specified)
                    if let customFont = patternStyle.font {
                        attributes[.font] = customFont
                    }
                    
                    // Background color (if specified)
                    if let backgroundColor = patternStyle.backgroundColor {
                        attributes[.backgroundColor] = backgroundColor
                    }
                    
                    // Underline style (if specified)
                    if let underlineStyle = patternStyle.underlineStyle {
                        attributes[.underlineStyle] = underlineStyle.rawValue
                    }
                    
                    // Strikethrough style (if specified)
                    if let strikethroughStyle = patternStyle.strikethroughStyle {
                        attributes[.strikethroughStyle] = strikethroughStyle.rawValue
                    }
                    
                    attributedString.addAttributes(attributes, range: nsRange)
                    searchRange = range.upperBound
                } else {
                    break
                }
            }
        }
        
        return attributedString
    }
    
    class Coordinator: NSObject {
        var text: Binding<String>
        var cursorPosition: Binding<Int>
        var isFocused: Binding<Bool>
        
        init(text: Binding<String>, cursorPosition: Binding<Int>, isFocused: Binding<Bool>) { 
            self.text = text
            self.cursorPosition = cursorPosition
            self.isFocused = isFocused
        }
        
        @objc func textChanged(_ sender: UITextField) { 
            text.wrappedValue = sender.text ?? "" 
        }
        
        @objc func cursorPositionChanged(_ sender: UITextField) {
            if let selectedRange = sender.selectedTextRange {
                let pos = sender.offset(from: sender.beginningOfDocument, to: selectedRange.start)
                cursorPosition.wrappedValue = pos
            }
        }

        @objc func didBeginEditing(_ sender: UITextField) {
            isFocused.wrappedValue = true
        }

        @objc func didEndEditing(_ sender: UITextField) {
            isFocused.wrappedValue = false
        }
        
        @objc func handlePasteNotification(_ notification: Notification) {
            if let pastedText = notification.userInfo?["pastedText"] as? String {
                // Insert pasted text at cursor position
                let currentText = text.wrappedValue
                let length = currentText.count
                let pos = max(0, min(cursorPosition.wrappedValue, length))
                let beforeCursor = String(currentText.prefix(pos))
                let afterCursor = String(currentText.suffix(length - pos))
                let newText = beforeCursor + pastedText + afterCursor
                text.wrappedValue = newText
                cursorPosition.wrappedValue = pos + pastedText.count
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

struct TranslationView: View {
    let resetToken: UUID
    let onBackTap: () -> Void
    let onClearTap: () -> Void
    let onTranslationReceived: (String, String) -> Void // New callback for translation results (translatedText, queryId)
    let onTranslationError: (String) -> Void // Callback to report errors to parent
    let onClearError: () -> Void // Callback to clear error state in parent
    let openMainApp: () -> Void // Callback to open app from error view

    let text: String
    @Binding var isLoading: Bool
    let translatedText: String
    let translationErrorMessage: String
    let translationNoSuggestion: Bool
    let backgroundColor: Color
    @Binding var selectedTranslation: String
    @Binding var inputBinding: String
    @Binding var cursorPosition: Int
    let isDarkMode: Bool
    @State private var cleanedInputValue: String = ""
    @State private var isCleanedInputSet: Bool = false
    @State private var textPatternStyles: [TextPatternStyle] = [] // Dynamic styling configuration
    @State private var inputText: String = ""
    @State private var adjustedTextHeight: CGFloat = 0
    @State private var scrollViewportHeight: CGFloat = 0
    @State private var isTextFieldFocused: Bool = true // Always keep focused for keyboard input
    @State private var localResetToken: UUID = UUID()
    @State private var typingDebounceWorkItem: DispatchWorkItem?
    @State private var overlayResetToken: UUID = UUID()
    @State private var translationAPIService = TranslationAPIService.shared
    @State private var showUntranslatedTip: Bool = false
    @State private var showSpellErrorTip: Bool = false

    var body: some View {
       let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()

        return VStack(spacing: 0) {
              // Show TipInfoView on top, outside the background
              if (showUntranslatedTip || showSpellErrorTip) && !inputBinding.isEmpty {
                   TranslationTipInfoView(isDarkMode: isDarkMode,
                   showUntranslatedTip: showUntranslatedTip,
                   showSpellErrorTip: showSpellErrorTip

                   )
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .background( isDarkMode ? backgroundColor : .white)
              }
            // Main translation content
            VStack(spacing: 0) {
                // Translation Toolbar - Bigger than normal with integrated content
                VStack(spacing: 0) {

                // Top row: Back button and Translate button (tabs aligned right)
                TopBar(
                    title: "Translate",
                    icon: "ic_translate",
                    iconSize: 24,
                    isDarkMode: isDarkMode,
                    onBackTap: onBackTap,
                    extraContent: {
                       // Translation tabs with switch - positioned on the right side
                       TranslationSwitchView(
                           selectedTranslation: $selectedTranslation
                       )

                    }
                 )
                 Spacer().frame(height: translationErrorMessage.isEmpty ? 4 : 5.8)

                
                // Text input field (editable via our custom keyboard)
                VStack(spacing: 8) {
                    let isPersian = selectedTranslation == TranslationType.persian.rawValue
                    NonSystemTextField(
                        text: $inputBinding,
                        placeholder: isPersian ? "برای ترجمه تایپ کنید" : "Type to translate",
                        isRTL: isPersian,
                        isFocused: $isTextFieldFocused,
                        cursorPosition: $cursorPosition,
                        allowPaste: true,
                        isDarkMode: isDarkMode,
                        textPatternStyles: textPatternStyles
                    )
                        .id(resetToken.uuidString + localResetToken.uuidString) // force lightweight rebuild when any token changes
                        // Constrain width; UITextField will scroll horizontally for long text
                        .frame(width: UIScreen.main.bounds.width - 94,height: 39.65)
                        .clipped()
                        .padding(.horizontal, 16)
                        .padding(isPersian ? .leading : .trailing, 30)
                        .background(AppColors.Background.input(isDarkMode: isDarkMode))
                        .cornerRadius(12)
                        // Clear icon overlay (shows only when there is text)
                        .overlay(alignment: isPersian ? .leading : .trailing) {
                            Group {
                                if isLoading {
                                    SpinningCircle(isDarkMode: isDarkMode)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                } else if !$inputBinding.wrappedValue.isEmpty {
                                    Button(action: {
                                        inputBinding = ""
                                        cursorPosition = 0
                                        showUntranslatedTip = false
                                        showSpellErrorTip = false
                                        textPatternStyles = []
                                        // trigger local rebuild immediately
                                        localResetToken = UUID()
                                        onClearTap()
                                    }) {
                                        Group {
                                            let bundle = Bundle(for: KeyboardViewController.self)
                                            if let imagePath = bundle.path(forResource: isDarkMode ? "ic_clear_dark" : "ic_clear", ofType: "png"),
                                               let uiImage = UIImage(contentsOfFile: imagePath) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .renderingMode(.template)
                                                    .scaledToFit()
                                                    .frame(width: 14, height: 14)
                                            } else {
                                                Image(systemName: "xmark.circle.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 18, height: 18)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .id(overlayResetToken.uuidString + (isLoading ? "|loading" : "|idle"))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    // Red border when there is a translation error
                                    !translationErrorMessage.isEmpty
                                        ? Color.red
                                        : (
                                            $inputBinding.wrappedValue.isEmpty
                                                ? AppColors.Border.input(isDarkMode: isDarkMode)
                                                : AppColors.Border.inputActive(isDarkMode: isDarkMode)
                                        ),
                                    lineWidth: 1
                                )
                        )
                        .onAppear {
                            // Ensure text field is focused when view appears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldFocused = true
                            }
                        }
                        .onChange(of: $inputBinding.wrappedValue) { newValue in
                            if isCleanedInputSet && inputBinding == cleanedInputValue {
                                isCleanedInputSet = false
                                return
                            }
                            textPatternStyles = []
                            // Cancel pending debounce
                            typingDebounceWorkItem?.cancel()
                            // Hide spinner during active typing
                            if isLoading { isLoading = false }
                            // Clear any previous error while user is typing
                            if !translationErrorMessage.isEmpty { onClearError() }
                            // Empty input: nothing to load
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else {
                                  showUntranslatedTip = false
                                  showSpellErrorTip = false
                                  return
                            }

                            let workItem = DispatchWorkItem {

                                // Call translation API if text is at least 4 characters
                                if trimmed.count >= 4 {
                                DispatchQueue.main.async {
                                    isLoading = true
                                    // Force a lightweight rebuild of overlay only
                                    overlayResetToken = UUID()
                                }

                                    Task {
                                        await callTranslationAPI(content: trimmed)
                                    }
                                }
                                                            }
                            typingDebounceWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
                        }
                        .onChange(of: selectedTranslation) { _ in

                            // Call translation API if there's text to translate
                            let trimmed = inputBinding.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && trimmed.count >= 4 {
                                // Ensure text field maintains focus when language changes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isTextFieldFocused = true
                                }
                            }
                        }
                        .onDisappear {
                            typingDebounceWorkItem?.cancel()
                            isLoading = false
                        }
                }
                .frame(width: UIScreen.main.bounds.width - 94,height: 39.65)
                .padding(.horizontal, 16)
                .offset(y: translationErrorMessage.isEmpty ? 12.4:10.4)
                .opacity(isLoggedIn ? 1 : 0)

                if !translationErrorMessage.isEmpty {
                 Spacer()
                 }

                // Error view under the translation input
                if !translationErrorMessage.isEmpty {
                    ErrorView(
                        errorType: inferErrorType(from: translationErrorMessage),
                        isDarkMode: isDarkMode,
                        onRetry: {
                            let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                            if(!isLoggedIn){
                                openMainApp()
                                return
                            }
                            if isLoading{
                                return
                            }

                            let trimmed = inputBinding.trimmingCharacters(in: .whitespacesAndNewlines)
                            isLoading = true
                            overlayResetToken = UUID()
                            typingDebounceWorkItem?.cancel()
                            Task { await callTranslationAPI(content: trimmed) }
                        }
                    )
                    .padding(.vertical, 4)
                    .cornerRadius(12)
                    .frame(width: UIScreen.main.bounds.width - 31, height: 190)
                    .background(AppColors.Background.card(isDarkMode: isDarkMode))
                    .cornerRadius(12)
                    .frame(width: UIScreen.main.bounds.width - 31, height: 224)
                    .cornerRadius(12)
                     .offset(y: 2)

                }
            }
            .background(backgroundColor)

            }
            .background(backgroundColor)
            .padding(.bottom, 7.2)

        }
    }
    
    // MARK: - Translation API Call
    private func callTranslationAPI(content: String) async {
        do {
            let targetLanguage = selectedTranslation == TranslationType.english.rawValue ? "fa" : "en"
            let response = try await translationAPIService.translateText(content: content, targetLanguage: targetLanguage)
            
            await MainActor.run {
                // Replace input field content with correct_input if available
                if let correctInput = response.correctInput {
                    // Clean the correct_input by removing HTML tags but keeping the content
                    let cleanedInput = cleanCorrectInput(correctInput)
                    inputBinding = cleanedInput
                    cleanedInputValue = cleanedInput
                    isCleanedInputSet = true
                    
                    // Parse styling from correct_input
                    textPatternStyles = parseTextPatternStyles(from: correctInput)
                } else {
                    // Fallback to parsing translated text for [] brackets
                    textPatternStyles = parseTranslatedTextPatternStyles(from: response.translated)
                }
                
                // Send translation result to parent view
                onTranslationReceived(response.translated, response.queryId)
                // Set loading to false after successful API call
                isLoading = false
                overlayResetToken = UUID()

            }
        } catch {
            await MainActor.run {
                Logger.debug("Translation API error: \(error.localizedDescription)")
                let apiError = BaseAPIService.convertErrorToAPIError(error)
                // Set loading to false after error
                isLoading = false
                overlayResetToken = UUID()

                switch apiError {
                case .http422(let queryId, _):
                    // Pass the original content and the error's query id
                    onTranslationReceived(content, queryId)
                    return
                default:
                    break
                }
                // Report error to parent using unified error message
                let message = BaseAPIService.getErrorMessageString(for: error)
                onTranslationError(message)
            }
        }
    }

    // MARK: - Helpers
    private func parseTextPatternStyles(from correctInput: String) -> [TextPatternStyle] {
        var styles: [TextPatternStyle] = []
        var hasWrongTags = false
        var hasSpellTags = false
        
        // Parse wrong tags: <wrong>text</wrong>
        let wrongPattern = "<wrong>(.*?)</wrong>"
        if let wrongRegex = try? NSRegularExpression(pattern: wrongPattern, options: []) {
            let matches = wrongRegex.matches(in: correctInput, options: [], range: NSRange(location: 0, length: correctInput.count))
            for match in matches {
                if let range = Range(match.range(at: 1), in: correctInput) {
                    let text = String(correctInput[range])
                    let style = TextPatternStyle(
                        text: "["+text+"]",
                        color: UIColor.from(AppColors.Translation.wrong(isDarkMode: isDarkMode))
                    )
                    styles.append(style)
                    hasWrongTags = true
                }
            }
        }
        
        // Parse spell tags: <spell>text</spell>
        let spellPattern = "<spell>(.*?)</spell>"
        if let spellRegex = try? NSRegularExpression(pattern: spellPattern, options: []) {
            let matches = spellRegex.matches(in: correctInput, options: [], range: NSRange(location: 0, length: correctInput.count))
            for match in matches {
                if let range = Range(match.range(at: 1), in: correctInput) {
                    let text = String(correctInput[range])
                    let style = TextPatternStyle(
                        text: text,
                        color: UIColor.from(AppColors.Translation.spell(isDarkMode: isDarkMode))
                    )
                    styles.append(style)
                    hasSpellTags = true
                }
            }
        }
        
        // Update tip visibility flags
        showUntranslatedTip = hasWrongTags
        showSpellErrorTip = hasSpellTags
        
        return styles
    }
    
    // Parse text pattern styles from translated text (for [] brackets)
    private func parseTranslatedTextPatternStyles(from translatedText: String) -> [TextPatternStyle] {
        var styles: [TextPatternStyle] = []
        
        // Parse wrong words between [] brackets
        let wrongPattern = "\\[([^\\]]*)\\]"
        if let wrongRegex = try? NSRegularExpression(pattern: wrongPattern, options: []) {
            let matches = wrongRegex.matches(in: translatedText, options: [], range: NSRange(location: 0, length: translatedText.count))
            for match in matches {
                if let range = Range(match.range(at: 1), in: translatedText) {
                    let text = String(translatedText[range])
                    let style = TextPatternStyle(
                        text: text,
                        color: UIColor.from(AppColors.Translation.wrong(isDarkMode: isDarkMode))
                    )
                    styles.append(style)
                }
            }
        }
        
        return styles
    }
    
    // Clean correct_input by removing HTML tags but keeping the content
    private func cleanCorrectInput(_ correctInput: String) -> String {
        var cleaned = correctInput
        
        // Remove <wrong> and </wrong> tags but keep content
        cleaned = cleaned.replacingOccurrences(of: "<wrong>", with: "[")
        cleaned = cleaned.replacingOccurrences(of: "</wrong>", with: "]")
        
        // Remove <spell> and </spell> tags but keep content
        cleaned = cleaned.replacingOccurrences(of: "<spell>", with: "")
        cleaned = cleaned.replacingOccurrences(of: "</spell>", with: "")
        
        return cleaned
    }
    
    private func inferErrorType(from message: String) -> ErrorView.ErrorType {
        let lower = message.lowercased()
        if lower.contains("network") || lower.contains("offline") || lower.contains("internet") || lower.contains("timeout") || lower.contains("timed out") {
            return .network
        }
        return .service
    }
}


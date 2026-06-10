import SwiftUI
import os

struct GrammarView: View {
    let onBackTap: () -> Void
    let onApplyTap: (Int) -> Void
    let onCloseTap: (Int) -> Void
    let onApplyAllTap: () -> Void
    let onRetryTap: () -> Void
    
    let text: String
    let isLoading: Bool
    let isApplyLoading: Bool
    let showSuggestion: Bool
    let wordOutputs: [WordOutput]
    let suggestionsList: [[WordOutput]]
    let grammarErrorMessage: String
    let grammarNoSuggestion: Bool
    let backgroundColor: Color
    let isDarkMode: Bool
    
    var body: some View {
        var stackAlignment: Alignment = .center

        // Set to topLeading when showing loading text or when there's text but no suggestions/errors
        if isLoading || isApplyLoading || (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && grammarErrorMessage.isEmpty && !grammarNoSuggestion) {
            stackAlignment = .topLeading
        }
        
        // Override to center when text is empty
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            stackAlignment = .center
        }

        let totalCorrections: Int
        if suggestionsList.isEmpty {
            let filtered = wordOutputs.filter { $0.state == .corrected || $0.state == .spell }
            totalCorrections = filtered.count
        } else {
            let flattened = suggestionsList.flatMap { $0 }
            let filtered = flattened.filter { $0.state == .corrected || $0.state == .spell }
            totalCorrections = filtered.count
        }

       return VStack(spacing: 0) {
         TopBar(
             title: "Grammar fix",
             icon: "ic_grammer",
             iconSize: 24,
             isDarkMode: isDarkMode,
             onBackTap: onBackTap,
             extraContent: {
                    Spacer().frame(height: 0)
             }
          )

          Spacer()


            // Content area - shows suggestions or text input
            VStack {
                if !isLoading && showSuggestion && (!wordOutputs.isEmpty || !suggestionsList.isEmpty) && !isApplyLoading {
                    // Show grammar suggestions
                    VStack(spacing: 0) {
                        // Header with corrections count and Apply all button
                        HStack {
                            Text("\(totalCorrections) Correction\(totalCorrections != 1 ? "s" : "") suggested")
                                .font(Font.sfProDisplay(size: 16, weight: .medium))
                                .foregroundColor(AppColors.Primary.blue(isDarkMode: isDarkMode))
                                .padding(.leading, 16)
                            
                            Spacer()
                            
                            // Apply all button (only show when multiple suggestions)
                            if suggestionsList.count > 1 {
                                Button(action: onApplyAllTap) {
                                    Text("Apply all")
                                        .font(Font.sfProDisplay(size: 16, weight: .regular))
                                        .underline()
                                        .foregroundColor(AppColors.Grammar.applyAll(isDarkMode: isDarkMode))

                                }
                                .padding(.trailing, 16)
                            }else{
                                Spacer().frame(width: 8)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 8)

                        // Suggestion container
                        if suggestionsList.isEmpty {
                           Spacer().frame(height: 8)
                            // Single suggestion made scrollable
                            ScrollView {
                                VStack(spacing: 0) {
                                    // Correct phrase label with action buttons
                                    HStack {
                                        Text("Correct phrase:")
                                            .font(Font.sfProDisplay(size: 16, weight: .regular))
                                            .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                        
                                        Spacer()
                                        
                                        // Close button (X)
                                        Button(action: { onCloseTap(0) }) {
                                            Image(systemName: "xmark")
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                                .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                        }
                                        .padding(.trailing, 8)
                                        
                                        Spacer().frame(width: 32)
                                        
                                        // Check button
                                        Button(action: { onApplyTap(0) }) {
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .frame(width: 16, height: 12)
                                                .foregroundColor(AppColors.Action.success(isDarkMode: isDarkMode))
                                        }

                                        Spacer().frame(width: 4)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 16)
                                    
                                    // Text with highlighted corrections (wrapped)
                                    VStack(alignment: .leading, spacing: 0) {
                                        let composed: Text = wordOutputs.enumerated().reduce(Text("") ) { acc, element in
                                            let (index, word) = element
                                            let prefix = index > 0 ? " " : ""
                                            let part = Text(prefix + word.value)
                                                .foregroundColor(colorForWordState(word.state))
                                                .font((word.state == .corrected || word.state == .spell) ? Font.sfProDisplay(size: 16, weight: .bold) : Font.sfProDisplay(size: 16))
                                                .strikethrough(word.state == .wrong && !word.value.isEmpty, color: colorForWordState(word.state))
                                            return acc + part
                                        }
                                        composed
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.bottom, 16)
                                    .padding(.horizontal, 16)
                                }
                                .background(AppColors.Background.card(isDarkMode: isDarkMode))
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }
                        } else {
                            // Multiple suggestions - scrollable list
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(suggestionsList.indices, id: \.self) { index in
                                        let suggestion = suggestionsList[index]
                                        VStack(spacing: 0) {
                                            // Correct phrase label with action buttons
                                            HStack {
                                                Text("Correct phrase:")
                                                .font(Font.sfProDisplay(size: 16, weight: .regular))
                                                .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                                
                                                Spacer()
                                                
                                                // Close button (X)
                                                Button(action: { onCloseTap(index) }) {
                                                    Image(systemName: "xmark")
                                                        .resizable()
                                                        .frame(width: 14, height: 14)
                                                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                                }
                                                .padding(.trailing, 8)

                                                Spacer().frame(width: 32)
                                                
                                                // Check button
                                                Button(action: { onApplyTap(index) }) {
                                                    Image(systemName: "checkmark")
                                                        .resizable()
                                                        .frame(width: 16, height: 12)
                                                        .foregroundColor(.green)
                                                }

                                                Spacer().frame(width: 4)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.top, 16)
                                            .padding(.bottom, 16)
                                            
                                            // Text with highlighted corrections (wrapped)
                                            VStack(alignment: .leading, spacing: 0) {
                                                let composed: Text = suggestion.enumerated().reduce(Text("") ) { acc, element in
                                                    let (index, word) = element
                                                    let prefix = index > 0 ? " " : ""
                                                    let part = Text(prefix + word.value)
                                                        .foregroundColor(colorForWordState(word.state))
                                                        .font((word.state == .corrected || word.state == .spell) ? Font.sfProDisplay(size: 16, weight: .bold) : Font.sfProDisplay(size: 16))
                                                        .strikethrough(word.state == .wrong && !word.value.isEmpty, color: colorForWordState(word.state))
                                                    return acc + part
                                                }
                                                composed
                                                    .lineLimit(nil)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.bottom, 16)
                                            .padding(.horizontal, 16)
                                        }
                                        .background(AppColors.Background.card(isDarkMode: isDarkMode))
                                        .cornerRadius(12)
                                        .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .frame(height: 190)

                } else {
                    // Show text input area (original content)
                    ZStack(alignment:stackAlignment) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.Background.card(isDarkMode: isDarkMode))
                        if isLoading || isApplyLoading {

                        BouncingDotsLoadingView(text: isApplyLoading ? "Applying changes" : "Checking your grammar", isDarkMode: isDarkMode)
                        }
                       else if !grammarErrorMessage.isEmpty {
                            // Show error message
                            ErrorView(
                                errorType: grammarErrorMessage.contains("network_error") ? .network : 
                                          grammarErrorMessage.contains("422") ? .meaninglessText : .service,
                                isDarkMode: isDarkMode,
                                onRetry: {
                                    // Clear error message and retry grammar check
                                    onRetryTap() // This will trigger the retry in the parent view
                                }
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if grammarNoSuggestion {
                            // Show no suggestion message
                            Text("It's all good!")
                                .font(Font.sfProDisplay(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding(.horizontal, 16)
                        } else if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Group {
                                                let bundle = Bundle(for: KeyboardViewController.self)
                                                if let imagePath = bundle.path(forResource: isDarkMode ? "helper_text_dark" : "helper_text", ofType: "png"),
                                                   let uiImage = UIImage(contentsOfFile: imagePath) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 300, height: 40)

                                                } else {
                                                    // Fallback to system icon
                                                    Image(systemName: "checkmark.circle")
                                                        .resizable()
                                                        .frame(width: 24, height: 24)
                                                        .foregroundColor(.blue)
                                                }
                                            }

                        } else if text.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 {
                            Text("Keep typing so I can review your text")
                                .font(Font.sfProDisplay(size: 16, weight: .light))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        } else {
                            // Show no suggestion message
                            Text("It's all good!")
                                .font(Font.sfProDisplay(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding(.horizontal, 16)

                        }
                    }
                    .frame(height: 190)
                    .padding(.horizontal, 16)
                }
            }
            .background(backgroundColor)

            Spacer()

        }
        .background(backgroundColor)
        .frame(height: 274) // Standard keyboard height
        .padding(.bottom, 7.2)
    }
    
    private func colorForWordState(_ state: WordState) -> Color {
        switch state {
        case .wrong:
            return AppColors.Grammar.wrong(isDarkMode: isDarkMode)
        case .corrected:
            return AppColors.Grammar.corrected(isDarkMode: isDarkMode)
        case .spell:
            return AppColors.Grammar.spell(isDarkMode: isDarkMode)
        case .normal:
            return AppColors.Grammar.normal(isDarkMode: isDarkMode)
        }
    }
    
    private func backgroundColorForWordState(_ state: WordState) -> Color {
        switch state {
        case .wrong:
            return Color.clear
        case .corrected:
            return Color.clear
        case .spell:
            return Color.clear
        case .normal:
            return Color.clear
        }
    }
}

#Preview {
    let sampleWordOutputs: [WordOutput] = [
        WordOutput(value: "Hello", state: .normal),
        WordOutput(value: "what", state: .normal),
        WordOutput(value: "is", state: .wrong),
        WordOutput(value: "are", state: .corrected),
        WordOutput(value: "you", state: .normal),
        WordOutput(value: "doing", state: .normal),
        WordOutput(value: "this", state: .wrong),
        WordOutput(value: "night", state: .wrong),
        WordOutput(value: "tonight", state: .corrected),
        WordOutput(value: "?", state: .normal),
    ]
    
    GrammarView(
        onBackTap: {},
        onApplyTap: { _ in },
        onCloseTap: { _ in },
        onApplyAllTap: {},
        onRetryTap: {},
        text: "Hello what is are you doing this night tonight?",
        isLoading: false,
        isApplyLoading: false,
        showSuggestion: true,
        wordOutputs: sampleWordOutputs,
        suggestionsList: [],
        grammarErrorMessage: "",
        grammarNoSuggestion: false,
        backgroundColor: Color(.systemGray6),
        isDarkMode: false
    )
}

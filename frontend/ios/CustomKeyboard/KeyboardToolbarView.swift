//
//  KeyboardToolbarView.swift
//  CustomKeyboard
//
//  Created by Royal Macbook  on 5/1/25.
//

import SwiftUI
import UIKit

struct SignInTooltipView: View {
    let isDarkMode: Bool
    let onDismiss: () -> Void
    let onSignInTap: () -> Void
    
    var body: some View {
    var width = 290.0

       return ZStack(alignment: .top) {
            // Background tap area to dismiss
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
            
            // Tooltip with image background
            ZStack {
                // Background image
                Group {
                    let bundle = Bundle(for: KeyboardViewController.self)
                    if let imagePath = bundle.path(forResource: "tooltip_background", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width, height: 80)

                    } else {
                        // Fallback to dark grey background if image not found
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.35, green: 0.35, blue: 0.35))
                    }
                }

                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Title: "Sign in required" in bold white
                    Text("Sign in required")
                        .font(Font.sfProDisplay(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Body with "Sign in" link on the same line, positioned to the right
                    HStack(spacing: 0) {
                        Text("Please sign in to access this feature")
                            .font(Font.sfProDisplay(size: 14, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.9))
                        
                        Spacer()
                        
                        // "Sign in" link in blue, underlined
                        Button(action: onSignInTap) {
                            Text("Sign in")
                                .font(Font.sfProDisplay(size: 14, weight: .bold))
                                .foregroundColor(AppColors.Primary.blue(isDarkMode: false))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                // Dismiss when tapping on the tooltip box
                onDismiss()
            }
        }
        .frame(maxWidth: width, alignment: .leading)
        .offset(x: -3, y: 24)
    }
}

struct LogoView: View {
    let isDarkMode: Bool
    let hasFullAccess: Bool
    let grammarState: BackgroundGrammarState

    private var isLoggedIn: Bool {
        AppGroupManager.shared.isUserLoggedIn()
    }
    
    private var logoId: String {
        let logoName = getLogo(isLoggedIn: isLoggedIn)
        let stateString: String
        switch grammarState {
        case .idle: stateString = "idle"
        case .checking: stateString = "checking"
        case .hasErrors(let count): stateString = "errors-\(count)"
        case .noErrors: stateString = "noErrors"
        }
        return "\(logoName)-\(stateString)"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            logoImageView
            badgeView
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.6), value: grammarState)
        .animation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.6), value: isLoggedIn)
    }
    
    private var logoImageView: some View {
        Group {
            let bundle = Bundle(for: KeyboardViewController.self)
            if let imagePath = bundle.path(forResource: getLogo(isLoggedIn: isLoggedIn), ofType: "png"),
               let uiImage = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .renderingMode(isLoggedIn ? .original : .template)
                    .foregroundColor(isLoggedIn ? nil : Color(red: 0.72, green: 0.73, blue: 0.75))
                    .frame(width: getLogo(isLoggedIn: isLoggedIn) == "logo_error" ? 30 : 30, height: getLogo(isLoggedIn: isLoggedIn) == "logo_error" ? 41.7 : 41)
                    .offset(y: getLogo(isLoggedIn: isLoggedIn) == "logo_error" ? -0.9 : 0)
                    .id(logoId)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.6), value: grammarState)
            } else {
                fallbackLogoView
            }
        }
    }
    
    private var fallbackLogoView: some View {
        ZStack {
            Circle()
                .fill(getLogoColor(isLoggedIn: isLoggedIn))
            Path { path in
                path.move(to: CGPoint(x: 12, y: 8))
                path.addLine(to: CGPoint(x: 12, y: 32))
                path.addArc(center: CGPoint(x: 20, y: 20), radius: 12, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                path.closeSubpath()
            }
            .fill(AppColors.Background.card(isDarkMode: isDarkMode))
        }
        .animation(.easeInOut(duration: 0.5), value: getLogoColor(isLoggedIn: isLoggedIn))
    }
    
    @ViewBuilder
    private var badgeView: some View {
        if !isLoggedIn && hasFullAccess {
            warningBadge
        } else if case .hasErrors(let count) = grammarState, isLoggedIn {
            errorBadge(count: count)
        } else if case .noErrors = grammarState, isLoggedIn {
            successBadge
        }
    }
    
    private var warningBadge: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            Image(systemName: "exclamationmark")
                .foregroundColor(Color.red)
                .font(.system(size: 13, weight: .bold))
        }
        .offset(x: 6, y: -2)
        .transition(.scale(scale: 0.7).combined(with: .opacity))
        .id("warning-badge")
    }
    
    private func errorBadge(count: Int) -> some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 22, height: 22)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .id("error-\(count)")
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
        .offset(x: 6, y: -2)
        .transition(.scale(scale: 0.7).combined(with: .opacity))
        .id("error-badge-\(count)")
    }
    
    private var successBadge: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 22, height: 22)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            Image(systemName: "checkmark")
                .foregroundColor(.white)
                .font(.system(size: 11, weight: .bold))
        }
        .offset(x: 6, y: -2)
        .transition(.scale(scale: 0.7).combined(with: .opacity))
        .id("success-badge")
    }

    // Helper to determine logo color based on state
    private func getLogoColor(isLoggedIn: Bool) -> Color {
        if !isLoggedIn {
            return Color(red: 0.72, green: 0.73, blue: 0.75)
        }
        
        switch grammarState {
        case .idle, .checking:
            return AppColors.Primary.blue(isDarkMode: isDarkMode)
        case .hasErrors(_):
            return Color.red
        case .noErrors:
            return Color.green
        }
    }
    private func getLogo(isLoggedIn: Bool) -> String {
        if !isLoggedIn {
            return "logo"
        }

        switch grammarState {
        case .idle, .checking:
            return "logo"
        case .hasErrors(_):
            return "logo_error"
        case .noErrors:
            return "logo_correct"
        }
    }
}

struct KeyboardToolbarView: View {
    @ObservedObject var controller: KeyboardViewController
    let onLogoTap: () -> Void
    let onTranslateTap: () -> Void
    let onGrammarTap: () -> Void
    let onFormalTap: () -> Void
    let onFriendlyTap: () -> Void
    let onConciseTap: () -> Void
    let onPredictionTap: (String) -> Void
    let favoriteTones: [String]
    let currentLocale: Locale
    let isDarkMode: Bool

    var body: some View {
        //get first three items from predictedWords
        let predictedWords = Array(controller.predictedWords.prefix(3))
        var toneSpacing = predictedWords.isEmpty ? 8.0 : 4.0

       return VStack(spacing: 0) {

        HStack(spacing: 5) {
            LogoView(isDarkMode: isDarkMode, hasFullAccess: controller.hasFullAccess, grammarState: controller.backgroundGrammarState)
                .frame(width: 40, height: 40)
                .onTapGesture {
                let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
                let hasFullAccess = controller.hasFullAccess
                if(!hasFullAccess) {
                 onGrammarTap()
                }
               else if (currentLocale.identifier == Locale.persian.identifier || !isLoggedIn){
                    onLogoTap()
                    }
                else{
                onGrammarTap()
                }
                }




            // Translate button with border
            Button(action: onTranslateTap) {
                Group {
                    let bundle = Bundle(for: KeyboardViewController.self)
                    if let imagePath = bundle.path(forResource: "ic_translate", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 28, height: 28)
                    } else {
                        // Fallback to system icon
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.Primary.blue(isDarkMode: isDarkMode))
                    }
                }
                .padding(6)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.Border.default(isDarkMode: isDarkMode), lineWidth: 1)
                )
            }

            // Tone area with dynamic favorite tones or default tones
            HStack (spacing: toneSpacing){
              Button(action: onFormalTap) {
                Group {
                    let bundle = Bundle(for: KeyboardViewController.self)
                    if let imagePath = bundle.path(forResource: "ic_tone", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .renderingMode(.original)
                            .frame(width: 26, height: 26)
                    } else {
                        // Fallback to system icon
                        Image(systemName: "waveform")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.Primary.blue(isDarkMode: isDarkMode))
                    }
                    }
                }
                .background(AppColors.Background.keyboard(isDarkMode: isDarkMode))
                .animation(nil, value: predictedWords.isEmpty)
                if predictedWords.isEmpty {
                    HStack(spacing: 0) {
                        Spacer()
                        ForEach(Array(getToneButtons().enumerated()), id: \.offset) { index, tone in
                            if index > 0 {
                                Rectangle()
                                    .fill(AppColors.Border.default(isDarkMode: isDarkMode))
                                    .frame(width: 1, height: 20)
                                Spacer()
                            }

                            Button(action: getToneAction(for: tone)) {
                                Text(tone)
                                    .font(Font.sfProDisplay(size: 16, weight: .semibold))
                                    .foregroundColor(getToneColor(for: tone))
                            }

                            if index < getToneButtons().count - 1 {
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).animation(.easeInOut(duration: 0.3))
                            .combined(with: .opacity.animation(.easeInOut(duration: 0.2).delay(0.5))),
                        removal: .opacity.animation(.easeInOut(duration: 0.1))
                            .combined(with: .move(edge: .leading).animation(.easeInOut(duration: 0.3).delay(0.2)))
                    ))
                }
                Button(action: onFormalTap) {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.Primary.blue(isDarkMode: isDarkMode))
                    .font(.system(size: 12, weight: .heavy))
                    .padding(5)
                    .padding(.horizontal, 2)
                    .background(AppColors.Text.disabled(isDarkMode: isDarkMode).opacity(0.15))
                    .cornerRadius(4)
                }

            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.Border.default(isDarkMode: isDarkMode), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.5), value: predictedWords.isEmpty)

             if !predictedWords.isEmpty {
                            GeometryReader { proxy in
                                let totalWidth = proxy.size.width
                                let visibleWords = visibleSuggestionsPrefix(
                                    suggestions: predictedWords,
                                    totalAvailableWidth: totalWidth,
                                    perButtonPadding: 0,
                                    dividerThickness: 1
                                )
                                HStack(spacing: 0) {
                                    ForEach(Array(visibleWords.enumerated()), id: \.element) { index, word in
                                        Button(action: { onPredictionTap(word) }) {
                                            Text(word)
                                                .font(Font.sfProDisplay(size: 16, weight: .semibold))
                                                .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .frame(maxWidth: .infinity)

                                        if index < visibleWords.count - 1 {
                                            Rectangle()
                                                .fill(AppColors.Border.default(isDarkMode: isDarkMode))
                                                .frame(width: 1, height: 16)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20)
                            .transition(.asymmetric(
                                insertion: .opacity.animation(.easeInOut(duration: 0.2).delay(0.5)),
                                removal: .opacity.animation(.easeInOut(duration: 0.1))
                            ))
                         }



        }
        .padding(.horizontal, 10)
        .offset(y: 24.5)
        }
        .frame(height: 11)
        .padding(.top, 3)
   }
    
    // Helper function to get tone buttons to display
    private func getToneButtons() -> [String] {
        //if we has favorite tone then return favorire tones plus remaining default tones
        if favoriteTones.count > 0 {
            let defaultTones = ["Formal", "Friendly", "Concise"]
            let remainings = defaultTones.filter { !favoriteTones.contains($0) }
            return favoriteTones + remainings
        }
    
        
        // If no favorites or less than 2, show default tones
        else {
            return ["Formal", "Friendly", "Concise"]
        }
    }
    
    // Helper function to get action for a tone
    private func getToneAction(for tone: String) -> () -> Void {
        switch tone {
        case "Formal":
            return onFormalTap
        case "Friendly":
            return onFriendlyTap
        case "Concise":
            return onConciseTap
        default:
            return onFormalTap
        }
    }
    
    // Helper function to get color for a tone
    private func getToneColor(for tone: String) -> Color {
            return AppColors.Text.primary(isDarkMode: isDarkMode)

    }

    // Detect if a single-line suggestion text will truncate within a given width.
    // - Parameters:
    //   - text: The suggestion string to render.
    //   - availableWidth: The horizontal space available for the text.
    //   - horizontalPadding: Optional padding applied inside the button/container.
    //   - fontSize: Font size used for suggestions (defaults to 16).
    //   - weight: Font weight used for suggestions (defaults to .semibold).
    // - Returns: true if the text needs truncation to fit; false otherwise.
    private func isSuggestionTruncated(
        _ text: String,
        availableWidth: CGFloat,
        horizontalPadding: CGFloat = 0,
        fontSize: CGFloat = 16,
        weight: UIFont.Weight = .semibold
    ) -> Bool {
        // Try to use the project font, fall back to system if unavailable.
        let uiFont = UIFont(name: "SF-Pro-Display-Semibold", size: fontSize)
            ?? UIFont.systemFont(ofSize: fontSize, weight: weight)

        // Measure the single-line width of the text using the chosen font.
        let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
        let measuredWidth = (text as NSString).size(withAttributes: attributes).width

        // Compare to available width (after padding) to determine truncation.
        let effectiveWidth = max(0, availableWidth - horizontalPadding)
        return measuredWidth > effectiveWidth
    }

    // Convenience: detect truncation when suggestions share a single row evenly.
    // Supply the total available width of the suggestions container.
    private func isSuggestionTruncatedInSharedRow(
        _ text: String,
        totalAvailableWidth: CGFloat,
        suggestionCount: Int,
        perButtonPadding: CGFloat = 0,
        dividerThickness: CGFloat = 1,
        fontSize: CGFloat = 16,
        weight: UIFont.Weight = .semibold
    ) -> Bool {
        let count = max(1, suggestionCount)
        let totalDividers = max(0, count - 1)
        let widthPerButton = (totalAvailableWidth - CGFloat(totalDividers) * dividerThickness) / CGFloat(count)
        return isSuggestionTruncated(
            text,
            availableWidth: widthPerButton,
            horizontalPadding: perButtonPadding,
            fontSize: fontSize,
            weight: weight
        )
    }

    // Determine the longest prefix of suggestions that fits without truncation.
    // Earlier items have priority: reduce count until the prefix fits.
    private func visibleSuggestionsPrefix(
        suggestions: [String],
        totalAvailableWidth: CGFloat,
        perButtonPadding: CGFloat = 0,
        dividerThickness: CGFloat = 1,
        fontSize: CGFloat = 16,
        weight: UIFont.Weight = .semibold
    ) -> [String] {
        guard !suggestions.isEmpty else { return [] }
        var k = suggestions.count
        while k > 0 {
            let count = k
            let totalDividers = max(0, count - 1)
            let widthPerButton = (totalAvailableWidth - CGFloat(totalDividers) * dividerThickness) / CGFloat(count)
            let prefix = Array(suggestions.prefix(k))
            let fits = prefix.allSatisfy { word in
                !isSuggestionTruncated(
                    word,
                    availableWidth: widthPerButton,
                    horizontalPadding: perButtonPadding,
                    fontSize: fontSize,
                    weight: weight
                )
            }
            if fits { return prefix }
            k -= 1
        }
        return []
    }
}

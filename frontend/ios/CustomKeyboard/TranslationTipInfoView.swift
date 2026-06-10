import SwiftUI

struct TipData {
    let text: String
    let highlightedText: String
    let highlightColor: Color
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct TranslationTipInfoView: View {
    let isDarkMode: Bool
    let showUntranslatedTip: Bool
    let showSpellErrorTip: Bool
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var currentTipIndex: Int = 0
    @State private var swipeOffset: CGFloat = 0

    private var containerBackground: Color {
        AppColors.Background.keyboard(isDarkMode: isDarkMode)
    }

    private var textColor: Color {
        AppColors.Text.primary(isDarkMode: isDarkMode)
    }
    
    private var availableTips: [TipData] {
        var tips: [TipData] = []
        if showSpellErrorTip {
            tips.append(TipData(
                text: "Some typos were fixed — changes are highlighted",
                highlightedText: "highlighted",
                highlightColor: AppColors.Grammar.spell(isDarkMode: isDarkMode)
            ))
        }
        if showUntranslatedTip {
            tips.append(TipData(
                text: "Some words couldn't be translated — marked in [ ]",
                highlightedText: "marked in [ ]",
                highlightColor: AppColors.Grammar.wrong(isDarkMode: isDarkMode)
            ))
        }
        return tips
    }
    
    private var currentTip: TipData? {
        guard !availableTips.isEmpty, currentTipIndex < availableTips.count else { return nil }
        return availableTips[currentTipIndex]
    }
    
    private var canNavigate: Bool {
        availableTips.count > 1
    }
    
    private var counterText: String {
        guard canNavigate else { return "" }
        return "\(currentTipIndex + 1)/\(availableTips.count)"
    }

    var body: some View {
        mainContainer
    }
    
    private var mainContainer: some View {
        ZStack(alignment: .leading) {
             HStack(spacing: 4) {
                 contentArea
             }
             .padding(.horizontal, 14)
             .padding(.vertical, 10)
             .background(containerBackground)
             .cornerRadius(12)
             .overlay(borderOverlay)
             .padding(.leading, 44)

            infoIcon

        }
                 .offset(y: offsetY)
                 .opacity(opacity)
                 .onAppear(perform: animateIn)
}
    
    private var infoIcon: some View {
    ZStack(alignment: .center) {
                Group {
                    let bundle = Bundle(for: KeyboardViewController.self)
                    if let imagePath = bundle.path(forResource: isDarkMode ? "tip_shape_dark" : "tip_shape", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                    } else {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                    }
                }
        Group {
            let bundle = Bundle(for: KeyboardViewController.self)
            if let imagePath = bundle.path(forResource: "ic_info", ofType: "png"),
               let uiImage = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .renderingMode( isDarkMode ? .template : .original)
                    .scaledToFit()
                    .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
            }
        }
        .padding(.trailing, 6)
        .padding(.top, 2)

    }
    }
    
    private var contentArea: some View {
        HStack {
            if canNavigate {
                swipeableContent
            } else {
                singleTipContent
            }
            Spacer()
            if canNavigate {
                navigationControls
            }
        }
    }
    
    private var swipeableContent: some View {
        ZStack {
            ForEach(0..<availableTips.count, id: \.self) { index in
                if let tip = availableTips[safe: index] {
                    tipView(for: tip)
                        .offset(x: CGFloat(index - currentTipIndex) * 300 + swipeOffset)
                        .opacity(index == currentTipIndex ? 1.0 : 0.0)
                }
            }
        }
        .clipped()
    }
    
    private var singleTipContent: some View {
        Group {
            if let tip = currentTip {
                tipView(for: tip)
            } else {
                Text("Translation completed")
                    .foregroundColor(textColor)
                    .font(.system(size: 13, weight: .regular))
            }
        }
    }
    
    private var navigationControls: some View {
        HStack(spacing: 4) {
            Text(counterText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
            
            Button(action: navigateToNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
            }
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                Color(red: 0.82, green: 0.84, blue: 0.87),
                lineWidth: 1
            )
    }
        private func navigateToNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentTipIndex < availableTips.count - 1 {
                currentTipIndex += 1
            } else {
                currentTipIndex = 0
            }
        }
    }
    
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.6)) {
            offsetY = 0
            opacity = 1
        }
    }
    
    @ViewBuilder
    private func tipView(for tip: TipData) -> some View {
        let parts = tip.text.components(separatedBy: tip.highlightedText)
        
        if parts.count == 2 {
            let beforeText = parts[0]
            let afterText = parts[1]
            
            HStack(spacing: 0) {
                Text(beforeText)
                    .foregroundColor(textColor)
                Text(tip.highlightedText)
                    .foregroundColor(tip.highlightColor)
                Text(afterText)
                    .foregroundColor(textColor)
            }
            .font(.system(size: 12, weight: .regular))
            .lineLimit(1)
            .multilineTextAlignment(.leading)
        } else {
            Text(tip.text)
                .foregroundColor(textColor)
                .font(.system(size: 12, weight: .regular))
                .lineLimit(1)
                .multilineTextAlignment(.leading)
        }
    }
}
#if DEBUG
#Preview {
    VStack(spacing: 12) {
        // Light mode examples
        TranslationTipInfoView(isDarkMode: false, showUntranslatedTip: true, showSpellErrorTip: false)
        TranslationTipInfoView(isDarkMode: false, showUntranslatedTip: false, showSpellErrorTip: true)
        TranslationTipInfoView(isDarkMode: false, showUntranslatedTip: true, showSpellErrorTip: true)
        
        // Dark mode examples
        TranslationTipInfoView(isDarkMode: true, showUntranslatedTip: true, showSpellErrorTip: false)
            .preferredColorScheme(.dark)
        TranslationTipInfoView(isDarkMode: true, showUntranslatedTip: false, showSpellErrorTip: true)
            .preferredColorScheme(.dark)
        TranslationTipInfoView(isDarkMode: true, showUntranslatedTip: true, showSpellErrorTip: true)
            .preferredColorScheme(.dark)
    }
    .padding()
}
#endif

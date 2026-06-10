import SwiftUI
import os

// Enum to track which tone tab is selected
enum ToneType: String, CaseIterable {
    case formal = "Formal"
    case friendly = "Friendly"
    case concise = "Concise"
}

// Reusable tone tabs widget
struct ToneTabsView: View {
    @Binding var selectedTone: String
    let padding: CGFloat
    let isDarkMode: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ToneType.allCases, id: \.self) { tone in
                Button(action: {
                    selectedTone = tone.rawValue
                }) {
                    Text(tone.rawValue)
                        .font(Font.sfProDisplay(size: 13, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTone == tone.rawValue ? 
                            (tone == .formal ? AppColors.Tone.formal(isDarkMode: isDarkMode) :
                             tone == .friendly ? AppColors.Tone.friendly(isDarkMode: isDarkMode) :
                             AppColors.Tone.concise(isDarkMode: isDarkMode)) : AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .padding(.horizontal, 20)
                        .padding(.vertical, padding)
                        .background(selectedTone == tone.rawValue ? 
                            (tone == .formal ? AppColors.Tone.formalBackground(isDarkMode: isDarkMode) :
                             tone == .friendly ? AppColors.Tone.friendlyBackground(isDarkMode: isDarkMode) :
                             AppColors.Tone.conciseBackground(isDarkMode: isDarkMode)) : Color.clear)
                        .cornerRadius(8)
                }
            }
            
            // Disabled "More tones soon!" tab
            Text("More tones soon!")
                .italic()
                .font(Font.sfProDisplay(size: 9, weight: .light))
                .italic()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
                .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                .padding(.leading, 8)
                .padding(.vertical, padding)
                .background(Color.clear)

        }
        .padding(.horizontal, padding)
        .padding(.top, padding * 0.5)
        .padding(.bottom, padding * 0.5)
                .frame(maxWidth: .infinity)
        .background(AppColors.Background.toneTabs(isDarkMode: isDarkMode))
        .cornerRadius(8)
        .padding(.horizontal, 12)
    }
}

struct ToneView: View {
    let onBackTap: () -> Void
    let onApplyTap: (Int) -> Void
    let onCloseTap: (Int) -> Void
    let onRephraseTap: (Int) -> Void
    let onRetryTap: () -> Void

    let text: String
    let isLoading: Bool
    let isApplyLoading: Bool
    let toneAdjustedText: String
    let toneErrorMessage: String
    let toneNoSuggestion: Bool
    let backgroundColor: Color
    @Binding var selectedTone: String
    let isDarkMode: Bool
    @State private var adjustedTextHeight: CGFloat = 0
    @State private var scrollViewportHeight: CGFloat = 0
    
    var body: some View {
        var stackAlignment: Alignment = .center
        if isLoading || isApplyLoading || (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && toneAdjustedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && toneErrorMessage.isEmpty && !toneNoSuggestion){
            stackAlignment = .topLeading
        }
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            stackAlignment = .center
        }

       let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
       var text = self.text
       var toneErrorMessage = self.toneErrorMessage
       var isLoading = self.isLoading
       var isApplyLoading = self.isApplyLoading

       if !isLoggedIn {
           text = ""
           toneErrorMessage = "auth"
           isLoading = false
           isApplyLoading = false
       }

       return VStack(spacing: 0) {
            // Tone Toolbar
            TopBar(title: "Tone re-write",
             icon: "ic_tone",
             iconSize: 24,
             isDarkMode: isDarkMode,
             onBackTap: onBackTap,
             extraContent: {
                    Spacer().frame(height: 0)
             }
             )

             Spacer()

            // Content area - single flow (no suggestion sections)
            VStack {
                if isLoading || isApplyLoading {
                    VStack(spacing: 0) {
                        ToneTabsView(
                            selectedTone: $selectedTone,
                            padding: 8,
                            isDarkMode: isDarkMode
                        )
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        BouncingDotsLoadingView(text: isApplyLoading ? "Applying changes" : "Re-writing your tone", isDarkMode: isDarkMode)
                    }
                    .frame(height: 190)
                    .background(AppColors.Background.card(isDarkMode: isDarkMode))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)

                } else {
                    ZStack(alignment: stackAlignment) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.Background.card(isDarkMode: isDarkMode))

                        if !toneErrorMessage.isEmpty {
                            // Show error message
                            VStack(spacing: 0) {
                                ToneTabsView(
                                    selectedTone: $selectedTone,
                                    padding: 8,
                                    isDarkMode: isDarkMode
                                )
                                .padding(.top, 12)
                                .padding(.bottom, 5)
                                ErrorView(
                                    errorType: toneErrorMessage.contains("network_error") ? .network : 
                                              toneErrorMessage.contains("422") ? .meaninglessText : .service,
                                    isDarkMode: isDarkMode,
                                    userSmaller: true,
                                    onRetry: {
                                        // Clear error message and retry tone adjustment
                                        onRetryTap() // This will trigger the retry in the parent view
                                    }
                                )
                                .frame(maxWidth: .infinity, maxHeight: 135, alignment: .center)
                            }
                        } else if toneNoSuggestion {
                            // Show no suggestion message
                            VStack(spacing: 0) {
                                ToneTabsView(
                                    selectedTone: $selectedTone,
                                    padding: 8,
                                    isDarkMode: isDarkMode
                                )
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                                Text("It's all good!")
                                    .font(Font.sfProDisplay(size: 16))
                                    .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .padding(.horizontal, 16)
                            }
                        } else if !toneAdjustedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(spacing: 0) {
                                ToneTabsView(
                                    selectedTone: $selectedTone,
                                    padding: 8,
                                    isDarkMode: isDarkMode
                                )
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                                HStack(alignment: .top) {
                                    // Make scroll enabled only when content exceeds the visible viewport
                                    Group {
                                        if #available(iOS 16.0, *) {
                                            ScrollView {
                                                Text(toneAdjustedText)
                                                    .font(Font.sfProDisplay(size: 16))
                                                    .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                                                    .lineLimit(nil)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                                    .background(
                                                        GeometryReader { proxy in
                                                            Color.clear
                                                                .onAppear { DispatchQueue.main.async { adjustedTextHeight = proxy.size.height } }
                                                                .onChange(of: toneAdjustedText) { _ in
                                                                    DispatchQueue.main.async { adjustedTextHeight = proxy.size.height }
                                                                }
                                                        }
                                                    )
                                                    .padding(.bottom, 4)
                                            }
                                            .background(
                                                GeometryReader { proxy in
                                                    Color.clear
                                                        .onAppear { DispatchQueue.main.async { scrollViewportHeight = proxy.size.height } }
                                                        .onChange(of: proxy.size.height) { _ in
                                                            DispatchQueue.main.async { scrollViewportHeight = proxy.size.height }
                                                        }
                                                }
                                            )
                                            .scrollDisabled(adjustedTextHeight <= scrollViewportHeight + 0.5)
                                        } else {
                                            // Fallback for older iOS: default ScrollView behavior
                                            ScrollView {
                                                Text(toneAdjustedText)
                                                    .font(Font.sfProDisplay(size: 16))
                                                    .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                                                    .lineLimit(nil)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                            }
                                        }
                                    }
                                    Spacer()

                                    VStack(spacing: 0){


                                      Button(action: { onApplyTap(0) }) {
                                          Image(systemName: "checkmark")
                                              .resizable()
                                              .frame(width: 16, height: 12)
                                              .foregroundColor(AppColors.Action.success(isDarkMode: isDarkMode))
                                      }


                                     Spacer()

                                     // Rephrase button placed between Apply and Close
                                     Button(action: { onRephraseTap(0) }) {
                                         Group {
                                             let bundle = Bundle(for: KeyboardViewController.self)
                                             if let imagePath = bundle.path(forResource: isDarkMode ? "ic_rephrase_dark" : "ic_rephrase", ofType: "png"),
                                                let uiImage = UIImage(contentsOfFile: imagePath) {
                                                 Image(uiImage: uiImage)
                                                     .resizable()
                                                     .frame(width: 14, height: 14)
                                             } else {
                                                 Image(systemName: "arrow.triangle.2.circlepath")
                                                     .resizable()
                                                     .frame(width: 29, height: 29)
                                             }
                                         }
                                     }

                                     Spacer()

                                     Button(action: { onCloseTap(0) }) {
                                         Image(systemName: "xmark")
                                             .resizable()
                                             .frame(width: 14, height: 14)
                                             .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                     }

                                    }
                                     .padding(.trailing, 4)



                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 16)
                            }
                        } else {
                            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(spacing: 0) {
                                    ToneTabsView(
                                        selectedTone: $selectedTone,
                                        padding: 8,
                                        isDarkMode: isDarkMode
                                    )
                                    .padding(.top, 12)
                                    Spacer()
                                    Group {
                                        let bundle = Bundle(for: KeyboardViewController.self)
                                        if let imagePath = bundle.path(forResource: isDarkMode ? "helper_text_dark" : "helper_text", ofType: "png"),
                                           let uiImage = UIImage(contentsOfFile: imagePath) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                 .frame(width: 300, height: 40)
                                        } else {
                                            Image(systemName: "checkmark.circle")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(AppColors.Primary.blue(isDarkMode: isDarkMode))
                                        }
                                    }
                                    .padding(.bottom, 8)
                                    Spacer()
                                }
                            } else if text.trimmingCharacters(in: .whitespacesAndNewlines).count < 4 {
                                VStack(spacing: 0) {
                                    ToneTabsView(
                                        selectedTone: $selectedTone,
                                        padding: 8,
                                        isDarkMode: isDarkMode
                                    )
                                    .padding(.top, 12)
                                    Text("Keep typing so I can review your text")
                                        .font(Font.sfProDisplay(size: 16, weight: .light))
                                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 8)
                                }
                            } else {
                                VStack(spacing: 0) {
                                    ToneTabsView(
                                        selectedTone: $selectedTone,
                                        padding: 8,
                                        isDarkMode: isDarkMode
                                    )
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)

                                  BouncingDotsLoadingView(text: "Re-writing your tone", isDarkMode: isDarkMode)

                                }
                            }
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
    
}

#Preview {
    let sampleWords: [WordOutput] = [
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
    
    ToneView(
        onBackTap: {},
        onApplyTap: { _ in },
        onCloseTap: { _ in },
        onRephraseTap: { _ in },
        onRetryTap: {},
        text: "Hello what is are you doing this night tonight?",
        isLoading: false,
        isApplyLoading: false,
        toneAdjustedText: "I would appreciate it if you could review my report and provide your feedback.",
        toneErrorMessage: "",
        toneNoSuggestion: false,
        backgroundColor: Color(.systemGray6),
        selectedTone: .constant(ToneType.formal.rawValue),
        isDarkMode: false
    )
}

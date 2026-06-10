import SwiftUI
import UIKit

// A dedicated view to show the full-access disabled message
// Used as a replacement for feature views when full access is not enabled
struct FullAccessErrorView: View {
    let isDarkMode: Bool
    let backgroundColor: Color
    let onBackTap: () -> Void
    @Environment(\.openURL) private var openURL
    @State private var showInfoSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Centered arrow button like the provided image
            Button(action: {
                if showInfoSheet {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showInfoSheet = false
                    }
                } else {
                    onBackTap()
                }
            }) {
                Image(systemName: "chevron.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 10)
                    .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                    .contentShape(Rectangle())
                    .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: 45)
            .padding(.top, 8)
            .onTapGesture{
                if showInfoSheet {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showInfoSheet = false
                    }
                } else {
                    onBackTap()
                }
            }

            Spacer()

            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.Background.card(isDarkMode: isDarkMode))

                ErrorView(
                    errorType: .fullAccessDisabled,
                    isDarkMode: isDarkMode,
                    userSmaller: true,
                    onRetry: {
                        // Attempt to open the app's settings in System Settings
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            _ = openURL(settingsURL)
                        }
                    },
                    onInfoTap: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showInfoSheet = true
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: 190, alignment: .center)
            }
            .frame(height: 190)
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(backgroundColor)
        .frame(height: 274)
        .padding(.bottom, 7.2)
        .overlay(alignment: .bottom) {
            if showInfoSheet {
                InfoBottomSheet(
                    isDarkMode: isDarkMode,
                    backgroundColor: backgroundColor,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showInfoSheet = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: showInfoSheet)
    }
}

#Preview {
    FullAccessErrorView(
        isDarkMode: false,
        backgroundColor: Color(.systemGray6),
        onBackTap: {}
    )
}

// MARK: - Bottom Sheet for Info
private struct InfoBottomSheet: View {
    let isDarkMode: Bool
    let backgroundColor: Color
    let onDismiss: () -> Void
    @State private var dragOffset: CGFloat = 0

    private let sheetHeight: CGFloat = 230
    private let dismissThreshold: CGFloat = 120

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 50)
                                .fill(.white)
                                .frame(maxWidth: 80, maxHeight: 3)
                                .padding(.top, 16)

            ZStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 14) {


                    HStack(alignment: .top, spacing: 5) {
                        Text("🔑")
                            .font(.system(size: 14))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Why Full Access?")
                                .font(Font.sfProDisplay(size: 16, weight: .bold))
                                .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Enabling Full Access lets us personalize your keyboard, sync settings, update suggestions, and enable online features.")
                                .font(Font.sfProDisplay(size: 14, weight: .regular))
                                .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(alignment: .top, spacing: 5) {
                        Text("👉")
                            .font(Font.sfProDisplay(size: 14, weight: .semibold))

                        Text("We never collect your typed text or passwords — your privacy is 100% safe.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 32)
            }
            .frame(height: 190)

            Spacer(minLength: 0)
        }
        .background(
            ZStack {
                // Blur backdrop behind the sheet
                BlurView(style: isDarkMode ? .systemMaterialDark : .systemMaterialLight)
                    .ignoresSafeArea()

                // Tint overlay with specified color and opacity
                AppColors.Overlay.sheetBackdrop(isDarkMode: isDarkMode)
                    .ignoresSafeArea()
            }
        )
        .frame(height: sheetHeight)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.height)
                    Logger.debug("onChanged value.translation.height=\(value.translation.height)")
                }
                .onEnded { value in
                    if value.translation.height > dismissThreshold {
                        withAnimation(.easeOut(duration: 0.2)) {
                            onDismiss()
                            dragOffset = 0
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
                    Logger.debug("onEnded value.translation.height=\(value.translation.height)")
                }
        )
    }
}

// MARK: - UIKit Blur in SwiftUI
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
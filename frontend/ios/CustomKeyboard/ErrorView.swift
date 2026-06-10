import SwiftUI

/// A reusable error state view that handles both network and service errors.
/// Shows different icons and messages based on the error type.
struct ErrorView: View {
    enum ErrorType {
        case network
        case service
        case meaninglessText
        case fullAccessDisabled
        case signInRequired
    }

    let errorType: ErrorType
    let onRetry: () -> Void
    let onInfoTap: (() -> Void)?
    let isDarkMode: Bool
    let userSmaller: Bool

    init(
        errorType: ErrorType = .network,
        isDarkMode: Bool = false,
        userSmaller: Bool = false,
        onRetry: @escaping () -> Void,
        onInfoTap: (() -> Void)? = nil
    ) {
        self.errorType = errorType
        self.onRetry = onRetry
        self.onInfoTap = onInfoTap
        self.isDarkMode = isDarkMode
        self.userSmaller = userSmaller
    }

    var body: some View {
       let isLoggedIn = AppGroupManager.shared.isUserLoggedIn()
       var errorType = self.errorType
       if !isLoggedIn && self.errorType != .fullAccessDisabled{
          errorType = .signInRequired
       }
       return VStack(spacing: 8) {
            // Icon
            Group {
                let bundle = Bundle(for: KeyboardViewController.self)
                if errorType == .network {
                    // Network error: Wi-Fi icon
                    if let imagePath = bundle.path(forResource: "ic_wifi", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "wifi.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                } else if errorType == .signInRequired {
                    // Sign-in required: Login icon
                    if let imagePath = bundle.path(forResource: "ic_login", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                } else if errorType == .meaninglessText {
                    // Meaningless text error: Glasses icon
                    if let imagePath = bundle.path(forResource: "ic_glasses", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "eyeglasses")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                } else if errorType == .fullAccessDisabled {
                    // Full access disabled: Broken heart icon
                    if let imagePath = bundle.path(forResource: "ic_heart", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "heart.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                } else {
                    // Service error: Broken heart icon
                    if let imagePath = bundle.path(forResource: "ic_heart", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: imagePath) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "heart.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Messages
            VStack(spacing: 4) {
                if errorType == .network {
                    Text("Hmm... Looks like you're offline...")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Please check your connection.")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)

                } else if errorType == .signInRequired {
                    Text("To use this feature, please sign in to your account or create a new one in few seconds.")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if errorType == .meaninglessText {
                    Text("Hmm, I couldn’t catch any meaningful words here. Can you please try again?")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if errorType == .fullAccessDisabled {
                    Text("It looks like full access isn't enabled.")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Turn it on in your keyboard settings to")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 6){
                    Text("to unlock all features.")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        Group {
                        let bundle = Bundle(for: KeyboardViewController.self)
                        if let imagePath = bundle.path(forResource: "ic_info", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: imagePath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                                .frame(width: 18, height: 18)
                                .padding(.top, 5)

                        } else {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
                        }
                    }.onTapGesture{
                                 onInfoTap!()
                                 }
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Oops! Unfortunately our service is")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("temporarily unavailable. We're fixing it!")
                        .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .light))
                        .foregroundColor(AppColors.Text.secondary(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, alignment: .leading)

                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: userSmaller ? 0 : 8)

            // Retry action
            Button(action: onRetry) {
                Text(errorType == .network ? "Try again" :
                     errorType == .signInRequired ? "Sign in" :
                     errorType == .meaninglessText ? "Try again" :
                     errorType == .fullAccessDisabled ? "Go to Settings" : "Refresh")
                    .font(Font.sfProDisplay(size: userSmaller ? 14 : 16, weight: .medium))
                    .underline()
                    .foregroundColor(AppColors.Text.primary(isDarkMode: isDarkMode))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

        }
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(errorType == .network ? "Offline. Please check your connection." :
                           errorType == .signInRequired ? "Sign in required to use this feature." :
                           errorType == .meaninglessText ? "No meaningful words detected. Please try again." :
                           errorType == .fullAccessDisabled ? "Full access is disabled. Open settings to enable it." :
                           "Service temporarily unavailable. Please refresh.")
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorView(errorType: .network, isDarkMode: false, onRetry: {})
        ErrorView(errorType: .service, isDarkMode: false, onRetry: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

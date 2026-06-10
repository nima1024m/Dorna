import SwiftUI

struct TopBar<ExtraContent: View>: View {
    let title: String
    let icon: String
    let iconSize: CGFloat
    let isDarkMode: Bool
    let onBackTap: () -> Void
    let extraContent: (() -> ExtraContent)?

    init(
        title: String,
        icon: String,
        iconSize: CGFloat = 24,
        isDarkMode: Bool = false,
        onBackTap: @escaping () -> Void,
        extraContent: (() -> ExtraContent)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.iconSize = iconSize
        self.isDarkMode = isDarkMode
        self.onBackTap = onBackTap
        self.extraContent = extraContent
    }

    var body: some View {
        HStack(spacing: 8) {
               // Back button
               Button(action: onBackTap) {
                                   HStack(spacing: 4){

                                       Image(systemName: "chevron.left")
                                           .resizable()
                                           .scaledToFit()
                                           .frame(width: 12, height: 12)
                                           .foregroundColor(.primary)
                                           Group {
                                               let bundle = Bundle(for: KeyboardViewController.self)
                                              if let imagePath = bundle.path(forResource: "ic_keyboard", ofType: "png"),
                                                 let uiImage = UIImage(contentsOfFile: imagePath) {
                                                   Image(uiImage: uiImage)
                                                       .resizable()
                                                       .renderingMode(.template)
                                                       .scaledToFit()
                                                       .frame(width: 20, height: 20)
                                                       .foregroundColor(.primary)
                                               } else {
                                                   // Fallback to system icon
                                                   Image(systemName: "keyboard")
                                                       .resizable()
                                                       .scaledToFit()
                                                       .font(.system(size: 18, weight: .heavy))
                                                       .foregroundColor(isDarkMode ? AppColors.Primary.blue(isDarkMode: isDarkMode) : .primary)
                                               }
                                           }

                                           Spacer().frame(width: 0.1)

                                   }

                               }
                               .padding(.horizontal, 5)
                               .frame(height: 40)
                               .cornerRadius(8)
                               .overlay(
                                   RoundedRectangle(cornerRadius: 8)
                                       .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                               )



                   HStack(spacing: 2) {
                      Group {
                                          let bundle = Bundle(for: KeyboardViewController.self)
                                          if let imagePath = bundle.path(forResource: icon, ofType: "png"),
                                             let uiImage = UIImage(contentsOfFile: imagePath) {
                                              Image(uiImage: uiImage)
                                                  .resizable()
                                                  .frame(width: iconSize, height: iconSize)
                                          } else {
                                              // Fallback to system icon
                                              Image(systemName: "waveform")
                                                  .resizable()
                                                  .frame(width: 24, height: 24)
                                                  .foregroundColor(AppColors.Primary.blue(isDarkMode: isDarkMode))
                                          }
                                      }

                       Text(title)
                           .font(Font.sfProDisplay(size: 14, weight: .bold))
                           .foregroundColor(AppColors.Primary.blue(isDarkMode: isDarkMode))
                   }
               .padding(.horizontal, 12)
               .frame(height: 40)
               .background(AppColors.Primary.blue(isDarkMode: isDarkMode).opacity(0.1))
               .cornerRadius(8)
               .overlay(
                   RoundedRectangle(cornerRadius: 8)
                       .stroke(AppColors.Primary.blue(isDarkMode: isDarkMode), lineWidth: 1)
               )


               Spacer()

              //  Conditionally show the extra content
              if let extraContent = extraContent {
                  extraContent()
                  .frame(height: 40)
              }
              }
              .padding(.horizontal, 16)
              .frame(height: 41)
              .padding(.top, 12)
    }

}

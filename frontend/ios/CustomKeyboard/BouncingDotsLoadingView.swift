import SwiftUI

struct BouncingDotsLoadingView: View {
    let text: String
    let dotSize: CGFloat
    let dotSpacing: CGFloat
    let bounceHeight: CGFloat
    let animationDuration: Double
    let isDarkMode: Bool

    @State private var animate: Bool = false

    init(
        text: String,
        dotSize: CGFloat = 4,
        dotSpacing: CGFloat = 4,
        bounceHeight: CGFloat = 6,
        animationDuration: Double = 0.45,
        isDarkMode: Bool = false
    ) {
        self.text = text
        self.dotSize = dotSize
        self.dotSpacing = dotSpacing
        self.bounceHeight = bounceHeight
        self.animationDuration = animationDuration
        self.isDarkMode = isDarkMode
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(Font.sfProDisplay(size: 16, weight: .light))
                .italic()
                .foregroundColor(AppColors.Loading.dots(isDarkMode: isDarkMode))

            HStack(spacing: dotSpacing) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppColors.Loading.dots(isDarkMode: isDarkMode))
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: animate ? -bounceOffset(for: index) : 0)
                        .animation(
                            .easeInOut(duration: animationDuration)
                                .repeatForever(autoreverses: true)
                                .delay(0.12 * Double(index)),
                            value: animate
                        )
                }
            }
            .padding(.top, 5)
            .accessibilityLabel("Loading")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .onAppear { animate = true }
    }

    private func bounceOffset(for index: Int) -> CGFloat {
        // Middle dot bounces a bit higher for subtle variation
        if index == 1 { return bounceHeight }
        return bounceHeight * 0.75
    }
}

#if DEBUG
struct BouncingDotsLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BouncingDotsLoadingView(text: "Loading", isDarkMode: false)
                .padding()
                .previewLayout(.sizeThatFits)
            BouncingDotsLoadingView(text: "Please wait", dotSize: 8, bounceHeight: 8, isDarkMode: false)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
#endif



import KeyboardKit

extension KeyboardApp {
    static var customKeyboard: KeyboardApp {
        .init(
            name: "CustomKeyboard",
            licenseKey: "",
            appGroupId: "",
            locales: .keyboardKitSupported
        )
    }
} 
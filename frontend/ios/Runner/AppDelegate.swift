import UIKit
import Flutter

// KeyboardManager implementation
@objc class KeyboardManager: NSObject {
    private let appGroupManager = AppGroupManager.shared
    
    // Opens system settings to the keyboard settings page
    @objc func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    // Checks if our custom keyboard is enabled
    @objc func isCustomKeyboardEnabled() -> Bool {
        // Get the main app bundle identifier
        let mainBundleID = Bundle.main.bundleIdentifier ?? ""
        
        // The keyboard extension bundle ID is typically the main app bundle ID + ".CustomKeyboard"
        let keyboardBundleID = mainBundleID + ".CustomKeyboard"
        
        // Also check for the full keyboard extension bundle ID
        let fullKeyboardBundleID = "com.dorna.app.CustomKeyboard"
        
        // Check the AppleKeyboards UserDefaults key for enabled keyboards
        if let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] {
            let isEnabled = keyboards.contains(keyboardBundleID) || keyboards.contains(fullKeyboardBundleID)
            
            print("Debug - Main Bundle ID: \(mainBundleID)")
            print("Debug - Keyboard Bundle ID: \(keyboardBundleID)")
            print("Debug - Full Keyboard Bundle ID: \(fullKeyboardBundleID)")
            print("Debug - Enabled Keyboards: \(keyboards)")
            print("Debug - Is Enabled: \(isEnabled)")
            
            return isEnabled
        }
        
        // If AppleKeyboards is not found, try alternative approach
        // Check if the keyboard extension is installed and accessible
        if let keyboardExtensionBundle = Bundle(identifier: fullKeyboardBundleID) {
            print("Debug - Keyboard extension bundle found: \(keyboardExtensionBundle)")
            return true
        }
        
        // Try to check if the keyboard is in the list of available keyboards
        // This might be stored in a different key
        let allUserDefaultsKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allUserDefaultsKeys {
            if key.contains("Keyboard") || key.contains("keyboard") {
                if let value = UserDefaults.standard.object(forKey: key) {
                    print("Debug - Found keyboard-related key: \(key) = \(value)")
                }
            }
        }
        
        print("Debug - Main Bundle ID: \(mainBundleID)")
        print("Debug - Keyboard Bundle ID: \(keyboardBundleID)")
        print("Debug - Full Keyboard Bundle ID: \(fullKeyboardBundleID)")
        print("Debug - AppleKeyboards not found in UserDefaults")
        print("Debug - Is Enabled: false")
        
        return false
    }
    
    // Checks if our custom keyboard is currently selected/active
    @objc func isCustomKeyboardSelected() -> Bool {
        // Use app group to check keyboard selection status
        // The keyboard extension will write its active status to shared UserDefaults
        if let isActive = appGroupManager.getKeyboardActiveStatus() {
            print("Debug - Keyboard active status from shared UserDefaults: \(isActive)")
            return isActive
        } else {
            print("Debug - No keyboard active status found in shared UserDefaults")
        }
        
        // Fallback: Try to check using UserDefaults (less reliable)
        let selectedKeyboard = UserDefaults.standard.object(forKey: "AppleCurrentKeyboard") as? String
        
        // Get the main app bundle identifier
        let mainBundleID = Bundle.main.bundleIdentifier ?? ""
        
        // The keyboard extension bundle ID is typically the main app bundle ID + ".CustomKeyboard"
        let keyboardBundleID = mainBundleID + ".CustomKeyboard"
        
        // Also check for the full keyboard extension bundle ID
        let fullKeyboardBundleID = "com.dorna.app.CustomKeyboard"
        
        // Check if either bundle ID matches the selected keyboard
        let isSelected = selectedKeyboard == keyboardBundleID || selectedKeyboard == fullKeyboardBundleID
        
        print("Debug - Fallback - Selected Keyboard: \(selectedKeyboard ?? "nil")")
        print("Debug - Fallback - Is Selected: \(isSelected)")
        
        return isSelected
    }
    @objc func isCustomKeyboardSelectedRawCheck() -> Bool {
        // Fallback: Try to check using UserDefaults (less reliable)
        let selectedKeyboard = UserDefaults.standard.object(forKey: "AppleCurrentKeyboard") as? String

        // Get the main app bundle identifier
        let mainBundleID = Bundle.main.bundleIdentifier ?? ""

        // The keyboard extension bundle ID is typically the main app bundle ID + ".CustomKeyboard"
        let keyboardBundleID = mainBundleID + ".CustomKeyboard"

        // Also check for the full keyboard extension bundle ID
        let fullKeyboardBundleID = "com.dorna.app.CustomKeyboard"

        // Check if either bundle ID matches the selected keyboard
        let isSelected = selectedKeyboard == keyboardBundleID || selectedKeyboard == fullKeyboardBundleID

        print("Debug - Fallback - Selected Keyboard: \(selectedKeyboard ?? "nil")")
        print("Debug - Fallback - Is Selected: \(isSelected)")

        return isSelected
    }


    // Checks full access using UIInputViewController API directly
    @objc func hasFullAccessByUIInputViewController() -> Bool {
        // Note: This approach only reflects full access when relevant to the context.
        // It follows the requested pattern using UIInputViewController().hasFullAccess
        let controller = UIInputViewController()
        let access = controller.hasFullAccess
        print("Debug - UIInputViewController hasFullAccess: \(access)")
        return access
    }
    
    // Gets debug information about keyboard status
    @objc func getKeyboardDebugInfo() -> [String: Any] {
        let mainBundleID = Bundle.main.bundleIdentifier ?? ""
        let keyboardBundleID = mainBundleID + ".CustomKeyboard"
        let fullKeyboardBundleID = "com.dorna.app.CustomKeyboard"
        
        let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        let selectedKeyboard = UserDefaults.standard.object(forKey: "AppleCurrentKeyboard") as? String
        
        return [
            "mainBundleID": mainBundleID,
            "keyboardBundleID": keyboardBundleID,
            "fullKeyboardBundleID": fullKeyboardBundleID,
            "enabledKeyboards": keyboards,
            "selectedKeyboard": selectedKeyboard ?? "nil",
        ]
    }
    
    // Gets the current selected keyboard name
    @objc func getCurrentSelectedKeyboardName() -> String {
        // This only works when the keyboard is visible.
        // Use UITextInputMode to fetch the currently displayed input mode's display name.
        var keyboardName = "No Keyboard Selected"

        let computeName: () -> Void = {
            let activeModes = UITextInputMode.activeInputModes
            let predicate = NSPredicate(format: "isDisplayed = YES")
            let displayed = (activeModes as NSArray).filtered(using: predicate)

            if let currentMode = displayed.last as? UITextInputMode {
                if let name = currentMode.value(forKey: "extendedDisplayName") as? String, !name.isEmpty {
                    keyboardName = name
                } else if let name = currentMode.value(forKey: "displayName") as? String, !name.isEmpty {
                    keyboardName = name
                } else if let lang = currentMode.primaryLanguage {
                    keyboardName = lang
                }
            } else {
                // Fallback to previously used approach only if needed
                if let selectedKeyboard = UserDefaults.standard.object(forKey: "AppleCurrentKeyboard") as? String, !selectedKeyboard.isEmpty {
                    keyboardName = selectedKeyboard
                }
            }
        }

        if Thread.isMainThread {
            computeName()
        } else {
            DispatchQueue.main.sync { computeName() }
        }

        print("Debug - Current displayed keyboard name: \(keyboardName)")
        return keyboardName
    }
    
    // Force refresh full access status by clearing cached value
    @objc func refreshFullAccessStatus() {
        appGroupManager.clearFullAccessStatus()
        
        // Also write a flag to force the keyboard extension to re-check
        appGroupManager.setForceRecheckFullAccess()
        
        // Force immediate re-check by writing a timestamp
        appGroupManager.setLastRecheckRequest()
    }
    
    // Force refresh keyboard selection status
    @objc func refreshKeyboardSelectionStatus() {
        appGroupManager.clearKeyboardActiveStatus()
        
        // Write a flag to force the keyboard extension to re-check
        appGroupManager.setForceRecheckKeyboardSelection()
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let keyboardManager = KeyboardManager()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for keyboard operations
    setupMethodChannels()
    
    // Add observer for app becoming active to check full access status
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
        // Make sure the window and root view don't force an opaque backdrop.
        if let win = self.window {
          win.isOpaque = false
          win.backgroundColor = .clear
          if let flutterVC = win.rootViewController as? FlutterViewController {
            flutterVC.view.isOpaque = false
            flutterVC.view.backgroundColor = .clear
          }
        }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupMethodChannels() {
    let controller = window?.rootViewController as! FlutterViewController
    let keyboardChannel = FlutterMethodChannel(
      name: "com.dorna.app/keyboard",
      binaryMessenger: controller.binaryMessenger
    )
    
    keyboardChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      switch call.method {
        case "setCollectData":
        if let args = call.arguments as? [String: Any],
           let enabled = args["enabled"] as? Bool {
            AppGroupManager.shared.setCollectDataConsent(enabled)
            print("Flutter requested setCollectData: \(enabled)")
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "enabled is required", details: nil))
        }

      case "setAutoCorrectionEnabled":
        if let args = call.arguments as? [String: Any],
           let enabled = args["enabled"] as? Bool {
            AppGroupManager.shared.setAutoCorrectionEnabled(enabled)
            print("Flutter requested setAutoCorrectionEnabled: \(enabled)")
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "enabled is required", details: nil))
        }
        
      case "openKeyboardSettings":
        self.keyboardManager.openKeyboardSettings()
        result(nil)
        
      case "isCustomKeyboardEnabled":
        let isEnabled = self.keyboardManager.isCustomKeyboardEnabled()
        print("Flutter requested isCustomKeyboardEnabled, returning: \(isEnabled)")
        result(isEnabled)
        
      case "isCustomKeyboardSelected":
        let isSelected = self.keyboardManager.isCustomKeyboardSelected()
        print("Flutter requested isCustomKeyboardSelected, returning: \(isSelected)")
        result(isSelected)

      case "isCustomKeyboardSelectedRawCheck":
        let isSelected = self.keyboardManager.isCustomKeyboardSelectedRawCheck()
        print("Flutter requested isCustomKeyboardSelectedRawCheck, returning: \(isSelected)")
        result(isSelected)

      case "hasFullAccessByUIInputViewController":
        let hasAccess = self.keyboardManager.hasFullAccessByUIInputViewController()
        print("Flutter requested hasFullAccessByUIInputViewController, returning: \(hasAccess)")
        result(hasAccess)
        
      case "getKeyboardDebugInfo":
        let debugInfo = self.keyboardManager.getKeyboardDebugInfo()
        print("Flutter requested getKeyboardDebugInfo, returning: \(debugInfo)")
        result(debugInfo)

      case "getCurrentSelectedKeyboardName":
        // Delay to next runloop to allow system to update input mode
        DispatchQueue.main.async {
          let keyboardName = self.keyboardManager.getCurrentSelectedKeyboardName()
          print("Flutter requested getCurrentSelectedKeyboardName, returning: \(keyboardName)")
          result(keyboardName)
        }
        
             case "refreshFullAccessStatus":
         self.keyboardManager.refreshFullAccessStatus()
         print("Flutter requested refreshFullAccessStatus")
         result(nil)
         
       case "refreshKeyboardSelectionStatus":
         self.keyboardManager.refreshKeyboardSelectionStatus()
         print("Flutter requested refreshKeyboardSelectionStatus")
         result(nil)
         
      case "testUserDefaultsAccess":
         let canWrite = AppGroupManager.shared.canWriteToSharedDefaults()
         print("Flutter requested testUserDefaultsAccess, returning: \(canWrite)")
         result(canWrite)
         
      case "clearAppGroupData":
         AppGroupManager.shared.clearAllAppGroupData()
         print("Flutter requested clearAppGroupData")
         result(nil)
         
      case "getFavoriteTones":
         let favorites = AppGroupManager.shared.getFavoriteTones()
         print("Flutter requested getFavoriteTones, returning: \(favorites)")
         result(favorites)
         
      case "addFavoriteTone":
         if let args = call.arguments as? [String: Any],
            let toneName = args["toneName"] as? String {
             AppGroupManager.shared.addFavoriteTone(toneName)
             print("Flutter requested addFavoriteTone: \(toneName)")
             result(nil)
         } else {
             result(FlutterError(code: "INVALID_ARGUMENTS", message: "toneName is required", details: nil))
         }
         
      case "removeFavoriteTone":
         if let args = call.arguments as? [String: Any],
            let toneName = args["toneName"] as? String {
             AppGroupManager.shared.removeFavoriteTone(toneName)
             print("Flutter requested removeFavoriteTone: \(toneName)")
             result(nil)
         } else {
             result(FlutterError(code: "INVALID_ARGUMENTS", message: "toneName is required", details: nil))
         }
         
      case "saveTokens":
         if let args = call.arguments as? [String: Any],
            let accessToken = args["accessToken"] as? String,
            let refreshToken = args["refreshToken"] as? String {
             let timestamp = args["timestamp"] as? Double
             AppGroupManager.shared.saveTokens(accessToken: accessToken, refreshToken: refreshToken, timestamp: timestamp)
             print("Flutter requested saveTokens with timestamp: \(timestamp ?? Date().timeIntervalSince1970)")
             result(nil)
         } else {
             result(FlutterError(code: "INVALID_ARGUMENTS", message: "accessToken and refreshToken are required", details: nil))
         }
         
      case "getAccessToken":
         let token = AppGroupManager.shared.getAccessToken()
         print("Flutter requested getAccessToken, returning: \(token != nil ? "***" : "nil")")
         result(token)
         
      case "getRefreshToken":
         let token = AppGroupManager.shared.getRefreshToken()
         print("Flutter requested getRefreshToken, returning: \(token != nil ? "***" : "nil")")
         result(token)
         
      case "getTokenTimestamp":
         let timestamp = AppGroupManager.shared.getTokenTimestamp()
         print("Flutter requested getTokenTimestamp, returning: \(timestamp ?? 0)")
         result(timestamp)
         
      case "clearTokens":
         AppGroupManager.shared.clearTokens()
         print("Flutter requested clearTokens")
         result(nil)
         
      case "setFullAccessStatus":
         if let args = call.arguments as? [String: Any],
            let hasFullAccess = args["hasFullAccess"] as? Bool {
             AppGroupManager.shared.setFullAccessStatus(hasFullAccess)
             print("Flutter requested setFullAccessStatus: \(hasFullAccess)")
             result(nil)
         } else {
             result(FlutterError(code: "INVALID_ARGUMENTS", message: "hasFullAccess is required", details: nil))
         }
         default:
         break
         
       }
     }
   }
   
       @objc private func appDidBecomeActive() {
      // When app becomes active, force a refresh of both statuses
      // This helps detect changes when user returns from Settings
      keyboardManager.refreshFullAccessStatus()
      keyboardManager.refreshKeyboardSelectionStatus()
    }
 }

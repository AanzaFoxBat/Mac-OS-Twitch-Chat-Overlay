import Foundation
import AppKit

enum ChatTextSize: Int, CaseIterable {
    case small = 0
    case medium = 1
    case large = 2

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var fontSize: Int {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let windowFrame = "windowFrame"
        static let twitchChatURL = "twitchChatURL"
        static let backgroundOpacity = "backgroundOpacity"
        static let contentOpacity = "contentOpacity"
        static let minimalChatStyle = "minimalChatStyle"
        static let chatTextSize = "chatTextSize"
        static let advancedOptionsEnabled = "advancedOptionsEnabled"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let chatFontFamily = "chatFontFamily"
        static let alertKeywords = "alertKeywords"
        static let alertHighlightColor = "alertHighlightColor"
    }

    // MARK: - Persisted Settings

    var windowFrame: NSRect? {
        get {
            guard let data = defaults.data(forKey: Keys.windowFrame),
                  let rect = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: data) else {
                return nil
            }
            return rect.rectValue
        }
        set {
            if let newValue = newValue {
                let value = NSValue(rect: newValue)
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true) {
                    defaults.set(data, forKey: Keys.windowFrame)
                }
            } else {
                defaults.removeObject(forKey: Keys.windowFrame)
            }
        }
    }

    @Published var twitchChatURL: String {
        didSet {
            defaults.set(twitchChatURL, forKey: Keys.twitchChatURL)
        }
    }

    @Published var backgroundOpacity: Double {
        didSet {
            defaults.set(backgroundOpacity, forKey: Keys.backgroundOpacity)
        }
    }

    @Published var contentOpacity: Double {
        didSet {
            defaults.set(contentOpacity, forKey: Keys.contentOpacity)
        }
    }

    @Published var minimalChatStyle: Bool {
        didSet {
            defaults.set(minimalChatStyle, forKey: Keys.minimalChatStyle)
        }
    }

    @Published var chatTextSize: ChatTextSize {
        didSet {
            defaults.set(chatTextSize.rawValue, forKey: Keys.chatTextSize)
        }
    }

    @Published var advancedOptionsEnabled: Bool {
        didSet {
            defaults.set(advancedOptionsEnabled, forKey: Keys.advancedOptionsEnabled)
        }
    }

    @Published var hotkeyKeyCode: UInt16 {
        didSet {
            defaults.set(Int(hotkeyKeyCode), forKey: Keys.hotkeyKeyCode)
        }
    }

    @Published var hotkeyModifiers: UInt {
        didSet {
            defaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers)
        }
    }

    @Published var chatFontFamily: String {
        didSet {
            defaults.set(chatFontFamily, forKey: Keys.chatFontFamily)
        }
    }

    @Published var alertKeywords: [String] {
        didSet {
            defaults.set(alertKeywords, forKey: Keys.alertKeywords)
        }
    }

    @Published var alertHighlightColor: String {
        didSet {
            defaults.set(alertHighlightColor, forKey: Keys.alertHighlightColor)
        }
    }

    // MARK: - Non-persisted Settings (always default on launch)

    @Published var clickThroughEnabled: Bool = false

    // MARK: - Initialization

    private init() {
        self.twitchChatURL = defaults.string(forKey: Keys.twitchChatURL) ?? ""
        self.backgroundOpacity = defaults.object(forKey: Keys.backgroundOpacity) as? Double ?? 0.5
        self.contentOpacity = defaults.object(forKey: Keys.contentOpacity) as? Double ?? 1.0
        self.minimalChatStyle = defaults.object(forKey: Keys.minimalChatStyle) as? Bool ?? false
        let sizeRaw = defaults.object(forKey: Keys.chatTextSize) as? Int ?? ChatTextSize.medium.rawValue
        self.chatTextSize = ChatTextSize(rawValue: sizeRaw) ?? .medium

        // Advanced options
        self.advancedOptionsEnabled = defaults.object(forKey: Keys.advancedOptionsEnabled) as? Bool ?? false
        self.hotkeyKeyCode = UInt16(defaults.object(forKey: Keys.hotkeyKeyCode) as? Int ?? 10) // kVK_ISO_Section
        self.hotkeyModifiers = defaults.object(forKey: Keys.hotkeyModifiers) as? UInt ?? NSEvent.ModifierFlags.control.rawValue
        self.chatFontFamily = defaults.string(forKey: Keys.chatFontFamily) ?? "System"
        self.alertKeywords = defaults.object(forKey: Keys.alertKeywords) as? [String] ?? []
        self.alertHighlightColor = defaults.string(forKey: Keys.alertHighlightColor) ?? "#FFFF00"
    }

    // MARK: - First Launch Detection

    var isFirstLaunch: Bool {
        return defaults.object(forKey: Keys.windowFrame) == nil
    }
}

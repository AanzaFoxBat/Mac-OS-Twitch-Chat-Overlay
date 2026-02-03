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
    }

    // MARK: - First Launch Detection

    var isFirstLaunch: Bool {
        return defaults.object(forKey: Keys.windowFrame) == nil
    }
}

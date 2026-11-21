import Foundation

public enum MategramKey: String, CaseIterable {
    case showProfileId
    case showDataCenter
    case showMutualContact
    case showRegistrationDate
    case hideStarRating
    case preciseLastSeen
    case timeSeconds
    case fullViewCount
    case hideStoriesBar
    case hideChatsTitle
    case confirmCalls
    case openLinksExternal
    case hidePremiumRow
    case hideStarsRow
    case hideTonRow
    case hideBusinessRow
    case hideGiftRow
    case hideAppsRow
    case hideTipsRow
    case cameraInGallery
    case roundProfileButtons

    public var defaultValue: Bool {
        switch self {
        case .showProfileId, .showDataCenter, .showRegistrationDate, .preciseLastSeen, .roundProfileButtons:
            return true
        default:
            return false
        }
    }
}

public final class MategramSettings {
    public static let shared = MategramSettings()
    public static let didChangeNotification = Notification.Name("MategramSettingsDidChange")

    private let defaults: UserDefaults

    private init() {
        self.defaults = UserDefaults.standard
        var registered: [String: Any] = [:]
        for key in MategramKey.allCases {
            registered[MategramSettings.storageKey(key)] = key.defaultValue
        }
        self.defaults.register(defaults: registered)
    }

    private static func storageKey(_ key: MategramKey) -> String {
        return "mategram.\(key.rawValue)"
    }

    public func bool(_ key: MategramKey) -> Bool {
        return self.defaults.bool(forKey: MategramSettings.storageKey(key))
    }

    public func set(_ value: Bool, for key: MategramKey) {
        self.defaults.set(value, forKey: MategramSettings.storageKey(key))
        NotificationCenter.default.post(name: MategramSettings.didChangeNotification, object: nil)
    }
}

public enum MategramCallGate {
    private static var allowed = false

    public static func allowNext() {
        allowed = true
    }

    public static func consume() -> Bool {
        let value = allowed
        allowed = false
        return value
    }
}

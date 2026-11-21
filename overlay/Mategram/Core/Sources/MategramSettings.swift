import Foundation

public enum MategramKey: String, CaseIterable {
    case showProfileId
    case showDataCenter
    case showMutualContact
    case showRegistrationDate
    case preciseLastSeen

    public var defaultValue: Bool {
        switch self {
        case .showProfileId, .showDataCenter, .showRegistrationDate, .preciseLastSeen:
            return true
        case .showMutualContact:
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

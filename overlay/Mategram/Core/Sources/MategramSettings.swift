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
    case ghostMode
    case ghostRead
    case ghostTyping
    case ghostOnline
    case ghostStories
    case ghostContents
    case ghostAlwaysOnline
    case hideReactions
    case sendOnReturn
    case hideSendAs
    case zalgoFilter
    case menuSaveToSaved
    case hideBusinessBotPanel
    case hideProxySponsor
    case disableChatSwipes
    case hidePhone
    case showSessionApiId
    case wordFilter
    case hideTabTitles
    case noAutoplayNextVoice
    case googleTranslate

    public var defaultValue: Bool {
        switch self {
        case .showProfileId, .showDataCenter, .showRegistrationDate, .preciseLastSeen, .roundProfileButtons, .ghostRead, .ghostTyping, .ghostOnline, .ghostStories, .ghostContents:
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

public enum MategramTextKey: String, CaseIterable {
    case filterWords
}

extension MategramSettings {
    private static func textStorageKey(_ key: MategramTextKey) -> String {
        return "mategram.text.\(key.rawValue)"
    }

    public func text(_ key: MategramTextKey) -> String {
        return UserDefaults.standard.string(forKey: MategramSettings.textStorageKey(key)) ?? ""
    }

    public func setText(_ value: String, for key: MategramTextKey) {
        UserDefaults.standard.set(value, forKey: MategramSettings.textStorageKey(key))
        if key == .filterWords {
            MategramWordFilter.reset()
        }
        NotificationCenter.default.post(name: MategramSettings.didChangeNotification, object: nil)
    }
}

public enum MategramWordFilter {
    private static var cached: [String]?

    static func reset() {
        cached = nil
    }

    private static func words() -> [String] {
        if let cached {
            return cached
        }
        let raw = MategramSettings.shared.text(.filterWords)
        let parts = raw.components(separatedBy: CharacterSet(charactersIn: ",
")).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }
        cached = parts
        return parts
    }

    public static func matches(_ text: String) -> Bool {
        if !MategramSettings.shared.bool(.wordFilter) || text.isEmpty {
            return false
        }
        let list = words()
        if list.isEmpty {
            return false
        }
        let lowered = text.lowercased()
        return list.contains(where: { lowered.contains($0) })
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

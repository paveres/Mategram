import Foundation
import Security

public enum MategramValueKey: String, CaseIterable {
    case sendDelay
    case onlineInterval
    case stickerSize
    case maxPinnedPreview
    case peekDuration
    case crossfadeSeconds
    case autoProxyDelay

    public var defaultValue: Int {
        switch self {
        case .sendDelay:
            return 12
        case .onlineInterval:
            return 30
        case .stickerSize:
            return 70
        case .maxPinnedPreview:
            return 2
        case .peekDuration:
            return 10
        case .crossfadeSeconds:
            return 5
        case .autoProxyDelay:
            return 15
        }
    }

    public var presets: [Int] {
        switch self {
        case .sendDelay:
            return [1, 3, 5, 10, 15, 30, 60, 120, 300, 600]
        case .onlineInterval:
            return [10, 20, 30, 60, 120]
        case .stickerSize:
            return [40, 50, 60, 70, 80, 90, 120, 150]
        case .maxPinnedPreview:
            return [1, 2, 3]
        case .peekDuration:
            return [5, 10, 15, 30, 60]
        case .crossfadeSeconds:
            return [2, 3, 5, 8, 10, 12]
        case .autoProxyDelay:
            return [5, 10, 15, 30, 60]
        }
    }

    public var range: ClosedRange<Int> {
        switch self {
        case .sendDelay:
            return 1 ... 86400
        case .onlineInterval:
            return 5 ... 600
        case .stickerSize:
            return 20 ... 200
        case .maxPinnedPreview:
            return 1 ... 3
        case .peekDuration:
            return 3 ... 600
        case .crossfadeSeconds:
            return 1 ... 30
        case .autoProxyDelay:
            return 3 ... 600
        }
    }

    public var sliderRange: ClosedRange<Int> {
        switch self {
        case .sendDelay:
            return 1 ... 600
        case .onlineInterval:
            return 5 ... 300
        case .stickerSize:
            return 30 ... 200
        case .maxPinnedPreview:
            return 1 ... 3
        case .peekDuration:
            return 3 ... 120
        case .crossfadeSeconds:
            return 1 ... 30
        case .autoProxyDelay:
            return 3 ... 120
        }
    }

    public var parent: MategramKey? {
        switch self {
        case .sendDelay:
            return .ghostDelaySend
        case .onlineInterval:
            return .ghostAlwaysOnline
        case .stickerSize:
            return .smallStickers
        case .peekDuration:
            return .peekOnline
        case .crossfadeSeconds:
            return .musicCrossfade
        case .autoProxyDelay:
            return .autoProxy
        case .maxPinnedPreview:
            return nil
        }
    }

    public func format(_ value: Int, _ language: MategramLanguage) -> String {
        let isRussian = language == .russian
        switch self {
        case .sendDelay, .onlineInterval, .peekDuration, .crossfadeSeconds, .autoProxyDelay:
            if value >= 3600 && value % 3600 == 0 {
                return isRussian ? "\(value / 3600) ч" : "\(value / 3600) h"
            } else if value >= 60 && value % 60 == 0 {
                return isRussian ? "\(value / 60) мин" : "\(value / 60) min"
            } else {
                return isRussian ? "\(value) сек" : "\(value) sec"
            }
        case .stickerSize:
            return "\(value)%"
        case .maxPinnedPreview:
            return "\(value)"
        }
    }
}

public struct MategramValueOption {
    public let key: MategramValueKey
    public let section: MategramSection
    public let titleRu: String
    public let titleEn: String
    public let footerRu: String
    public let footerEn: String

    public func title(_ language: MategramLanguage) -> String {
        return language == .russian ? self.titleRu : self.titleEn
    }

    public func footer(_ language: MategramLanguage) -> String {
        return language == .russian ? self.footerRu : self.footerEn
    }
}

public extension MategramCatalog {
    static let restartKeys: Set<MategramKey> = [
        .hideCallsTab, .hideTabTitles, .hideAllChatsTab, .longAllChats, .compactFolders, .rememberFolder,
        .glassMessages, .glassInlineButtons, .hideStoriesBar, .hideChatsTitle, .singleLinePreview,
        .fastDownload, .fastUpload, .builtInMic, .swipeUpCamera, .swipeUpEditor, .sessionBackup,
        .chatTranslateFree, .appleSpeech, .mutedNameColors, .smallStickers, .hideChatListStatus,
        .hideEmojiStatus, .hideProfileColor, .hideProfileGifts, .proxyLocalDNS, .autoProxy, .ramMonitor,
        .disableChatSwipes, .hideProxySponsor, .hideSponsored, .alwaysHD, .wideChannelPosts, .noDeleteEffect, .hideStickerTime, .noDeleteSwipe, .glassDarker, .transparentMessages, .semiTransparentMessages
    ]

    static func valueOption(for key: MategramKey) -> MategramValueOption? {
        return valueOptions.first(where: { $0.key.parent == key })
    }

    static let valueOptions: [MategramValueOption] = [
        MategramValueOption(key: .sendDelay, section: .ghost, titleRu: "Время задержки", titleEn: "Delay time", footerRu: "Насколько откладывать отправку при включённой задержке.", footerEn: "How long sending is delayed when the delay is on."),
        MategramValueOption(key: .onlineInterval, section: .ghost, titleRu: "Интервал «в сети»", titleEn: "Online interval", footerRu: "Как часто обновлять статус «в сети» для «Всегда в сети».", footerEn: "How often the online status is refreshed for «Always online»."),
        MategramValueOption(key: .peekDuration, section: .ghost, titleRu: "Время подглядывания", titleEn: "Peek duration", footerRu: "Сколько держать «был(а)» открытым при «Подглядеть онлайн».", footerEn: "How long last seen stays open for «Peek last seen»."),
        MategramValueOption(key: .crossfadeSeconds, section: .voice, titleRu: "Длина кроссфейда", titleEn: "Crossfade length", footerRu: "Сколько секунд трек затухает в конце и нарастает в начале.", footerEn: "How many seconds a track fades out at the end and in at the start."),
        MategramValueOption(key: .autoProxyDelay, section: .network, titleRu: "Ожидание автопрокси", titleEn: "Auto proxy wait", footerRu: "Сколько ждать соединения, прежде чем включить или сменить прокси.", footerEn: "How long to wait for a connection before turning on or switching the proxy."),
        MategramValueOption(key: .stickerSize, section: .chat, titleRu: "Размер стикеров", titleEn: "Sticker size", footerRu: "Размер стикеров при включённых маленьких стикерах.", footerEn: "Sticker size when small stickers are on.")
    ]

    static func valueOptions(in section: MategramSection) -> [MategramValueOption] {
        return valueOptions.filter { $0.section == section }
    }
}

extension MategramSettings {
    static func valueStorageKey(_ key: MategramValueKey) -> String {
        return "mategram.value.\(key.rawValue)"
    }

    public func value(_ key: MategramValueKey) -> Int {
        if let number = UserDefaults.standard.object(forKey: MategramSettings.valueStorageKey(key)) as? NSNumber {
            return min(key.range.upperBound, max(key.range.lowerBound, number.intValue))
        }
        return key.defaultValue
    }

    public func setValue(_ value: Int, for key: MategramValueKey) {
        let clamped = min(key.range.upperBound, max(key.range.lowerBound, value))
        UserDefaults.standard.set(clamped, forKey: MategramSettings.valueStorageKey(key))
        MategramVault.save()
        NotificationCenter.default.post(name: MategramSettings.didChangeNotification, object: nil)
    }
}

public enum MategramVault {
    private static let service = "app.mategram.settings"
    private static let account = "settings"
    private static let markerKey = "mategram.vault.marker"

    private static func query() -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    public static func save() {
        UserDefaults.standard.set(true, forKey: markerKey)
        guard let data = MategramBackup.export().data(using: .utf8) else {
            return
        }
        let base = query()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemUpdate(base as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = base
            for (key, value) in attributes {
                item[key] = value
            }
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    static func load() -> String? {
        var request = query()
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func restoreIfNeeded(defaults: UserDefaults) {
        if defaults.bool(forKey: markerKey) {
            return
        }
        defaults.set(true, forKey: markerKey)
        guard let string = load(), let data = string.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], (object["app"] as? String) == "Mategram" else {
            return
        }
        if let flags = object["flags"] as? [String: Bool] {
            for (name, value) in flags where MategramKey(rawValue: name) != nil {
                defaults.set(value, forKey: "mategram.\(name)")
            }
        }
        if let texts = object["texts"] as? [String: String] {
            for (name, value) in texts where MategramTextKey(rawValue: name) != nil {
                defaults.set(value, forKey: "mategram.text.\(name)")
            }
        }
        if let values = object["values"] as? [String: Int] {
            for (name, value) in values where MategramValueKey(rawValue: name) != nil {
                defaults.set(value, forKey: "mategram.value.\(name)")
            }
        }
        if let exceptions = object["ghostExceptions"] as? [NSNumber] {
            defaults.set(exceptions, forKey: "mategram.ghost.exceptions")
        }
    }
}

public enum MategramSecureStore {
    private static let service = "app.mategram.sessions"

    private static func query(_ account: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    public static func set(_ data: Data, account: String) {
        let base = query(account)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(base as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = base
            for (key, value) in attributes {
                item[key] = value
            }
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    public static func get(account: String) -> Data? {
        var request = query(account)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess else {
            return nil
        }
        return result as? Data
    }

    public static func remove(account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}

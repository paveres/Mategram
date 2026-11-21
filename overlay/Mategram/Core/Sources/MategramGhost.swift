import Foundation

public enum MategramGhost {
    private static func active(_ key: MategramKey) -> Bool {
        let settings = MategramSettings.shared
        return settings.bool(.ghostMode) && settings.bool(key)
    }

    private static let exceptionsKey = "mategram.ghost.exceptions"
    private static var exceptionsCache: Set<Int64>?

    private static func exceptions() -> Set<Int64> {
        if let exceptionsCache {
            return exceptionsCache
        }
        let values = (UserDefaults.standard.array(forKey: exceptionsKey) as? [NSNumber]) ?? []
        let set = Set(values.map { $0.int64Value })
        exceptionsCache = set
        return set
    }

    public static func isException(peer: Int64) -> Bool {
        return exceptions().contains(peer)
    }

    public static func setException(peer: Int64, _ value: Bool) {
        var set = exceptions()
        if value {
            set.insert(peer)
        } else {
            set.remove(peer)
        }
        exceptionsCache = set
        UserDefaults.standard.set(set.map { NSNumber(value: $0) }, forKey: exceptionsKey)
    }

    public static func holdsReadReceipt(peer: Int64? = nil) -> Bool {
        if let peer, isException(peer: peer) {
            return false
        }
        return active(.ghostRead)
    }

    public static func holdsTyping(peer: Int64? = nil) -> Bool {
        if let peer, isException(peer: peer) {
            return false
        }
        return active(.ghostTyping)
    }

    public static func holdsOnline() -> Bool {
        return active(.ghostOnline)
    }

    public static func holdsStoryViews() -> Bool {
        return active(.ghostStories)
    }

    public static func holdsContentRead() -> Bool {
        return active(.ghostContents)
    }

    public static func keepsOnline() -> Bool {
        let settings = MategramSettings.shared
        return settings.bool(.ghostMode) && settings.bool(.ghostAlwaysOnline) && !settings.bool(.ghostOnline)
    }
}

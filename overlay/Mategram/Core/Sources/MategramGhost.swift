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

    private static var allowedReads = Set<Int64>()

    public static func allowRead(peer: Int64) {
        allowedReads.insert(peer)
    }

    public static func endAllowRead(peer: Int64) {
        allowedReads.remove(peer)
    }

    public static func holdsReadReceipt(peer: Int64? = nil) -> Bool {
        if let peer, isException(peer: peer) || allowedReads.contains(peer) {
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

    public static func holdsActivity(kind: Int, peer: Int64) -> Bool {
        if isException(peer: peer) {
            return false
        }
        switch kind {
        case 1:
            return active(.ghostHideText)
        case 2:
            return active(.ghostHideRecording)
        case 3:
            return active(.ghostHideUploads)
        case 4:
            return active(.ghostHideStickers)
        default:
            return false
        }
    }

    public static func readsOnReply(peer: Int64) -> Bool {
        return holdsReadReceipt(peer: peer) && MategramSettings.shared.bool(.ghostReadOnReply)
    }

    public static var sendDelay: Int32? {
        return active(.ghostDelaySend) ? 12 : nil
    }

    public static var showsServerReadAction: Bool {
        return active(.ghostRead)
    }
}

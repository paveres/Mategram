import Foundation

public enum MategramGhost {
    private static func active(_ key: MategramKey) -> Bool {
        let settings = MategramSettings.shared
        return settings.bool(.ghostMode) && settings.bool(key)
    }

    public static func holdsReadReceipt() -> Bool {
        return active(.ghostRead)
    }

    public static func holdsTyping() -> Bool {
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
}

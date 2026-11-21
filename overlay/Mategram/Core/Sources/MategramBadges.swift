import Foundation

public enum MategramBadges {
    private static let lock = NSLock()
    private static var users: Set<Int64> = [37203514]
    private static var emojiId: Int64 = 5767273250321079194
    private static var loaded = false
    private static var lastRefresh: TimeInterval = 0
    private static let cacheKey = "mategram.badges.cache"
    private static let source = "https://raw.githubusercontent.com/paveres/Mategram/main/badges/users.json"

    private static func apply(data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        var newUsers: Set<Int64> = []
        if let list = object["users"] as? [Any] {
            for value in list {
                if let number = value as? NSNumber {
                    newUsers.insert(number.int64Value)
                }
            }
        }
        var newEmoji: Int64?
        if let text = object["emojiId"] as? String, let value = Int64(text) {
            newEmoji = value
        } else if let number = object["emojiId"] as? NSNumber {
            newEmoji = number.int64Value
        }
        lock.lock()
        users = newUsers
        if let newEmoji {
            emojiId = newEmoji
        }
        lock.unlock()
        return true
    }

    private static func prepare() {
        lock.lock()
        let needsLoad = !loaded
        loaded = true
        let now = Date().timeIntervalSince1970
        let needsRefresh = now - lastRefresh > 3600
        if needsRefresh {
            lastRefresh = now
        }
        lock.unlock()

        if needsLoad, let cached = UserDefaults.standard.data(forKey: cacheKey) {
            _ = apply(data: cached)
        }
        if needsRefresh, let url = URL(string: source) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 15.0
            URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let data, let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    return
                }
                if apply(data: data) {
                    UserDefaults.standard.set(data, forKey: cacheKey)
                }
            }.resume()
        }
    }

    public static func emojiFileId(userId: Int64) -> Int64? {
        prepare()
        lock.lock()
        defer { lock.unlock() }
        return users.contains(userId) ? emojiId : nil
    }
}

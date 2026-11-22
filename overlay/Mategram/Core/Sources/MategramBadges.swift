import Foundation

public struct MategramRole: Equatable {
    public let key: String
    public let text: String
    public let emojiId: Int64?
}

public enum MategramBadges {
    private static let lock = NSLock()
    private static var users: [Int64: Int64] = [37203514: 0]
    private static var signatures: [Int64: String] = [:]
    private static var roles: [Int64: (key: String, text: String?, emojiId: Int64?)] = [:]
    private static var catalog: [String: (ru: String, en: String, emojiId: Int64?)] = [:]
    private static var defaultEmojiId: Int64 = 5771816900518489704
    private static var loaded = false
    private static var lastRefresh: TimeInterval = 0
    private static let cacheKey = "mategram.badges.cache.v3"
    private static let source = "https://api.mates.wtf/v1/marks"
    static let eventsSource = "https://api.mates.wtf/v1/live"

    private static func parseId(_ value: Any?) -> Int64? {
        if let text = value as? String {
            return Int64(text)
        }
        if let number = value as? NSNumber {
            return number.int64Value
        }
        return nil
    }

    private static func apply(data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let list = object["badges"] as? [[String: Any]] else {
            return false
        }
        var newUsers: [Int64: Int64] = [:]
        var newSignatures: [Int64: String] = [:]
        var newRoles: [Int64: (key: String, text: String?, emojiId: Int64?)] = [:]
        for row in list {
            guard let userId = parseId(row["userId"]) else {
                continue
            }
            if hasBadge(row) {
                newUsers[userId] = parseId(row["emojiId"]) ?? 0
            }
            if let role = parseRole(row) {
                newRoles[userId] = role
            }
            if let signature = row["signature"] as? String, !signature.isEmpty {
                newSignatures[userId] = signature
            }
        }
        var newCatalog: [String: (ru: String, en: String, emojiId: Int64?)] = [:]
        if let rolesObject = object["roles"] as? [String: [String: Any]] {
            for (key, value) in rolesObject {
                let ru = value["ru"] as? String ?? key
                newCatalog[key] = (ru: ru, en: value["en"] as? String ?? ru, emojiId: parseId(value["emojiId"]))
            }
        }
        lock.lock()
        users = newUsers
        signatures = newSignatures
        roles = newRoles
        if !newCatalog.isEmpty {
            catalog = newCatalog
        }
        if let value = parseId(object["defaultEmojiId"]), value != 0 {
            defaultEmojiId = value
        }
        lock.unlock()
        return true
    }

    private static func hasBadge(_ row: [String: Any]) -> Bool {
        if let flag = row["badge"] as? Bool {
            return flag
        }
        if let flag = row["badge"] as? NSNumber {
            return flag.boolValue
        }
        return row["role"] == nil
    }

    private static func parseRole(_ row: [String: Any]) -> (key: String, text: String?, emojiId: Int64?)? {
        guard let key = row["role"] as? String, !key.isEmpty else {
            return nil
        }
        let text = (row["roleText"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return (key: key, text: text, emojiId: parseId(row["roleEmojiId"]))
    }

    static func applyEvent(userId: Int64, badge: [String: Any]?) {
        lock.lock()
        if let badge, let role = parseRole(badge) {
            roles[userId] = role
        } else {
            roles.removeValue(forKey: userId)
        }
        if let badge, !hasBadge(badge) {
            users.removeValue(forKey: userId)
            if let signature = badge["signature"] as? String, !signature.isEmpty {
                signatures[userId] = signature
            } else {
                signatures.removeValue(forKey: userId)
            }
        } else if let badge {
            users[userId] = parseId(badge["emojiId"]) ?? 0
            if let signature = badge["signature"] as? String, !signature.isEmpty {
                signatures[userId] = signature
            } else {
                signatures.removeValue(forKey: userId)
            }
        } else {
            users.removeValue(forKey: userId)
            signatures.removeValue(forKey: userId)
        }
        lock.unlock()
        NotificationCenter.default.post(name: MategramSettings.didChangeNotification, object: nil)
    }

    static func refresh(force: Bool) {
        lock.lock()
        let now = Date().timeIntervalSince1970
        let needsRefresh = force || now - lastRefresh > 300
        if needsRefresh {
            lastRefresh = now
        }
        lock.unlock()
        guard needsRefresh, let url = URL(string: source) else {
            return
        }
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

    private static func prepare() {
        lock.lock()
        let needsLoad = !loaded
        loaded = true
        lock.unlock()
        if needsLoad {
            if let cached = UserDefaults.standard.data(forKey: cacheKey) {
                _ = apply(data: cached)
            }
            MategramBadgeStream.shared.start()
        }
        refresh(force: false)
    }

    public static func emojiFileId(userId: Int64) -> Int64? {
        prepare()
        lock.lock()
        defer { lock.unlock() }
        guard let emoji = users[userId] else {
            return nil
        }
        return emoji != 0 ? emoji : defaultEmojiId
    }

    public static func role(userId: Int64, russian: Bool) -> MategramRole? {
        prepare()
        lock.lock()
        defer { lock.unlock() }
        guard let role = roles[userId] else {
            return nil
        }
        let entry = catalog[role.key] ?? defaultCatalog[role.key]
        let text = role.text ?? (russian ? entry?.ru : entry?.en) ?? role.key
        return MategramRole(key: role.key, text: text, emojiId: role.emojiId ?? entry?.emojiId)
    }

    private static let defaultCatalog: [String: (ru: String, en: String, emojiId: Int64?)] = [
        "owner": (ru: "Владелец клиента MateGram", en: "MateGram owner", emojiId: 5807868868886009920),
        "coowner": (ru: "Со-владелец клиента MateGram", en: "MateGram co-owner", emojiId: 5807465992363710697),
        "developer": (ru: "Разработчик клиента MateGram", en: "MateGram developer", emojiId: 5931415565955503486),
        "coder": (ru: "Кодер клиента MateGram", en: "MateGram coder", emojiId: 5879841310902324730),
        "beta": (ru: "Бета-тестер клиента MateGram", en: "MateGram beta tester", emojiId: 5213073897628378814),
        "sponsor": (ru: "Спонсор клиента MateGram", en: "MateGram sponsor", emojiId: 5994453058656931434)
    ]

    public static func signature(userId: Int64) -> String? {
        prepare()
        lock.lock()
        defer { lock.unlock() }
        return signatures[userId]
    }
}

final class MategramBadgeStream: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    static let shared = MategramBadgeStream()

    private let queue = OperationQueue()
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var buffer = Data()
    private var lastEventId: String?
    private var failures = 0
    private var started = false

    override init() {
        self.queue.maxConcurrentOperationCount = 1
        super.init()
    }

    func start() {
        self.queue.addOperation { [weak self] in
            guard let self, !self.started else {
                return
            }
            self.started = true
            self.connect()
        }
    }

    private func connect() {
        guard let url = URL(string: MategramBadges.eventsSource) else {
            return
        }
        if self.session == nil {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 90.0
            configuration.timeoutIntervalForResource = 60.0 * 60.0 * 24.0
            self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: self.queue)
        }
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let lastEventId = self.lastEventId {
            request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-ID")
        }
        self.buffer = Data()
        let task = self.session?.dataTask(with: request)
        self.task = task
        task?.resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.failures = 0
        self.buffer.append(data)
        self.parse()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.task = nil
        self.failures = min(self.failures + 1, 10)
        let delay = min(3.0 * Double(self.failures), 30.0)
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.queue.addOperation {
                self?.connect()
            }
        }
    }

    private func parse() {
        let separator = Data("\n\n".utf8)
        while let range = self.buffer.range(of: separator) {
            let block = self.buffer.subdata(in: self.buffer.startIndex ..< range.lowerBound)
            self.buffer.removeSubrange(self.buffer.startIndex ..< range.upperBound)
            guard let text = String(data: block, encoding: .utf8) else {
                continue
            }
            var name = ""
            var payload = ""
            for rawLine in text.components(separatedBy: "\n") {
                let line = rawLine.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
                if line.hasPrefix("event:") {
                    name = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("data:") {
                    payload += String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("id:") {
                    self.lastEventId = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
            }
            self.handle(name: name, payload: payload)
        }
    }

    private func handle(name: String, payload: String) {
        guard let data = payload.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        if name == "hello" {
            if (object["resync"] as? Bool) == true {
                MategramBadges.refresh(force: true)
            }
            return
        }
        guard name == "badge" else {
            return
        }
        let userId: Int64?
        if let number = object["userId"] as? NSNumber {
            userId = number.int64Value
        } else if let text = object["userId"] as? String {
            userId = Int64(text)
        } else {
            userId = nil
        }
        guard let userId else {
            return
        }
        MategramBadges.applyEvent(userId: userId, badge: object["badge"] as? [String: Any])
    }
}

public enum MategramInstalls {
    private static let key = "mategram.installs.sent"

    public static func hello(userId: Int64) {
        guard userId > 0, let url = URL(string: "https://api.mates.wtf/v1/hello") else {
            return
        }
        var sent = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        let now = Date().timeIntervalSince1970
        let build = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0
        let marker = "\(userId)"
        if let last = sent[marker], now - last < 6.0 * 3600.0, UserDefaults.standard.integer(forKey: key + ".build") == build {
            return
        }
        sent[marker] = now
        UserDefaults.standard.set(sent, forKey: key)
        UserDefaults.standard.set(build, forKey: key + ".build")
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["users": [userId], "build": build, "version": version])
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if (response as? HTTPURLResponse)?.statusCode != 200 {
                var current = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
                current.removeValue(forKey: marker)
                UserDefaults.standard.set(current, forKey: key)
            }
        }.resume()
    }
}

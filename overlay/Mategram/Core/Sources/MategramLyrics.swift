import Foundation

public struct MategramLyricLine {
    public let timestamp: Double
    public let text: String

    public init(timestamp: Double, text: String) {
        self.timestamp = timestamp
        self.text = text
    }
}

public struct MategramLyrics {
    public let lines: [MategramLyricLine]
    public let plain: String?
    public let isApproximate: Bool

    public init(lines: [MategramLyricLine], plain: String?, isApproximate: Bool) {
        self.lines = lines
        self.plain = plain
        self.isApproximate = isApproximate
    }

    public var isSynced: Bool {
        return self.lines.count > 1
    }

    public func activeIndex(at time: Double) -> Int? {
        if self.lines.isEmpty {
            return nil
        }
        var low = 0
        var high = self.lines.count - 1
        var result: Int?
        while low <= high {
            let mid = (low + high) / 2
            if self.lines[mid].timestamp <= time {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    public func spokenFraction(lineIndex: Int, at time: Double, duration: Double) -> Double {
        guard lineIndex >= 0 && lineIndex < self.lines.count else {
            return 0.0
        }
        let start = self.lines[lineIndex].timestamp
        var end = lineIndex + 1 < self.lines.count ? self.lines[lineIndex + 1].timestamp : (duration > start ? duration : start + 5.0)
        let words = max(1, self.lines[lineIndex].text.split(separator: " ").count)
        end = min(end, start + max(1.5, Double(words) * 0.55))
        if end <= start {
            return 1.0
        }
        return max(0.0, min(1.0, (time - start) / (end - start)))
    }
}

public enum MategramLyricsService {
    private static let lock = NSLock()
    private static var cache: [String: MategramLyrics] = [:]
    private static var misses: [String: TimeInterval] = [:]
    private static let endpoint = "https://api.mates.wtf/v1/lyrics"
    private static let missLifetime: TimeInterval = 600.0

    private static func key(title: String, artist: String, duration: Double) -> String {
        return "\(title.lowercased())|\(artist.lowercased())|\(Int(duration / 2.0))"
    }

    @discardableResult
    public static func fetch(title: String, artist: String, duration: Double, completion: @escaping (MategramLyrics?) -> Void) -> URLSessionDataTask? {
        let cacheKey = key(title: title, artist: artist, duration: duration)
        lock.lock()
        let cached = cache[cacheKey]
        let missedAt = misses[cacheKey]
        lock.unlock()
        if let cached {
            DispatchQueue.main.async {
                completion(cached)
            }
            return nil
        }
        if let missedAt, Date().timeIntervalSince1970 - missedAt < missLifetime {
            DispatchQueue.main.async {
                completion(nil)
            }
            return nil
        }
        guard var components = URLComponents(string: endpoint) else {
            completion(nil)
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "artist", value: artist),
            URLQueryItem(name: "duration", value: String(Int(duration)))
        ]
        guard let url = components.url else {
            completion(nil)
            return nil
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            let lyrics = data.flatMap { parse(data: $0, duration: duration) }
            lock.lock()
            if let lyrics {
                cache[cacheKey] = lyrics
            } else if data != nil {
                misses[cacheKey] = Date().timeIntervalSince1970
            }
            lock.unlock()
            DispatchQueue.main.async {
                completion(lyrics)
            }
        }
        task.resume()
        return task
    }

    private static func parse(data: Data, duration: Double) -> MategramLyrics? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], (object["found"] as? Bool) == true else {
            return nil
        }
        var lines: [MategramLyricLine] = []
        if let synced = object["synced"] as? [[String: Any]] {
            for row in synced {
                let time = (row["timestamp"] as? NSNumber)?.doubleValue ?? 0.0
                let text = (row["text"] as? String) ?? ""
                lines.append(MategramLyricLine(timestamp: time, text: text))
            }
        }
        let plain = (object["plain"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if lines.count > 1 {
            return MategramLyrics(lines: lines, plain: plain, isApproximate: false)
        }
        guard let plain, !plain.isEmpty else {
            return nil
        }
        if let spread = spread(plain: plain, duration: duration) {
            return MategramLyrics(lines: spread, plain: plain, isApproximate: true)
        }
        return MategramLyrics(lines: [], plain: plain, isApproximate: false)
    }

    private static func spread(plain: String, duration: Double) -> [MategramLyricLine]? {
        guard duration > 40.0 else {
            return nil
        }
        let rows = plain.split(separator: "\n", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        let filled = rows.filter { !$0.isEmpty && !($0.hasPrefix("[") && $0.hasSuffix("]")) }
        guard filled.count >= 4 else {
            return nil
        }
        let weights = rows.map { row -> Double in
            return row.isEmpty ? 0.45 : 1.0 + Double(row.count) / 26.0
        }
        let total = weights.reduce(0.0, +)
        guard total > 0.0 else {
            return nil
        }
        let start = duration * 0.05
        let span = duration * 0.90
        var elapsed = 0.0
        var result: [MategramLyricLine] = []
        for (index, row) in rows.enumerated() {
            result.append(MategramLyricLine(timestamp: start + span * (elapsed / total), text: row))
            elapsed += weights[index]
        }
        return result
    }
}

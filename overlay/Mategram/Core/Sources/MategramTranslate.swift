import Foundation

public enum MategramGoogleTranslate {
    public static var isEnabled: Bool {
        return MategramSettings.shared.bool(.googleTranslate)
    }

    @discardableResult
    public static func translate(text: String, toLang: String, completion: @escaping (String?) -> Void) -> URLSessionDataTask? {
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: "auto"),
            URLQueryItem(name: "tl", value: toLang),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: text)
        ]
        guard let url = components?.url else {
            completion(nil)
            return nil
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [Any], let parts = json.first as? [Any] else {
                completion(nil)
                return
            }
            var result = ""
            for part in parts {
                if let segment = part as? [Any], let translated = segment.first as? String {
                    result += translated
                }
            }
            completion(result.isEmpty ? nil : result)
        }
        task.resume()
        return task
    }

    public static func translateAll(_ texts: [String], toLang: String, completion: @escaping ([String?]) -> Void) {
        if texts.isEmpty {
            completion([])
            return
        }
        let box = MategramTranslateBox(count: texts.count)
        let group = DispatchGroup()
        for (index, text) in texts.enumerated() {
            group.enter()
            translate(text: text, toLang: toLang, completion: { translated in
                box.set(index, translated)
                group.leave()
            })
        }
        group.notify(queue: .main) {
            completion(box.values())
        }
    }
}

private final class MategramTranslateBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String?]

    init(count: Int) {
        self.storage = Array(repeating: nil, count: count)
    }

    func set(_ index: Int, _ value: String?) {
        self.lock.lock()
        self.storage[index] = value
        self.lock.unlock()
    }

    func values() -> [String?] {
        self.lock.lock()
        let result = self.storage
        self.lock.unlock()
        return result
    }
}

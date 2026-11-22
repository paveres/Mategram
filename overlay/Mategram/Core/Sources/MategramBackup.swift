import Foundation

public enum MategramBackup {
    public static func export() -> String {
        let settings = MategramSettings.shared
        var flags: [String: Bool] = [:]
        for key in MategramKey.allCases {
            flags[key.rawValue] = settings.bool(key)
        }
        var texts: [String: String] = [:]
        for key in MategramTextKey.allCases {
            texts[key.rawValue] = settings.text(key)
        }
        var values: [String: Int] = [:]
        for key in MategramValueKey.allCases {
            values[key.rawValue] = settings.value(key)
        }
        let exceptions = (UserDefaults.standard.array(forKey: "mategram.ghost.exceptions") as? [NSNumber]) ?? []
        let object: [String: Any] = ["app": "Mategram", "version": 2, "flags": flags, "texts": texts, "values": values, "ghostExceptions": exceptions]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]), let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }

    public static func importSettings(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], (object["app"] as? String) == "Mategram" else {
            return false
        }
        let settings = MategramSettings.shared
        if let flags = object["flags"] as? [String: Bool] {
            for (name, value) in flags {
                if let key = MategramKey(rawValue: name) {
                    settings.set(value, for: key)
                }
            }
        }
        if let texts = object["texts"] as? [String: String] {
            for (name, value) in texts {
                if let key = MategramTextKey(rawValue: name) {
                    settings.setText(value, for: key)
                }
            }
        }
        if let values = object["values"] as? [String: Int] {
            for (name, value) in values {
                if let key = MategramValueKey(rawValue: name) {
                    settings.setValue(value, for: key)
                }
            }
        }
        return true
    }
}

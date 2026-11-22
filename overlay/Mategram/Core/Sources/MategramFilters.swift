import Foundation
import UIKit

public enum MategramZalgo {
    private static func isCombining(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .nonspacingMark, .enclosingMark:
            return true
        default:
            return false
        }
    }

    public static func clean(_ text: String) -> String {
        if !MategramSettings.shared.bool(.zalgoFilter) {
            return text
        }
        var scalars = String.UnicodeScalarView()
        var run = 0
        for scalar in text.unicodeScalars {
            if isCombining(scalar) {
                run += 1
                if run > 2 {
                    continue
                }
            } else {
                run = 0
            }
            scalars.append(scalar)
        }
        return String(scalars)
    }
}

public enum MategramPhone {
    public static func mask(_ formatted: String) -> String {
        var result = ""
        var seenSpace = false
        for character in formatted {
            if character == " " {
                seenSpace = true
                result.append(character)
            } else if seenSpace && character.isNumber {
                result.append("•")
            } else {
                result.append(character)
            }
        }
        return result
    }
}

public enum MategramLook {
    public static var stickerScale: CGFloat {
        return MategramSettings.shared.bool(.smallStickers) ? CGFloat(MategramSettings.shared.value(.stickerSize)) / 100.0 : 1.0
    }

    public static func muted(_ color: UIColor) -> UIColor {
        if !MategramSettings.shared.bool(.mutedNameColors) {
            return color
        }
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return color
        }
        return UIColor(hue: hue, saturation: saturation * 0.5, brightness: brightness, alpha: alpha)
    }
}

public enum MategramServiceTime {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    public static func append(_ string: NSAttributedString?, timestamp: Int32) -> NSAttributedString? {
        guard MategramSettings.shared.bool(.serviceMessageTime), let string, string.length > 0 else {
            return string
        }
        let attributes = string.attributes(at: string.length - 1, effectiveRange: nil).filter { $0.key == .font || $0.key == .foregroundColor }
        let result = NSMutableAttributedString(attributedString: string)
        let time = formatter.string(from: Date(timeIntervalSince1970: Double(timestamp)))
        result.append(NSAttributedString(string: " · \(time)", attributes: attributes))
        return result
    }
}

public enum MategramDNS {
    private static let lock = NSLock()
    private static var cache: [String: String] = [:]

    public static func resolve(_ host: String) -> String {
        guard MategramSettings.shared.bool(.proxyLocalDNS) else {
            return host
        }
        if host.isEmpty || host.allSatisfy({ $0.isNumber || $0 == "." || $0 == ":" }) {
            return host
        }
        lock.lock()
        let cached = cache[host]
        lock.unlock()
        if let cached {
            return cached
        }
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let first = result else {
            return host
        }
        defer {
            freeaddrinfo(result)
        }
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard let address = first.pointee.ai_addr else {
            return host
        }
        let resolved: String? = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { pointer -> String? in
            var inAddress = pointer.pointee.sin_addr
            guard inet_ntop(AF_INET, &inAddress, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else {
                return nil
            }
            return String(cString: buffer)
        }
        guard let resolved else {
            return host
        }
        lock.lock()
        cache[host] = resolved
        lock.unlock()
        return resolved
    }
}

public enum MategramDesign {
    public static var keepAvatarExpanded: Bool {
        return true
    }
}

import Foundation

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

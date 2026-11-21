import Foundation

public enum MategramNumbers {
    public static func fullCount(_ count: Int, separator: String = "\u{202F}") -> String {
        let digits = String(abs(count))
        var result = ""
        var position = 0
        for character in digits.reversed() {
            if position > 0 && position % 3 == 0 {
                result.append(contentsOf: separator.reversed())
            }
            result.append(character)
            position += 1
        }
        return (count < 0 ? "-" : "") + String(result.reversed())
    }
}

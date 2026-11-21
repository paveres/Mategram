import Foundation

public struct MategramRegDateEstimate {
    public let timestamp: Int32
    public let uncertaintyDays: Int32

    public init(timestamp: Int32, uncertaintyDays: Int32) {
        self.timestamp = timestamp
        self.uncertaintyDays = uncertaintyDays
    }
}

public enum MategramRegDate {
    public static func estimate(userId: Int64, now: Int32) -> MategramRegDateEstimate? {
        let ids = MategramRegDateAnchors.ids
        let times = MategramRegDateAnchors.times
        guard ids.count > 2, ids.count == times.count, let firstId = ids.first, let lastId = ids.last, userId >= firstId else {
            return nil
        }

        if userId >= lastId {
            let count = ids.count
            var index = count - 2
            while index > 0 && times[count - 1] - times[index] < 90 * 86400 {
                index -= 1
            }
            let idSpan = Double(ids[count - 1] - ids[index])
            let timeSpan = Double(times[count - 1] - times[index])
            guard idSpan > 0, timeSpan > 0 else {
                return nil
            }
            let rate = idSpan / timeSpan
            let value = Double(times[count - 1]) + Double(userId - ids[count - 1]) / rate
            let clamped = min(Double(now), value)
            return MategramRegDateEstimate(timestamp: Int32(clamping: Int64(clamped)), uncertaintyDays: 75)
        }

        var low = 0
        var high = ids.count - 1
        while low < high {
            let middle = (low + high) / 2
            if ids[middle] < userId {
                low = middle + 1
            } else {
                high = middle
            }
        }
        if ids[low] == userId || low == 0 {
            return MategramRegDateEstimate(timestamp: times[low], uncertaintyDays: 15)
        }
        let previous = low - 1
        let idSpan = Double(ids[low] - ids[previous])
        let fraction = idSpan > 0 ? Double(userId - ids[previous]) / idSpan : 0.0
        let timeSpan = Double(times[low] - times[previous])
        let value = Double(times[previous]) + fraction * timeSpan
        let gapDays = timeSpan / 86400.0
        return MategramRegDateEstimate(timestamp: Int32(clamping: Int64(value)), uncertaintyDays: Int32(max(10.0, min(2000.0, gapDays / 2.0))))
    }

    private static func monthYear(date: Date, language: MategramLanguage, withMonth: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .russian ? "ru_RU" : "en_US")
        formatter.dateFormat = withMonth ? "LLLL yyyy" : "yyyy"
        return formatter.string(from: date)
    }

    public static func text(estimate: MategramRegDateEstimate, languageCode: String) -> String {
        let language = MategramLanguage(code: languageCode)
        let date = Date(timeIntervalSince1970: TimeInterval(estimate.timestamp))
        let withMonth = estimate.uncertaintyDays <= 100
        return "≈ " + self.monthYear(date: date, language: language, withMonth: withMonth)
    }

    public static func text(telegramMonth: String, languageCode: String) -> String? {
        let parts = telegramMonth.split(separator: ".")
        guard parts.count == 2, let month = Int(parts[0]), let year = Int(parts[1]), month >= 1, month <= 12 else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 15
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        return self.monthYear(date: date, language: MategramLanguage(code: languageCode), withMonth: true)
    }
}

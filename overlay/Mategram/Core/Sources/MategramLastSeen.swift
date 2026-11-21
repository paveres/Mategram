import Foundation

public enum MategramLastSeen {
    private static let lock = NSLock()
    private static var timeFormatters: [String: DateFormatter] = [:]
    private static var dateFormatters: [String: DateFormatter] = [:]

    private static func timeFormatter(language: MategramLanguage, twentyFourHour: Bool) -> DateFormatter {
        let key = "\(language == .russian ? "ru" : "en")-\(twentyFourHour ? "24" : "12")"
        self.lock.lock()
        defer { self.lock.unlock() }
        if let formatter = self.timeFormatters[key] {
            return formatter
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .russian ? "ru_RU" : "en_US_POSIX")
        formatter.dateFormat = twentyFourHour ? "HH:mm:ss" : "h:mm:ss a"
        self.timeFormatters[key] = formatter
        return formatter
    }

    private static func dateFormatter(language: MategramLanguage, withYear: Bool) -> DateFormatter {
        let key = "\(language == .russian ? "ru" : "en")-\(withYear ? "y" : "n")"
        self.lock.lock()
        defer { self.lock.unlock() }
        if let formatter = self.dateFormatters[key] {
            return formatter
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .russian ? "ru_RU" : "en_US")
        if withYear {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        } else {
            formatter.setLocalizedDateFormatFromTemplate("d MMM")
        }
        self.dateFormatters[key] = formatter
        return formatter
    }

    public static func text(statusTimestamp: Int32, now: Int32, languageCode: String, twentyFourHour: Bool) -> String? {
        if statusTimestamp >= now {
            return nil
        }
        let language = MategramLanguage(code: languageCode)
        let date = Date(timeIntervalSince1970: TimeInterval(statusTimestamp))
        let nowDate = Date(timeIntervalSince1970: TimeInterval(now))
        let calendar = Calendar.current

        let time = self.timeFormatter(language: language, twentyFourHour: twentyFourHour).string(from: date)
        let prefix = language == .russian ? "был(а) " : "last seen "
        let connector = language == .russian ? " в " : " at "

        let day: String
        if calendar.isDate(date, inSameDayAs: nowDate) {
            day = language == .russian ? "сегодня" : "today"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: nowDate), calendar.isDate(date, inSameDayAs: yesterday) {
            day = language == .russian ? "вчера" : "yesterday"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: nowDate) {
            day = self.dateFormatter(language: language, withYear: false).string(from: date)
        } else {
            day = self.dateFormatter(language: language, withYear: true).string(from: date)
        }
        return prefix + day + connector + time
    }
}

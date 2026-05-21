import Foundation

// MARK: - Event date / time parsing

enum EventDateParser {

    // "2026-06-07" → Date? representing midnight Rome time
    static func parseDate(_ string: String) -> Date? {
        isoDateFormatter.date(from: string.trimmingCharacters(in: .whitespaces))
    }

    // "2026-06-07" → "07"
    static func dayString(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }
        let day = Calendar.current.component(.day, from: date)
        return String(format: "%02d", day)
    }

    // "2026-06-07" → "GIU"
    static func monthShort(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }
        return italianMonthShort.string(from: date).uppercased()
    }

    // "2026-06-07" → "7 giugno 2026"
    static func fullDate(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return dateString }
        return italianFullDate.string(from: date)
    }

    // Combine "2026-06-07" + "10:00" → Date for EKEvent startDate
    static func combinedDate(dateString: String, timeString: String) -> Date? {
        guard let date = parseDate(dateString) else { return nil }
        guard !timeString.trimmingCharacters(in: .whitespaces).isEmpty,
              let timeParsed = parseTime(timeString) else { return date }
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: timeParsed)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        return cal.date(from: comps)
    }

    // Parse flexible time strings: "10:00", "10:00:00", "10.00" → Date (reference day)
    static func parseTime(_ string: String) -> Date? {
        let cleaned = string
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: ":")
        for formatter in timeFormatters {
            if let d = formatter.date(from: cleaned) { return d }
        }
        return nil
    }

    // Format time for display: "10:00"
    static func displayTime(_ string: String) -> String {
        guard let date = parseTime(string) else {
            return string.trimmingCharacters(in: .whitespaces)
        }
        return displayTimeFormatter.string(from: date)
    }

    // MARK: - Private formatters (created once, reused)

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        return f
    }()

    private static let italianMonthShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    private static let italianFullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.locale = Locale(identifier: "it_IT")
        return f
    }()

    private static let timeFormatters: [DateFormatter] = {
        ["HH:mm:ss", "HH:mm", "H:mm"].map { fmt in
            let f = DateFormatter()
            f.dateFormat = fmt
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }
    }()

    private static let displayTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}

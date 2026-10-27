import Foundation

/// Validates knowledge encoded as canonical Gregorian text; comparison bounds are never stored.
enum CivilDate {
    static let dayLength = 10
    private static let yearLength = 4
    private static let monthLength = 7
    private static let minuteLength = 16
    private static let maximumYear = 9_999

    static var calendar: Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .gmt
        return gregorian
    }

    static func parse(_ text: String, formats: [Int: String]) throws -> Date {
        guard let format = formats[text.utf8.count],
              text.unicodeScalars.allSatisfy({ "0123456789-T:".unicodeScalars.contains($0) })
        else {
            throw RecordError.invalidDate
        }
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = .gmt
        formatter.isLenient = false
        formatter.dateFormat = format
        guard let date = formatter.date(from: text), formatter.string(from: date) == text,
              (1...maximumYear).contains(calendar.component(.year, from: date))
        else {
            throw RecordError.invalidDate
        }
        return date
    }

    static func validateMark(_ text: String) throws {
        _ = try parse(text, formats: [dayLength: "yyyy-MM-dd", minuteLength: "yyyy-MM-dd'T'HH:mm"])
    }

    static func range(_ text: String?) throws -> DateInterval? {
        guard let text else {
            return nil
        }
        let date = try parse(
            text,
            formats: [yearLength: "yyyy", monthLength: "yyyy-MM", dayLength: "yyyy-MM-dd"]
        )
        let component: Calendar.Component
        switch text.count {
        case yearLength:
            component = .year
        case monthLength:
            component = .month
        default:
            component = .day
        }
        guard let interval = calendar.dateInterval(of: component, for: date) else {
            throw RecordError.invalidDate
        }
        return interval
    }

    static func latestDay(in range: DateInterval) -> Date {
        calendar.date(byAdding: .day, value: -1, to: range.end) ?? range.start
    }
}

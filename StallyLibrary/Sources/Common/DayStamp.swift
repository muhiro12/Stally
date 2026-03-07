import Foundation

enum DayStamp {
    private static let utcTimeZone = TimeZone(secondsFromGMT: .zero)
        ?? TimeZone(abbreviation: "UTC")
        ?? .current

    static var utcCalendar: Calendar {
        var calendar: Calendar = .init(identifier: .gregorian)
        calendar.timeZone = utcTimeZone
        return calendar
    }

    static func storageDate(
        from date: Date,
        calendar: Calendar = .current
    ) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let utcDay = utcCalendar.date(from: components) else {
            preconditionFailure("Failed to normalize a storage day from \(date).")
        }

        return utcDay
    }

    static func localDate(
        from storageDate: Date,
        calendar: Calendar = .current
    ) -> Date {
        let components = utcCalendar.dateComponents([.year, .month, .day], from: storageDate)

        guard let localDay = calendar.date(from: components) else {
            preconditionFailure("Failed to resolve a local day from \(storageDate).")
        }

        return localDay
    }

    static func monthStart(
        from date: Date,
        calendar: Calendar = .current
    ) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)

        guard let monthStart = calendar.date(from: components) else {
            preconditionFailure("Failed to resolve a month start from \(date).")
        }

        return monthStart
    }
}

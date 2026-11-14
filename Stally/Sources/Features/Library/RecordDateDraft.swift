import Foundation

/// Calendar controls edit civil components; UTC is only a stable UI conversion zone.
struct RecordDateDraft {
    enum Precision: Int, CaseIterable, Identifiable {
        case unknown = 0
        case year = 4
        case month = 7
        case day = 10

        var id: Self {
            self
        }
        var title: LocalizedStringResource {
            switch self {
            case .unknown:
                "Unknown"
            case .year:
                "Year"
            case .month:
                "Month"
            case .day:
                "Day"
            }
        }
    }

    private static let minuteLength = 16

    static var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = .gmt
        result.locale = .current
        return result
    }

    static var today: String {
        let formatter = formatter("yyyy-MM-dd")
        formatter.timeZone = .current
        return formatter.string(from: .now)
    }

    var precision: Precision
    var year: String
    var month: Int
    var date: Date
    var includesTime: Bool
    var unsupportedValue: String?

    var value: String? {
        if let unsupportedValue {
            return unsupportedValue
        }
        switch precision {
        case .unknown:
            return nil
        case .year:
            return year
        case .month:
            return year + String(format: "-%02d", month)
        case .day:
            return Self.formatter(includesTime ? "yyyy-MM-dd'T'HH:mm" : "yyyy-MM-dd").string(from: date)
        }
    }

    init(_ value: String?) {
        let initialDate = Self.formatter("yyyy-MM-dd").date(from: Self.today) ?? .now
        date = initialDate
        year = Self.formatter("yyyy").string(from: initialDate)
        month = Self.calendar.component(.month, from: initialDate)
        includesTime = value?.count == Self.minuteLength
        precision = value == nil ? .unknown : Precision(rawValue: value?.count ?? 0) ?? .day
        guard let value else {
            return
        }
        let formats = [
            Precision.year.rawValue: "yyyy",
            Precision.month.rawValue: "yyyy-MM",
            Precision.day.rawValue: "yyyy-MM-dd",
            Self.minuteLength: "yyyy-MM-dd'T'HH:mm"
        ]
        guard let format = formats[value.count],
              let parsed = Self.formatter(format).date(from: value),
              Self.formatter(format).string(from: parsed) == value
        else {
            unsupportedValue = value
            return
        }
        date = parsed
        year = String(value.prefix(Precision.year.rawValue))
        month = Self.calendar.component(.month, from: parsed)
    }

    static func display(_ value: String?) -> String {
        guard let value else {
            return String(localized: "Unknown")
        }
        let draft = Self(value)
        guard draft.unsupportedValue == nil else {
            return value
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = .current
        switch draft.precision {
        case .unknown:
            return String(localized: "Unknown")
        case .year:
            formatter.setLocalizedDateFormatFromTemplate("yyyy")
        case .month:
            formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        case .day:
            formatter.setLocalizedDateFormatFromTemplate(draft.includesTime ? "yyyyMMMdjmm" : "yyyyMMMd")
        }
        return formatter.string(from: draft.date)
    }

    static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        formatter.isLenient = false
        return formatter
    }
    mutating func selectPrecision(_ newPrecision: Precision) {
        if precision == .day {
            year = Self.formatter("yyyy").string(from: date)
            month = Self.calendar.component(.month, from: date)
        } else if newPrecision == .day, precision != .unknown {
            let monthValue = precision == .year ? 1 : month
            let candidate = year + String(format: "-%02d-01", monthValue)
            if let parsed = Self.formatter("yyyy-MM-dd").date(from: candidate) {
                date = parsed
            }
        }
        precision = newPrecision
    }
}

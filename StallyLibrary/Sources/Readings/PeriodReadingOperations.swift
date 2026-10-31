import Foundation

/// Uses Gregorian civil dates, retaining the precision and uncertainty of each record.
public enum PeriodReadingOperations {
    private struct Difference {
        let days: Int
        let months: Int
        let years: Int
    }

    /// Conflicting histories fail visibly rather than yielding a misleading numeric total.
    public static func readings(for item: Item, today: String) throws -> PeriodReadings {
        let periods = item.periods ?? []
        try PeriodOperations.validateHistory(periods, today: today)
        return try .init(
            current: reading(periods.filter(\.isOngoing), today: today),
            cumulative: reading(periods, today: today)
        )
    }

    private static func reading(_ periods: [ItemPeriod], today: String) throws -> PeriodReading? {
        let todayDate = try CivilDate.parse(today, formats: [CivilDate.dayLength: "yyyy-MM-dd"])
        guard !periods.isEmpty else {
            return nil
        }
        var days = 0
        var months = 0
        var years = 0
        var excluded = 0
        var approximate = false
        var possibleIntervals: [DateInterval] = []
        for period in periods {
            let endText = period.isOngoing ? today : period.endLocalDate
            guard let startText = period.startLocalDate, let endText,
                  let start = try CivilDate.range(startText), let end = try CivilDate.range(endText),
                  !period.isOngoing || start.start <= todayDate
            else {
                excluded += 1
                continue
            }
            let precision = min(startText.count, endText.count)
            let difference = difference(start: start.start, end: end.start, precision: precision)
            days += difference.days
            months += difference.months
            years += difference.years
            approximate = approximate || precision != CivilDate.dayLength
            possibleIntervals.append(.init(start: start.start, end: max(start.start, CivilDate.latestDay(in: end))))
        }
        let sorted = possibleIntervals.sorted { $0.start < $1.start }
        let mayOverlap = zip(sorted, sorted.dropFirst()).contains { $0.end > $1.start }
        return .init(
            exactDays: days,
            approximateMonths: months,
            approximateYears: years,
            includedCount: periods.count - excluded,
            excludedCount: excluded,
            hasApproximation: approximate,
            mayOverlap: mayOverlap
        )
    }
    private static func difference(start: Date, end: Date, precision: Int) -> Difference {
        let yearLength = 4
        let monthLength = 7
        let monthsPerYear = 12
        let years = CivilDate.calendar.component(.year, from: end) - CivilDate.calendar.component(.year, from: start)
        switch precision {
        case yearLength:
            return .init(days: 0, months: 0, years: max(0, years))
        case monthLength:
            let months =
                years * monthsPerYear + CivilDate.calendar.component(.month, from: end)
                - CivilDate.calendar.component(.month, from: start)
            return .init(days: 0, months: max(0, months), years: 0)
        default:
            let days = CivilDate.calendar.dateComponents([.day], from: start, to: end).day ?? 0
            return .init(days: max(0, days), months: 0, years: 0)
        }
    }
}

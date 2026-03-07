import Foundation

/// History builders for the quiet monthly accumulation view.
public enum MarkHistoryCalculator {
    /// One rendered day cell in the history grid.
    public struct MarkHistoryDayCell: Identifiable, Equatable, Sendable {
        public let date: Date
        public let dayNumber: Int
        public let isInDisplayedMonth: Bool
        public let isMarked: Bool

        public var id: Date {
            date
        }
    }

    /// One month of day cells for the detail history.
    public struct MarkHistoryMonth: Identifiable, Equatable, Sendable {
        public let monthStart: Date
        public let cells: [MarkHistoryDayCell]

        public var id: Date {
            monthStart
        }
    }

    public static func months(
        for item: Item,
        count: Int = 6,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [MarkHistoryMonth] {
        let safeCount = max(count, .zero)
        let markedStorageDates = Set(item.marks.map(\.day))
        let referenceMonthStart = DayStamp.monthStart(
            from: referenceDate,
            calendar: calendar
        )

        return (0..<safeCount).compactMap { offset in
            guard let monthStart = calendar.date(
                byAdding: .month,
                value: -offset,
                to: referenceMonthStart
            ) else {
                return nil
            }

            return .init(
                monthStart: monthStart,
                cells: cells(
                    for: monthStart,
                    markedStorageDates: markedStorageDates,
                    calendar: calendar
                )
            )
        }
    }
}

private extension MarkHistoryCalculator {
    static func cells(
        for monthStart: Date,
        markedStorageDates: Set<Date>,
        calendar: Calendar
    ) -> [MarkHistoryDayCell] {
        guard let monthDayRange = calendar.range(
            of: .day,
            in: .month,
            for: monthStart
        ) else {
            return []
        }

        let leadingEmptyCellCount = weekdayOffset(
            for: monthStart,
            calendar: calendar
        )
        let totalVisibleDayCount = leadingEmptyCellCount + monthDayRange.count
        let trailingEmptyCellCount = totalVisibleDayCount.isMultiple(of: 7)
            ? .zero
            : 7 - (totalVisibleDayCount % 7)
        let cellCount = totalVisibleDayCount + trailingEmptyCellCount

        return (0..<cellCount).compactMap { index in
            let dayOffset = index - leadingEmptyCellCount

            guard let cellDate = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: monthStart
            ) else {
                return nil
            }

            let storageDate = DayStamp.storageDate(
                from: cellDate,
                calendar: calendar
            )

            return .init(
                date: cellDate,
                dayNumber: calendar.component(.day, from: cellDate),
                isInDisplayedMonth: calendar.isDate(
                    cellDate,
                    equalTo: monthStart,
                    toGranularity: .month
                ),
                isMarked: markedStorageDates.contains(storageDate)
            )
        }
    }

    static func weekdayOffset(
        for date: Date,
        calendar: Calendar
    ) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday - calendar.firstWeekday + 7) % 7
    }
}

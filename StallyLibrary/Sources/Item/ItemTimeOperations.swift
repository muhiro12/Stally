/// Cross-surface elapsed-time readings using an explicitly captured local day.
public enum ItemTimeOperations {
    private static let monthsPerYear = 12

    /// Reads persisted start knowledge while distinguishing unknown and malformed values.
    public static func snapshot(for item: Item, today: LocalDay) -> ItemTimeSnapshot {
        do {
            let tracking = try ItemOperations.trackingInput(for: item)
            return snapshot(start: tracking.start, today: today)
        } catch {
            return .invalidStart
        }
    }

    /// Reads the range supported by start precision. The starting day is day zero.
    public static func snapshot(start: ItemStart?, today: LocalDay) -> ItemTimeSnapshot {
        guard let start else {
            return .unknown
        }
        guard today >= start.earliestDay else {
            return .notStarted(start)
        }

        let latestPastStart = min(start.latestDay, today)
        let days = latestPastStart.distance(to: today)...start.earliestDay.distance(to: today)
        let units: ClosedRange<Int>
        switch start.precision {
        case .day:
            units = days
        case .month:
            let lower = completedMonths(from: latestPastStart, to: today)
            let upper = completedMonths(from: start.earliestDay, to: today)
            units = lower...upper
        case .year:
            let lower = completedMonths(from: latestPastStart, to: today) / monthsPerYear
            let upper = completedMonths(from: start.earliestDay, to: today) / monthsPerYear
            units = lower...upper
        }
        return .elapsed(start: start, days: days, units: units)
    }

    private static func completedMonths(from start: LocalDay, to today: LocalDay) -> Int {
        let months = (today.year - start.year) * monthsPerYear + today.month - start.month
        let anniversaryDay = min(
            start.day,
            ItemStart.lastValidDay(year: today.year, month: today.month)
        )
        return today.day < anniversaryDay ? months - 1 : months
    }
}

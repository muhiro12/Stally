public extension ItemTimeOperations {
    /// Reads the current or next yearly milestone, including archived Items.
    /// Unknown, invalid, and wholly future starts have no milestone reading.
    static func milestone(for item: Item, today: LocalDay) -> ItemMilestone? {
        guard let tracking = try? ItemOperations.trackingInput(for: item) else {
            return nil
        }
        return milestone(start: tracking.start, today: today)
    }

    /// Retains an approximate milestone throughout its known month or year.
    /// February 29 anniversaries use February 28 in non-leap years. No dates or
    /// milestone events are saved, and no period beyond year 9999 is invented.
    static func milestone(start: ItemStart?, today: LocalDay) -> ItemMilestone? {
        guard let start, start.earliestDay <= today else {
            return nil
        }
        let firstYear = max(start.earliestDay.year + 1, today.year)
        guard let current = milestonePeriod(start: start, year: firstYear) else {
            return nil
        }
        let period: ItemStart
        if current.latestDay >= today {
            period = current
        } else if let next = milestonePeriod(start: start, year: firstYear + 1) {
            period = next
        } else {
            return nil
        }
        return .init(years: period.earliestDay.year - start.earliestDay.year, period: period)
    }

    private static func milestonePeriod(start: ItemStart, year: Int) -> ItemStart? {
        switch start.precision {
        case .year:
            return .init(year: year)
        case .month:
            return .init(year: year, month: start.earliestDay.month)
        case .day:
            let month = start.earliestDay.month
            let day = min(start.earliestDay.day, ItemStart.lastValidDay(year: year, month: month))
            return .init(year: year, month: month, day: day)
        }
    }
}

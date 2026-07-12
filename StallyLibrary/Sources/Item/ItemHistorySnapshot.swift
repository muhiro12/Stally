//
//  ItemHistorySnapshot.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/06/25.
//

/// Item-level history readings derived from one item and its marks.
public struct ItemHistorySnapshot {
    private enum Defaults {
        static let shortWindowDayCount = 30
        static let mediumWindowDayCount = 90
        static let inclusiveWindowAdjustment = 1
        static let monthKeyMultiplier = 100
    }

    /// Total unique marked days.
    public let totalMarks: Int
    /// Most recent marked day.
    public let lastMarkedDay: LocalDay?
    /// Unique marked days in the latest 30-day window.
    public let marksInLast30Days: Int
    /// Unique marked days in the latest 90-day window.
    public let marksInLast90Days: Int
    /// Number of distinct calendar months with marks.
    public let monthsUsed: Int
    /// Days between the last mark and `today`.
    public let daysSinceLastMark: Int?
    /// Unique marked days sorted from newest to oldest.
    public let markedDays: [LocalDay]

    init(item: Item, today: LocalDay) {
        let uniqueDays = Set(item.marks.map(\.day))
        let sortedDays = uniqueDays.sorted(by: >)

        totalMarks = uniqueDays.count
        lastMarkedDay = sortedDays.first
        marksInLast30Days = Self.countMarks(
            in: uniqueDays,
            from: today,
            numberOfDays: Defaults.shortWindowDayCount
        )
        marksInLast90Days = Self.countMarks(
            in: uniqueDays,
            from: today,
            numberOfDays: Defaults.mediumWindowDayCount
        )
        monthsUsed = Self.countMonthsUsed(in: uniqueDays)
        daysSinceLastMark = lastMarkedDay.map { lastMarkedDay in
            max(0, lastMarkedDay.distance(to: today))
        }
        markedDays = sortedDays
    }

    private static func countMarks(
        in markedDays: Set<LocalDay>,
        from today: LocalDay,
        numberOfDays: Int
    ) -> Int {
        guard let startDay = today.adding(
            days: -(numberOfDays - Defaults.inclusiveWindowAdjustment)
        ) else {
            return 0
        }

        return markedDays.filter { day in
            day >= startDay
        }
        .count
    }

    private static func countMonthsUsed(in markedDays: Set<LocalDay>) -> Int {
        let monthKeys = markedDays.map { day in
            day.year * Defaults.monthKeyMultiplier + day.month
        }

        return Set(monthKeys).count
    }
}

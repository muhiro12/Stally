//
//  InsightsOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Cross-surface Insights use cases for collection pattern reading.
public enum InsightsOperations {
    private enum GregorianWeekday {
        static let sunday = 1
        static let monday = 2
        static let tuesday = 3
        static let wednesday = 4
        static let thursday = 5
        static let friday = 6
        static let saturday = 7
    }

    private struct MonthKey: Hashable {
        let year: Int
        let month: Int
    }

    private static let rankedItemLimit = 5
    private static let monthlyActivityLimit = 12
    private static let mondayFirstWeekdays = [
        GregorianWeekday.monday,
        GregorianWeekday.tuesday,
        GregorianWeekday.wednesday,
        GregorianWeekday.thursday,
        GregorianWeekday.friday,
        GregorianWeekday.saturday,
        GregorianWeekday.sunday
    ]

    /// Builds the current Insights reading.
    public static func snapshot(
        for items: [Item],
        options: InsightsOptions = .default,
        timeZone: TimeZone = .current,
        now: Date = .now
    ) -> InsightsSnapshot {
        let scopedItems = options.includesArchivedItems ? items : ItemOperations.activeItems(from: items)

        guard let today = LocalDay(containing: now, in: timeZone) else {
            return unavailableSnapshot(options: options, scopedItems: scopedItems)
        }

        let startDay = options.range.startDay(from: today)

        guard options.range == .allTime || startDay != nil else {
            return unavailableSnapshot(options: options, scopedItems: scopedItems)
        }

        let readings = scopedItems.map { item in
            makeReading(
                for: item,
                startDay: startDay
            )
        }
        let activeDays = Set(readings.flatMap(\.rangeMarkedDays))
        let topItems = makeTopItems(from: readings)
        let quietItems = makeQuietItems(from: readings)
        let currentStreak = currentStreak(in: activeDays, today: today)
        let totalMarks = readings.reduce(0) { result, reading in
            result + reading.rangeMarkCount
        }
        let categoryShares = makeCategoryShares(
            from: readings,
            totalMarks: totalMarks
        )

        return .init(
            options: options,
            totalMarks: totalMarks,
            activeDays: activeDays.count,
            uniqueMarkedItems: uniqueMarkedItemCount(from: readings),
            uniqueMarkedCategories: categoryShares.count,
            topItems: topItems,
            quietItems: quietItems,
            currentStreak: currentStreak,
            bestStreak: bestStreak(in: activeDays),
            categoryShares: categoryShares,
            weekdayActivity: makeWeekdayActivity(from: readings),
            monthlyActivity: makeMonthlyActivity(from: readings),
            noteCoverage: noteCoverage(for: scopedItems),
            photoCoverage: photoCoverage(for: scopedItems),
            recommendations: makeRecommendations(
                totalMarks: totalMarks,
                topItems: topItems,
                quietItems: quietItems,
                currentStreak: currentStreak
            )
        )
    }
}

private extension InsightsOperations {
    static func unavailableSnapshot(
        options: InsightsOptions,
        scopedItems: [Item]
    ) -> InsightsSnapshot {
        .init(
            options: options,
            totalMarks: 0,
            activeDays: 0,
            uniqueMarkedItems: 0,
            uniqueMarkedCategories: 0,
            topItems: [],
            quietItems: [],
            currentStreak: 0,
            bestStreak: 0,
            categoryShares: [],
            weekdayActivity: [],
            monthlyActivity: [],
            noteCoverage: noteCoverage(for: scopedItems),
            photoCoverage: photoCoverage(for: scopedItems),
            recommendations: []
        )
    }

    static func makeReading(
        for item: Item,
        startDay: LocalDay?
    ) -> ItemRangeReading {
        let allMarkedDays = Set(item.marks.map(\.day))
        let rangeMarkedDays = allMarkedDays.filter { day in
            guard let startDay else {
                return true
            }

            return day >= startDay
        }

        return .init(
            item: item,
            rangeMarkedDays: rangeMarkedDays.sorted(),
            allMarkedDays: allMarkedDays.sorted()
        )
    }

    static func makeTopItems(
        from readings: [ItemRangeReading]
    ) -> [ItemInsightSummary] {
        readings
            .filter { reading in
                reading.rangeMarkCount > 0
            }
            .sorted { lhsReading, rhsReading in
                if lhsReading.rangeMarkCount == rhsReading.rangeMarkCount {
                    return lhsReading.item.createdAt > rhsReading.item.createdAt
                }

                return lhsReading.rangeMarkCount > rhsReading.rangeMarkCount
            }
            .prefix(Self.rankedItemLimit)
            .map(\.summary)
    }

    static func uniqueMarkedItemCount(from readings: [ItemRangeReading]) -> Int {
        readings.filter { reading in
            reading.rangeMarkCount > 0
        }
        .count
    }

    static func makeQuietItems(
        from readings: [ItemRangeReading]
    ) -> [ItemInsightSummary] {
        readings
            .filter { reading in
                reading.totalMarkCount > 0 && reading.rangeMarkCount == 0
            }
            .sorted { lhsReading, rhsReading in
                if let lhsLastMarkedDay = lhsReading.lastMarkedDay,
                   let rhsLastMarkedDay = rhsReading.lastMarkedDay,
                   lhsLastMarkedDay != rhsLastMarkedDay {
                    return lhsLastMarkedDay < rhsLastMarkedDay
                }

                return lhsReading.item.createdAt < rhsReading.item.createdAt
            }
            .prefix(Self.rankedItemLimit)
            .map(\.summary)
    }

    static func makeCategoryShares(
        from readings: [ItemRangeReading],
        totalMarks: Int
    ) -> [CategoryShare] {
        let marksByCategory = readings.reduce(into: [ItemCategory: Int]()) { result, reading in
            guard reading.rangeMarkCount > 0 else {
                return
            }

            result[reading.item.category, default: 0] += reading.rangeMarkCount
        }

        return marksByCategory
            .map { category, markCount in
                .init(
                    category: category,
                    markCount: markCount,
                    fraction: totalMarks > 0 ? Double(markCount) / Double(totalMarks) : 0
                )
            }
            .sorted { lhsShare, rhsShare in
                if lhsShare.markCount == rhsShare.markCount {
                    return lhsShare.category.rawValue < rhsShare.category.rawValue
                }

                return lhsShare.markCount > rhsShare.markCount
            }
    }

    static func makeWeekdayActivity(
        from readings: [ItemRangeReading]
    ) -> [WeekdayActivity] {
        let counts = readings
            .flatMap(\.rangeMarkedDays)
            .reduce(into: [Int: Int]()) { result, day in
                guard let weekday = weekday(for: day) else {
                    return
                }

                result[weekday, default: 0] += 1
            }

        return mondayFirstWeekdays.compactMap { weekday in
            guard let markCount = counts[weekday] else {
                return nil
            }

            return .init(weekday: weekday, markCount: markCount)
        }
    }

    static func makeMonthlyActivity(
        from readings: [ItemRangeReading]
    ) -> [MonthlyActivity] {
        let counts = readings
            .flatMap(\.rangeMarkedDays)
            .reduce(into: [MonthKey: Int]()) { result, day in
                result[.init(year: day.year, month: day.month), default: 0] += 1
            }

        return Array(
            counts
                .map { key, markCount in
                    MonthlyActivity(
                        year: key.year,
                        month: key.month,
                        markCount: markCount
                    )
                }
                .sorted { lhs, rhs in
                    lhs.id < rhs.id
                }
                .suffix(monthlyActivityLimit)
        )
    }

    static func noteCoverage(for items: [Item]) -> CollectionCoverage {
        let coveredCount = items.filter { item in
            !item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .count

        return .init(coveredCount: coveredCount, totalCount: items.count)
    }

    static func photoCoverage(for items: [Item]) -> CollectionCoverage {
        let coveredCount = items.filter { item in
            !(item.photoData?.isEmpty ?? true)
        }
        .count

        return .init(coveredCount: coveredCount, totalCount: items.count)
    }

    static func makeRecommendations(
        totalMarks: Int,
        topItems: [ItemInsightSummary],
        quietItems: [ItemInsightSummary],
        currentStreak: Int
    ) -> [InsightRecommendation] {
        var recommendations: [InsightRecommendation] = []

        if totalMarks == 0 {
            recommendations.append(.init(kind: .startThisRangeWithOneMark))
        }

        if !quietItems.isEmpty {
            recommendations.append(.init(kind: .revisitQuietFavorites))
        }

        if topItems.contains(where: { summary in
            summary.item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) {
            recommendations.append(.init(kind: .addContextToFrequentItems))
        }

        if currentStreak > 0 {
            recommendations.append(.init(kind: .protectCurrentStreak))
        }

        return recommendations
    }

    static func currentStreak(
        in activeDays: Set<LocalDay>,
        today: LocalDay
    ) -> Int {
        var streak = 0
        var day = today

        while activeDays.contains(day) {
            streak += 1

            guard let previousDay = day.adding(days: -1) else {
                return streak
            }

            day = previousDay
        }

        return streak
    }

    static func bestStreak(in activeDays: Set<LocalDay>) -> Int {
        var bestStreak = 0
        var currentStreak = 0
        var previousDay: LocalDay?

        for day in activeDays.sorted() {
            if let previousDay,
               previousDay.distance(to: day) == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }

            bestStreak = max(bestStreak, currentStreak)
            previousDay = day
        }

        return bestStreak
    }

    static func weekday(for day: LocalDay) -> Int? {
        guard let timeZone = TimeZone(secondsFromGMT: 0),
              let date = day.date(in: timeZone) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.component(.weekday, from: date)
    }
}

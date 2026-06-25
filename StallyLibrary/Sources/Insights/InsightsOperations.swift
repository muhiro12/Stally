//
//  InsightsOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Cross-surface Insights use cases for collection pattern reading.
public enum InsightsOperations {
    private static let rankedItemLimit = 5

    /// Builds the current Insights reading.
    public static func snapshot(
        for items: [Item],
        options: InsightsOptions = .default,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> InsightsSnapshot {
        let today = calendar.startOfDay(for: now)
        let startDay = options.range.startDay(from: today, calendar: calendar)
        let scopedItems = options.includesArchivedItems ? items : ItemOperations.activeItems(from: items)
        let readings = scopedItems.map { item in
            makeReading(
                for: item,
                startDay: startDay,
                today: today,
                calendar: calendar
            )
        }
        let activeDays = Set(readings.flatMap(\.rangeMarkedDays))
        let topItems = makeTopItems(from: readings)
        let quietItems = makeQuietItems(from: readings)
        let currentStreak = currentStreak(in: activeDays, today: today, calendar: calendar)
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
            bestStreak: bestStreak(in: activeDays, calendar: calendar),
            categoryShares: categoryShares,
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

    private static func makeReading(
        for item: Item,
        startDay: Date?,
        today: Date,
        calendar: Calendar
    ) -> ItemRangeReading {
        let allMarkedDays = Set(
            item.marks.map { mark in
                calendar.startOfDay(for: mark.day)
            }
        )
        let rangeMarkedDays = allMarkedDays.filter { day in
            guard day <= today else {
                return false
            }

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

    private static func makeTopItems(
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

    private static func uniqueMarkedItemCount(from readings: [ItemRangeReading]) -> Int {
        readings.filter { reading in
            reading.rangeMarkCount > 0
        }
        .count
    }

    private static func makeQuietItems(
        from readings: [ItemRangeReading]
    ) -> [ItemInsightSummary] {
        readings
            .filter { reading in
                reading.totalMarkCount > 0 && reading.rangeMarkCount == 0
            }
            .sorted { lhsReading, rhsReading in
                (lhsReading.lastMarkedDay ?? .distantPast) < (rhsReading.lastMarkedDay ?? .distantPast)
            }
            .prefix(Self.rankedItemLimit)
            .map(\.summary)
    }

    private static func makeCategoryShares(
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

    private static func noteCoverage(for items: [Item]) -> CollectionCoverage {
        let coveredCount = items.filter { item in
            !item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        .count

        return .init(coveredCount: coveredCount, totalCount: items.count)
    }

    private static func photoCoverage(for items: [Item]) -> CollectionCoverage {
        let coveredCount = items.filter { item in
            !(item.photoData?.isEmpty ?? true)
        }
        .count

        return .init(coveredCount: coveredCount, totalCount: items.count)
    }

    private static func makeRecommendations(
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

    private static func currentStreak(
        in activeDays: Set<Date>,
        today: Date,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var day = today

        while activeDays.contains(day) {
            streak += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
                return streak
            }

            day = previousDay
        }

        return streak
    }

    private static func bestStreak(
        in activeDays: Set<Date>,
        calendar: Calendar
    ) -> Int {
        var bestStreak = 0
        var currentStreak = 0
        var previousDay: Date?

        for day in activeDays.sorted() {
            if let previousDay,
               calendar.dateComponents([.day], from: previousDay, to: day).day == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }

            bestStreak = max(bestStreak, currentStreak)
            previousDay = day
        }

        return bestStreak
    }
}

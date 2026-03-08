import Foundation

/// Derived item state used across the home and detail experiences.
public enum ItemInsightsCalculator {
    /// Summary of derived mark state for one item.
    public struct ItemSummary: Equatable, Sendable {
        public let itemID: UUID
        public let totalMarks: Int
        public let lastMarkedAt: Date?
        public let isMarkedToday: Bool
    }

    /// Aggregate insight values for active items shown on Home.
    public struct ActiveCollectionSummary: Equatable, Sendable {
        public let totalItems: Int
        public let markedTodayCount: Int
        public let neverMarkedCount: Int
        public let totalMarks: Int
    }

    /// Aggregate insight values for archived items shown in Archive.
    public struct ArchiveCollectionSummary: Equatable, Sendable {
        public let totalItems: Int
        public let itemsWithMarksCount: Int
        public let totalMarks: Int
        public let lastArchivedAt: Date?
    }

    /// Builds a derived summary for one item.
    public static func summary(
        for item: Item,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> ItemSummary {
        let sortedMarks = item.marks.sorted { lhs, rhs in
            lhs.day < rhs.day
        }
        let todayStorageDate = DayStamp.storageDate(
            from: referenceDate,
            calendar: calendar
        )
        let lastMarkedAt = sortedMarks.last.map { mark in
            DayStamp.localDate(
                from: mark.day,
                calendar: calendar
            )
        }

        return .init(
            itemID: item.id,
            totalMarks: sortedMarks.count,
            lastMarkedAt: lastMarkedAt,
            isMarkedToday: sortedMarks.contains { mark in
                mark.day == todayStorageDate
            }
        )
    }

    /// Filters active items.
    public static func activeItems(
        from items: [Item]
    ) -> [Item] {
        items.filter { item in
            !item.isArchived
        }
    }

    /// Builds aggregate insight values for active items.
    public static func activeSummary(
        from items: [Item],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> ActiveCollectionSummary {
        let activeItems = activeItems(from: items)
        let itemSummaries = activeItems.map { item in
            summary(
                for: item,
                referenceDate: referenceDate,
                calendar: calendar
            )
        }

        return .init(
            totalItems: activeItems.count,
            markedTodayCount: itemSummaries.filter(\.isMarkedToday).count,
            neverMarkedCount: itemSummaries.filter { $0.totalMarks == .zero }.count,
            totalMarks: itemSummaries.reduce(into: .zero) { partialResult, summary in
                partialResult += summary.totalMarks
            }
        )
    }

    /// Filters and sorts archived items.
    public static func archivedItems(
        from items: [Item]
    ) -> [Item] {
        items
            .filter(\.isArchived)
            .sorted { lhs, rhs in
                archivedSort(lhs: lhs, rhs: rhs)
            }
    }

    /// Builds aggregate insight values for archived items.
    public static func archiveSummary(
        from items: [Item]
    ) -> ArchiveCollectionSummary {
        let archivedItems = archivedItems(from: items)

        return .init(
            totalItems: archivedItems.count,
            itemsWithMarksCount: archivedItems.filter { !$0.marks.isEmpty }.count,
            totalMarks: archivedItems.reduce(into: .zero) { partialResult, item in
                partialResult += item.marks.count
            },
            lastArchivedAt: archivedItems.compactMap(\.archivedAt).max()
        )
    }

    /// Builds a contiguous day timeline for the selected insight range.
    public static func activityDays(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [CollectionActivityDay] {
        let scopedItems = scopedItems(
            from: items,
            includeArchivedItems: includeArchivedItems
        )
        guard let windowStart = activityWindowStart(
            from: scopedItems,
            range: range,
            referenceDate: referenceDate,
            calendar: calendar
        ) else {
            return []
        }

        let referenceDay = DayStamp.storageDate(
            from: referenceDate,
            calendar: calendar
        )
        let groupedMarks = marksByDay(
            from: scopedItems,
            startingAt: windowStart,
            endingAt: referenceDay,
            calendar: calendar
        )

        return activityDaySeries(
            startingAt: windowStart,
            endingAt: referenceDay,
            marksByDay: groupedMarks,
            calendar: calendar
        )
    }

    /// Builds aggregate activity values for the selected insight range.
    public static func activitySummary(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> CollectionActivitySummary {
        let scopedItems = scopedItems(
            from: items,
            includeArchivedItems: includeArchivedItems
        )
        let activityDays = activityDays(
            from: scopedItems,
            range: range,
            includeArchivedItems: true,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let activityMarks = activityDays.filter(\.isActive)
        let totalMarks = activityMarks.reduce(into: .zero) { partialResult, day in
            partialResult += day.markCount
        }
        let uniqueMarkedItems = uniqueMarkedItemCount(
            from: scopedItems,
            range: range,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let uniqueMarkedCategories = uniqueMarkedCategoryCount(
            from: scopedItems,
            range: range,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let busiestDay = activityMarks.max { lhs, rhs in
            if lhs.markCount != rhs.markCount {
                return lhs.markCount < rhs.markCount
            }

            return lhs.date < rhs.date
        }

        return .init(
            range: range,
            totalMarks: totalMarks,
            activeDays: activityMarks.count,
            uniqueMarkedItems: uniqueMarkedItems,
            uniqueMarkedCategories: uniqueMarkedCategories,
            averageMarksPerActiveDay: averageMarksPerActiveDay(
                totalMarks: totalMarks,
                activeDays: activityMarks.count
            ),
            busiestDay: busiestDay
        )
    }

    /// Applies search, filter, and sort options to a list of items.
    public static func items(
        from items: [Item],
        matching query: ItemListQuery,
        kind: ItemListQuery.ListKind,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [Item] {
        let orderedItems = defaultOrderedItems(
            from: items,
            kind: kind,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let itemSummaries = query.quickFilter == nil
            ? [:]
            : summariesByID(
                for: orderedItems,
                referenceDate: referenceDate,
                calendar: calendar
            )

        let filteredItems = filterItems(
            orderedItems,
            query: query,
            itemSummaries: itemSummaries
        )

        return sortFilteredItems(
            filteredItems,
            query: query,
            referenceDate: referenceDate,
            calendar: calendar
        )
    }

    /// Applies the Home-specific default ordering.
    public static func homeSort(
        items: [Item],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [Item] {
        let summaries = Dictionary(
            uniqueKeysWithValues: items.map { item in
                (
                    item.id,
                    summary(
                        for: item,
                        referenceDate: referenceDate,
                        calendar: calendar
                    )
                )
            }
        )

        return items.sorted { lhs, rhs in
            let leftSummary = summaries[lhs.id]
            let rightSummary = summaries[rhs.id]

            if leftSummary?.isMarkedToday != rightSummary?.isMarkedToday {
                return leftSummary?.isMarkedToday == true
            }

            if leftSummary?.lastMarkedAt != rightSummary?.lastMarkedAt {
                return compareDescending(
                    leftSummary?.lastMarkedAt,
                    rightSummary?.lastMarkedAt
                )
            }

            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}

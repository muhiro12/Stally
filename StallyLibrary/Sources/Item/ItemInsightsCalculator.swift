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

    public static func activeItems(
        from items: [Item]
    ) -> [Item] {
        items.filter { item in
            !item.isArchived
        }
    }

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

    public static func archivedItems(
        from items: [Item]
    ) -> [Item] {
        items
            .filter { item in
                item.isArchived
            }
            .sorted(by: archivedSort)
    }

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

    public static func items(
        from items: [Item],
        matching query: ItemListQuery,
        kind: ItemListQuery.ListKind,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [Item] {
        let defaultOrderedItems = defaultOrderedItems(
            from: items,
            kind: kind,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let itemSummaries = query.quickFilter == nil
            ? [:]
            : summariesByID(
                for: defaultOrderedItems,
                referenceDate: referenceDate,
                calendar: calendar
            )

        let filteredItems = defaultOrderedItems.filter { item in
            matchesSearch(
                item: item,
                searchText: query.trimmedSearchText
            ) && matchesCategory(
                item: item,
                category: query.category
            ) && matchesQuickFilter(
                item: item,
                summary: itemSummaries[item.id],
                quickFilter: query.quickFilter
            )
        }

        guard query.sortOption != .defaultOrder else {
            return filteredItems
        }

        let summaries = summariesByID(
            for: filteredItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let defaultIndexes = Dictionary(
            uniqueKeysWithValues: filteredItems.enumerated().map { index, item in
                (item.id, index)
            }
        )

        return filteredItems.sorted { lhs, rhs in
            switch query.sortOption {
            case .defaultOrder:
                false
            case .recentlyMarked:
                let leftDate = summaries[lhs.id]?.lastMarkedAt
                let rightDate = summaries[rhs.id]?.lastMarkedAt

                if leftDate != rightDate {
                    return compareDescending(leftDate, rightDate)
                }
            case .mostMarked:
                let leftCount = summaries[lhs.id]?.totalMarks ?? .zero
                let rightCount = summaries[rhs.id]?.totalMarks ?? .zero

                if leftCount != rightCount {
                    return leftCount > rightCount
                }
            case .name:
                let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)

                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }
            }

            return (defaultIndexes[lhs.id] ?? .zero) < (defaultIndexes[rhs.id] ?? .zero)
        }
    }

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

private extension ItemInsightsCalculator {
    static func defaultOrderedItems(
        from items: [Item],
        kind: ItemListQuery.ListKind,
        referenceDate: Date,
        calendar: Calendar
    ) -> [Item] {
        switch kind {
        case .active:
            homeSort(
                items: activeItems(from: items),
                referenceDate: referenceDate,
                calendar: calendar
            )
        case .archived:
            archivedItems(from: items)
        }
    }

    static func summariesByID(
        for items: [Item],
        referenceDate: Date,
        calendar: Calendar
    ) -> [UUID: ItemSummary] {
        Dictionary(
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
    }

    static func matchesSearch(
        item: Item,
        searchText: String
    ) -> Bool {
        guard !searchText.isEmpty else {
            return true
        }

        return item.name.localizedCaseInsensitiveContains(searchText)
            || item.category.title.localizedCaseInsensitiveContains(searchText)
            || (item.note?.localizedCaseInsensitiveContains(searchText) == true)
    }

    static func matchesCategory(
        item: Item,
        category: ItemCategory?
    ) -> Bool {
        guard let category else {
            return true
        }

        return item.category == category
    }

    static func matchesQuickFilter(
        item: Item,
        summary: ItemSummary?,
        quickFilter: ItemListQuery.QuickFilter?
    ) -> Bool {
        guard let quickFilter else {
            return true
        }

        let totalMarks = summary?.totalMarks ?? item.marks.count
        let isMarkedOnReferenceDay = summary?.isMarkedToday == true

        switch quickFilter {
        case .markedOnReferenceDay:
            return isMarkedOnReferenceDay
        case .unmarkedOnReferenceDay:
            return !isMarkedOnReferenceDay
        case .withHistory:
            return totalMarks > .zero
        case .withoutHistory:
            return totalMarks == .zero
        }
    }

    static func compareDescending(
        _ lhs: Date?,
        _ rhs: Date?
    ) -> Bool {
        switch (lhs, rhs) {
        case let (left?, right?):
            left > right
        case (.some, .none):
            true
        case (.none, .some):
            false
        case (.none, .none):
            false
        }
    }

    static func archivedSort(
        lhs: Item,
        rhs: Item
    ) -> Bool {
        if lhs.archivedAt != rhs.archivedAt {
            return compareDescending(lhs.archivedAt, rhs.archivedAt)
        }

        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt > rhs.updatedAt
        }

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

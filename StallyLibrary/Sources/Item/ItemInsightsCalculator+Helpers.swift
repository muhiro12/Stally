import Foundation

extension ItemInsightsCalculator {
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

    static func filterItems(
        _ items: [Item],
        query: ItemListQuery,
        itemSummaries: [UUID: ItemSummary]
    ) -> [Item] {
        items.filter { item in
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
    }

    static func sortFilteredItems(
        _ filteredItems: [Item],
        query: ItemListQuery,
        referenceDate: Date,
        calendar: Calendar
    ) -> [Item] {
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
            compareSortedItems(
                lhs,
                rhs,
                sortOption: query.sortOption,
                summaries: summaries,
                defaultIndexes: defaultIndexes
            )
        }
    }

    static func compareSortedItems(
        _ lhs: Item,
        _ rhs: Item,
        sortOption: ItemListQuery.SortOption,
        summaries: [UUID: ItemSummary],
        defaultIndexes: [UUID: Int]
    ) -> Bool {
        switch sortOption {
        case .defaultOrder:
            break
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

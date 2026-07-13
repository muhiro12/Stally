//
//  ItemCollectionOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/13.
//

import Foundation

/// Cross-surface use cases for searching, filtering, and sorting item collections.
public enum ItemCollectionOperations {
    /// Applies the selected browse options while preserving the input order as
    /// the stable fallback for equal sort values.
    public static func items(
        from items: [Item],
        options: ItemCollectionOptions,
        today: LocalDay?,
        selectedDay: LocalDay? = nil
    ) -> [Item] {
        let searchText = options.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let positionedItems: [PositionedItem] = items.enumerated().compactMap { offset, item in
            let positionedItem = PositionedItem(
                offset: offset,
                item: item,
                markedDays: Set(item.marks.map(\.day))
            )

            guard matchesSearch(item, searchText: searchText),
                  matchesCategory(item, category: options.category),
                  matchesFilter(
                    positionedItem,
                    filter: options.filter,
                    today: today,
                    selectedDay: selectedDay
                  ) else {
                return nil
            }

            return positionedItem
        }

        guard options.sort != .defaultOrder else {
            return positionedItems.map(\.item)
        }

        return positionedItems
            .sorted { lhs, rhs in
                orderedBefore(lhs, rhs, sort: options.sort)
            }
            .map(\.item)
    }
}

private extension ItemCollectionOperations {
    struct PositionedItem {
        let offset: Int
        let item: Item
        let markedDays: Set<LocalDay>

        var latestMarkedDay: LocalDay? {
            markedDays.max()
        }
    }

    static func matchesSearch(
        _ item: Item,
        searchText: String
    ) -> Bool {
        guard !searchText.isEmpty else {
            return true
        }

        return item.name.localizedCaseInsensitiveContains(searchText)
            || item.note.localizedCaseInsensitiveContains(searchText)
    }

    static func matchesCategory(
        _ item: Item,
        category: ItemCategory?
    ) -> Bool {
        guard let category else {
            return true
        }

        return item.category == category
    }

    static func matchesFilter(
        _ item: PositionedItem,
        filter: ItemCollectionFilter,
        today: LocalDay?,
        selectedDay: LocalDay?
    ) -> Bool {
        switch filter {
        case .all:
            return true
        case .openToday:
            return today.map { !item.markedDays.contains($0) } ?? false
        case .markedToday:
            return today.map(item.markedDays.contains) ?? false
        case .openOnDay:
            return selectedDay.map { !item.markedDays.contains($0) } ?? false
        case .markedOnDay:
            return selectedDay.map(item.markedDays.contains) ?? false
        case .neverMarked, .withoutHistory:
            return item.markedDays.isEmpty
        case .withHistory:
            return !item.markedDays.isEmpty
        }
    }

    static func orderedBefore(
        _ lhs: PositionedItem,
        _ rhs: PositionedItem,
        sort: ItemCollectionSort
    ) -> Bool {
        switch sort {
        case .defaultOrder:
            return lhs.offset < rhs.offset
        case .recentlyMarked:
            if lhs.latestMarkedDay != rhs.latestMarkedDay {
                return compareOptionalDays(lhs.latestMarkedDay, rhs.latestMarkedDay)
            }
        case .mostMarked:
            if lhs.markedDays.count != rhs.markedDays.count {
                return lhs.markedDays.count > rhs.markedDays.count
            }
        case .name:
            let comparison = lhs.item.name.localizedStandardCompare(rhs.item.name)

            if comparison != .orderedSame {
                return comparison == .orderedAscending
            }
        case .category:
            let lhsIndex = ItemCategory.allCases.firstIndex(of: lhs.item.category)
            let rhsIndex = ItemCategory.allCases.firstIndex(of: rhs.item.category)

            if lhsIndex != rhsIndex {
                return (lhsIndex ?? ItemCategory.allCases.count)
                    < (rhsIndex ?? ItemCategory.allCases.count)
            }
        }

        return lhs.offset < rhs.offset
    }

    static func compareOptionalDays(
        _ lhs: LocalDay?,
        _ rhs: LocalDay?
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            return lhs > rhs
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return false
        }
    }
}

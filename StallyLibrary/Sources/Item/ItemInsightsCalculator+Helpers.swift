import Foundation

extension ItemInsightsCalculator {
    struct ActivityMarkRecord {
        let day: Date
        let itemID: UUID
        let category: ItemCategory
    }

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

    static func scopedItems(
        from items: [Item],
        includeArchivedItems: Bool
    ) -> [Item] {
        includeArchivedItems ? items : activeItems(from: items)
    }

    static func activityWindowStart(
        from items: [Item],
        range: ItemInsightsRange,
        referenceDate: Date,
        calendar: Calendar
    ) -> Date? {
        let referenceDay = DayStamp.storageDate(
            from: referenceDate,
            calendar: calendar
        )

        if let fixedDayCount = range.fixedDayCount {
            return calendar.date(
                byAdding: .day,
                value: -(fixedDayCount - 1),
                to: referenceDay
            )
        }

        let earliestMarkDay = items
            .flatMap(\.marks)
            .map(\.day)
            .min()
        let earliestCreatedDay = items
            .map { item in
                DayStamp.storageDate(
                    from: item.createdAt,
                    calendar: calendar
                )
            }
            .min()

        let candidateDays = [
            earliestMarkDay,
            earliestCreatedDay
        ]
        .compactMap { $0 }

        return candidateDays.min() ?? referenceDay
    }

    static func marksByDay(
        from items: [Item],
        startingAt windowStart: Date,
        endingAt windowEnd: Date,
        calendar: Calendar
    ) -> [Date: [ActivityMarkRecord]] {
        items.reduce(into: [:]) { partialResult, item in
            for mark in item.marks {
                let normalizedDay = DayStamp.storageDate(
                    from: mark.day,
                    calendar: calendar
                )
                guard normalizedDay >= windowStart, normalizedDay <= windowEnd else {
                    continue
                }

                partialResult[normalizedDay, default: []].append(
                    .init(
                        day: normalizedDay,
                        itemID: item.id,
                        category: item.category
                    )
                )
            }
        }
    }

    static func activityDaySeries(
        startingAt windowStart: Date,
        endingAt windowEnd: Date,
        marksByDay: [Date: [ActivityMarkRecord]],
        calendar: Calendar
    ) -> [CollectionActivityDay] {
        var days: [CollectionActivityDay] = []
        var cursor = windowStart

        while cursor <= windowEnd {
            let dayMarks = marksByDay[cursor] ?? []
            let uniqueItemIDs = Set(dayMarks.map(\.itemID))
            let uniqueCategories = Set(dayMarks.map(\.category))

            days.append(
                .init(
                    date: DayStamp.localDate(
                        from: cursor,
                        calendar: calendar
                    ),
                    markCount: dayMarks.count,
                    uniqueItemCount: uniqueItemIDs.count,
                    uniqueCategoryCount: uniqueCategories.count
                )
            )

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: cursor
            ) else {
                break
            }

            cursor = nextDay
        }

        return days
    }

    static func uniqueMarkedItemCount(
        from items: [Item],
        range: ItemInsightsRange,
        referenceDate: Date,
        calendar: Calendar
    ) -> Int {
        guard let windowStart = activityWindowStart(
            from: items,
            range: range,
            referenceDate: referenceDate,
            calendar: calendar
        ) else {
            return .zero
        }

        let windowEnd = DayStamp.storageDate(
            from: referenceDate,
            calendar: calendar
        )

        return Set(
            items.compactMap { item in
                item.marks.contains(where: { mark in
                    let day = DayStamp.storageDate(
                        from: mark.day,
                        calendar: calendar
                    )
                    return day >= windowStart && day <= windowEnd
                })
                    ? item.id
                    : nil
            }
        ).count
    }

    static func uniqueMarkedCategoryCount(
        from items: [Item],
        range: ItemInsightsRange,
        referenceDate: Date,
        calendar: Calendar
    ) -> Int {
        guard let windowStart = activityWindowStart(
            from: items,
            range: range,
            referenceDate: referenceDate,
            calendar: calendar
        ) else {
            return .zero
        }

        let windowEnd = DayStamp.storageDate(
            from: referenceDate,
            calendar: calendar
        )

        return Set(
            items.compactMap { item in
                item.marks.contains(where: { mark in
                    let day = DayStamp.storageDate(
                        from: mark.day,
                        calendar: calendar
                    )
                    return day >= windowStart && day <= windowEnd
                })
                    ? item.category
                    : nil
            }
        ).count
    }

    static func averageMarksPerActiveDay(
        totalMarks: Int,
        activeDays: Int
    ) -> Double {
        guard activeDays > .zero else {
            return .zero
        }

        return Double(totalMarks) / Double(activeDays)
    }

    static func currentStreakDays(
        from activityDays: [CollectionActivityDay]
    ) -> Int {
        activityDays.reversed().prefix { $0.isActive }.count
    }

    static func bestStreakDays(
        from activityDays: [CollectionActivityDay]
    ) -> Int {
        var bestStreak = 0
        var currentStreak = 0

        for activityDay in activityDays {
            if activityDay.isActive {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return bestStreak
    }

    static func longestIdleGapDays(
        from activityDays: [CollectionActivityDay]
    ) -> Int {
        var longestGap = 0
        var currentGap = 0
        var hasSeenActiveDay = false

        for activityDay in activityDays {
            if activityDay.isActive {
                if hasSeenActiveDay {
                    longestGap = max(longestGap, currentGap)
                }
                currentGap = 0
                hasSeenActiveDay = true
            } else if hasSeenActiveDay {
                currentGap += 1
            }
        }

        return longestGap
    }

    static func daysSinceLastActive(
        lastActiveDate: Date?,
        referenceDate: Date,
        calendar: Calendar
    ) -> Int? {
        guard let lastActiveDate else {
            return nil
        }

        let lastActiveDay = DayStamp.storageDate(
            from: lastActiveDate,
            calendar: calendar
        )
        let referenceDay = DayStamp.storageDate(
            from: referenceDate,
            calendar: calendar
        )

        return calendar.dateComponents(
            [.day],
            from: lastActiveDay,
            to: referenceDay
        ).day
    }
}

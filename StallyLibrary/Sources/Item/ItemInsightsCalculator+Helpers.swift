import Foundation

extension ItemInsightsCalculator {
    struct ActivityMarkRecord {
        let day: Date
        let itemID: UUID
        let category: ItemCategory
    }

    struct CategoryRecord {
        var markCount = 0
        var uniqueItemIDs = Set<UUID>()
        var lastMarkedAt: Date?
    }

    struct WeekdayRecord {
        var markCount = 0
        var activeDays = 0
    }

    struct WeekRecord {
        var markCount = 0
        var activeDays = 0
    }

    struct MonthRecord {
        var markCount = 0
        var activeDays = 0
        var uniqueItemIDs = Set<UUID>()
        var uniqueCategories = Set<ItemCategory>()
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

    static func compareAscending(
        _ lhs: Date?,
        _ rhs: Date?
    ) -> Bool {
        switch (lhs, rhs) {
        case let (left?, right?):
            left < right
        case (.none, .some):
            true
        case (.some, .none):
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

    static func categoryRecords(
        from items: [Item],
        startingAt windowStart: Date,
        endingAt windowEnd: Date,
        calendar: Calendar
    ) -> [ItemCategory: CategoryRecord] {
        items.reduce(into: [:]) { partialResult, item in
            for mark in item.marks {
                let normalizedDay = DayStamp.storageDate(
                    from: mark.day,
                    calendar: calendar
                )
                guard normalizedDay >= windowStart, normalizedDay <= windowEnd else {
                    continue
                }

                partialResult[item.category, default: .init()].markCount += 1
                partialResult[item.category, default: .init()].uniqueItemIDs.insert(item.id)

                let currentLastMarkedAt = partialResult[item.category, default: .init()].lastMarkedAt
                if currentLastMarkedAt == nil || normalizedDay > currentLastMarkedAt! {
                    partialResult[item.category, default: .init()].lastMarkedAt = normalizedDay
                }
            }
        }
    }

    static func shareOfMarks(
        totalMarks: Int,
        categoryMarks: Int
    ) -> Double {
        guard totalMarks > .zero else {
            return .zero
        }

        return Double(categoryMarks) / Double(totalMarks)
    }

    static func averagePerUnit(
        total: Int,
        count: Int
    ) -> Double {
        guard count > .zero else {
            return .zero
        }

        return Double(total) / Double(count)
    }

    static func fraction(
        numerator: Int,
        denominator: Int
    ) -> Double {
        guard denominator > .zero else {
            return .zero
        }

        return Double(numerator) / Double(denominator)
    }

    static func weekdaySummaries(
        from activityDays: [CollectionActivityDay],
        totalMarks: Int,
        calendar: Calendar
    ) -> [CollectionWeekdaySummary] {
        let weekdayRecords = activityDays.reduce(into: [Int: WeekdayRecord]()) { partialResult, day in
            let weekday = calendar.component(.weekday, from: day.date)
            partialResult[weekday, default: .init()].markCount += day.markCount

            if day.isActive {
                partialResult[weekday, default: .init()].activeDays += 1
            }
        }

        return orderedWeekdays(calendar: calendar).map { weekday in
            let record = weekdayRecords[weekday, default: .init()]

            return .init(
                weekday: weekday,
                title: weekdayTitle(
                    for: weekday,
                    calendar: calendar
                ),
                shortTitle: shortWeekdayTitle(
                    for: weekday,
                    calendar: calendar
                ),
                markCount: record.markCount,
                activeDays: record.activeDays,
                shareOfMarks: shareOfMarks(
                    totalMarks: totalMarks,
                    categoryMarks: record.markCount
                )
            )
        }
    }

    static func weekRecords(
        from activityDays: [CollectionActivityDay],
        calendar: Calendar
    ) -> [Date: WeekRecord] {
        activityDays.reduce(into: [:]) { partialResult, day in
            guard let weekStart = calendar.dateInterval(
                of: .weekOfYear,
                for: day.date
            )?.start else {
                return
            }

            partialResult[weekStart, default: .init()].markCount += day.markCount
            if day.isActive {
                partialResult[weekStart, default: .init()].activeDays += 1
            }
        }
    }

    static func orderedWeekdays(
        calendar: Calendar
    ) -> [Int] {
        let start = calendar.firstWeekday

        return (0..<7).map { offset in
            ((start - 1 + offset) % 7) + 1
        }
    }

    static func weekdayTitle(
        for weekday: Int,
        calendar: Calendar
    ) -> String {
        calendar.weekdaySymbols[weekday - 1]
    }

    static func shortWeekdayTitle(
        for weekday: Int,
        calendar: Calendar
    ) -> String {
        calendar.shortWeekdaySymbols[weekday - 1]
    }

    static func weekdayReferenceDate(
        for weekday: Int,
        calendar: Calendar
    ) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.year = 2_026
        components.month = 3
        components.day = 1
        components.hour = 12

        let baseDate = components.date ?? .now
        let baseWeekday = calendar.component(.weekday, from: baseDate)
        let delta = weekday - baseWeekday

        return calendar.date(
            byAdding: .day,
            value: delta,
            to: baseDate
        ) ?? baseDate
    }

    static func rankedItems(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool,
        limit: Int,
        referenceDate: Date,
        calendar: Calendar,
        order: (CollectionItemRanking, CollectionItemRanking) -> Bool
    ) -> [CollectionItemRanking] {
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

        let windowEnd = DayStamp.storageDate(
            from: referenceDate,
            calendar: calendar
        )

        return scopedItems
            .map { item in
                let marksInRange = item.marks.filter { mark in
                    let normalizedDay = DayStamp.storageDate(
                        from: mark.day,
                        calendar: calendar
                    )
                    return normalizedDay >= windowStart && normalizedDay <= windowEnd
                }
                let lastMarkedAt = item.marks
                    .map(\.day)
                    .max()
                    .map { storageDay in
                        DayStamp.localDate(
                            from: storageDay,
                            calendar: calendar
                        )
                    }

                return CollectionItemRanking(
                    itemID: item.id,
                    totalMarksInRange: marksInRange.count,
                    activeDaysInRange: Set(marksInRange.map(\.day)).count,
                    totalLifetimeMarks: item.marks.count,
                    lastMarkedAt: lastMarkedAt,
                    isArchived: item.isArchived
                )
            }
            .sorted(by: order)
            .prefix(max(limit, .zero))
            .map { $0 }
    }

    static func monthlySummaries(
        startingAt windowStart: Date,
        endingAt windowEnd: Date,
        marksByDay: [Date: [ActivityMarkRecord]],
        calendar: Calendar
    ) -> [CollectionMonthSummary] {
        guard let firstMonthStart = calendar.dateInterval(
            of: .month,
            for: windowStart
        )?.start,
        let lastMonthStart = calendar.dateInterval(
            of: .month,
            for: windowEnd
        )?.start else {
            return []
        }

        let monthFormatter = monthTitleFormatter(calendar: calendar)
        var records = [Date: MonthRecord]()
        for (day, marks) in marksByDay {
            guard let monthStart = calendar.dateInterval(
                of: .month,
                for: day
            )?.start else {
                continue
            }

            records[monthStart, default: .init()].markCount += marks.count
            records[monthStart, default: .init()].activeDays += 1
            records[monthStart, default: .init()].uniqueItemIDs.formUnion(
                marks.map(\.itemID)
            )
            records[monthStart, default: .init()].uniqueCategories.formUnion(
                marks.map(\.category)
            )
        }

        var summaries: [CollectionMonthSummary] = []
        var cursor = firstMonthStart
        while cursor <= lastMonthStart {
            let record = records[cursor, default: .init()]

            summaries.append(
                .init(
                    monthStart: cursor,
                    monthTitle: monthFormatter.string(from: cursor),
                    markCount: record.markCount,
                    activeDays: record.activeDays,
                    uniqueItems: record.uniqueItemIDs.count,
                    uniqueCategories: record.uniqueCategories.count,
                    averageMarksPerActiveDay: averagePerUnit(
                        total: record.markCount,
                        count: record.activeDays
                    )
                )
            )

            guard let nextMonth = calendar.date(
                byAdding: .month,
                value: 1,
                to: cursor
            ) else {
                break
            }

            cursor = nextMonth
        }

        return summaries
    }

    static func monthTitleFormatter(
        calendar: Calendar
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        return formatter
    }
}

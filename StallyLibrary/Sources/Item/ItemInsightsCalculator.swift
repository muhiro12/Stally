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

    /// Builds streak values for the selected insight range.
    public static func streakSummary(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> CollectionStreakSummary {
        let activityDays = activityDays(
            from: items,
            range: range,
            includeArchivedItems: includeArchivedItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let activeDays = activityDays.filter(\.isActive)
        let lastActiveDate = activeDays.last?.date

        return .init(
            range: range,
            currentStreakDays: currentStreakDays(
                from: activityDays
            ),
            bestStreakDays: bestStreakDays(
                from: activityDays
            ),
            longestIdleGapDays: longestIdleGapDays(
                from: activityDays
            ),
            daysSinceLastActive: daysSinceLastActive(
                lastActiveDate: lastActiveDate,
                referenceDate: referenceDate,
                calendar: calendar
            ),
            lastActiveDate: lastActiveDate
        )
    }

    /// Builds a sorted mark breakdown by category for the selected insight range.
    public static func categorySummaries(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [CollectionCategorySummary] {
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
        let categoryRecords = categoryRecords(
            from: scopedItems,
            startingAt: windowStart,
            endingAt: windowEnd,
            calendar: calendar
        )
        let totalMarks = categoryRecords.reduce(into: .zero) { partialResult, pair in
            partialResult += pair.value.markCount
        }

        return categoryRecords
            .map { category, record in
                .init(
                    category: category,
                    totalMarks: record.markCount,
                    uniqueItems: record.uniqueItemIDs.count,
                    shareOfMarks: shareOfMarks(
                        totalMarks: totalMarks,
                        categoryMarks: record.markCount
                    ),
                    lastMarkedAt: record.lastMarkedAt.map { storageDay in
                        DayStamp.localDate(
                            from: storageDay,
                            calendar: calendar
                        )
                    }
                )
            }
            .sorted { lhs, rhs in
                if lhs.totalMarks != rhs.totalMarks {
                    return lhs.totalMarks > rhs.totalMarks
                }

                if lhs.lastMarkedAt != rhs.lastMarkedAt {
                    return compareDescending(
                        lhs.lastMarkedAt,
                        rhs.lastMarkedAt
                    )
                }

                return lhs.category.title.localizedCaseInsensitiveCompare(rhs.category.title) == .orderedAscending
            }
    }

    /// Builds descending item rankings for the selected insight range.
    public static func topItemRankings(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        limit: Int = 5,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [CollectionItemRanking] {
        rankedItems(
            from: items,
            range: range,
            includeArchivedItems: includeArchivedItems,
            limit: limit,
            referenceDate: referenceDate,
            calendar: calendar
        ) { lhs, rhs in
            if lhs.totalMarksInRange != rhs.totalMarksInRange {
                return lhs.totalMarksInRange > rhs.totalMarksInRange
            }

            if lhs.activeDaysInRange != rhs.activeDaysInRange {
                return lhs.activeDaysInRange > rhs.activeDaysInRange
            }

            return compareDescending(
                lhs.lastMarkedAt,
                rhs.lastMarkedAt
            )
        }
    }

    /// Builds quiet-item rankings for the selected insight range.
    public static func quietItemRankings(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        limit: Int = 5,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [CollectionItemRanking] {
        rankedItems(
            from: items,
            range: range,
            includeArchivedItems: includeArchivedItems,
            limit: limit,
            referenceDate: referenceDate,
            calendar: calendar
        ) { lhs, rhs in
            if lhs.totalMarksInRange != rhs.totalMarksInRange {
                return lhs.totalMarksInRange < rhs.totalMarksInRange
            }

            if lhs.lastMarkedAt != rhs.lastMarkedAt {
                return compareAscending(
                    lhs.lastMarkedAt,
                    rhs.lastMarkedAt
                )
            }

            return lhs.totalLifetimeMarks < rhs.totalLifetimeMarks
        }
    }

    /// Builds weekday-level mark summaries for the selected insight range.
    public static func weekdaySummaries(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [CollectionWeekdaySummary] {
        let activityDays = activityDays(
            from: items,
            range: range,
            includeArchivedItems: includeArchivedItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let totalMarks = activityDays.reduce(into: .zero) { partialResult, day in
            partialResult += day.markCount
        }

        return weekdaySummaries(
            from: activityDays,
            totalMarks: totalMarks,
            calendar: calendar
        )
    }

    /// Builds weekly cadence metrics for the selected insight range.
    public static func cadenceSummary(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> CollectionCadenceSummary {
        let activityDays = activityDays(
            from: items,
            range: range,
            includeArchivedItems: includeArchivedItems,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let weekRecords = weekRecords(
            from: activityDays,
            calendar: calendar
        )
        let totalMarks = activityDays.reduce(into: .zero) { partialResult, day in
            partialResult += day.markCount
        }
        let totalActiveDays = activityDays.filter(\.isActive).count
        let weekdaySummaries = weekdaySummaries(
            from: activityDays,
            totalMarks: totalMarks,
            calendar: calendar
        )
        let weekendMarks = weekdaySummaries
            .filter { summary in
                calendar.isDateInWeekend(
                    weekdayReferenceDate(
                        for: summary.weekday,
                        calendar: calendar
                    )
                )
            }
            .reduce(into: .zero) { partialResult, summary in
                partialResult += summary.markCount
            }
        let weekdayMarks = max(totalMarks - weekendMarks, .zero)
        let totalWeeks = weekRecords.count
        let activeWeeks = weekRecords.values.filter { record in
            record.markCount > .zero
        }.count
        let busiestWeekStart = weekRecords.max { lhs, rhs in
            if lhs.value.markCount != rhs.value.markCount {
                return lhs.value.markCount < rhs.value.markCount
            }

            return lhs.key < rhs.key
        }?.key

        return .init(
            range: range,
            totalWeeks: totalWeeks,
            activeWeeks: activeWeeks,
            averageMarksPerWeek: averagePerUnit(
                total: totalMarks,
                count: totalWeeks
            ),
            averageActiveDaysPerWeek: averagePerUnit(
                total: totalActiveDays,
                count: totalWeeks
            ),
            weekdayMarks: weekdayMarks,
            weekendMarks: weekendMarks,
            weekendShareOfMarks: shareOfMarks(
                totalMarks: totalMarks,
                categoryMarks: weekendMarks
            ),
            consistencyScore: fraction(
                numerator: activeWeeks,
                denominator: totalWeeks
            ),
            busiestWeekStart: busiestWeekStart
        )
    }

    /// Builds contiguous monthly summaries for the selected insight range.
    public static func monthlySummaries(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [CollectionMonthSummary] {
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
        let groupedMarks = marksByDay(
            from: scopedItems,
            startingAt: windowStart,
            endingAt: windowEnd,
            calendar: calendar
        )

        return monthlySummaries(
            startingAt: windowStart,
            endingAt: windowEnd,
            marksByDay: groupedMarks,
            calendar: calendar
        )
    }

    /// Builds high-level collection health metrics for the selected insight range.
    public static func healthSummary(
        from items: [Item],
        range: ItemInsightsRange,
        includeArchivedItems: Bool = true,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> CollectionHealthSummary {
        let scopedItems = scopedItems(
            from: items,
            includeArchivedItems: includeArchivedItems
        )
        let activeItems = activeItems(from: scopedItems)
        let archivedItems = scopedItems.count - activeItems.count
        let itemsWithHistory = scopedItems.filter { item in
            !item.marks.isEmpty
        }.count
        let itemsWithNotes = scopedItems.filter { item in
            let note = item.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !note.isEmpty
        }.count
        let itemsWithPhotos = scopedItems.filter { item in
            item.photoData != nil
        }.count
        let recentlyAddedCount = recentlyAddedCount(
            from: scopedItems,
            range: range,
            referenceDate: referenceDate,
            calendar: calendar
        )

        return .init(
            range: range,
            totalItems: scopedItems.count,
            activeItems: activeItems.count,
            archivedItems: archivedItems,
            itemsWithHistory: itemsWithHistory,
            itemsWithNotes: itemsWithNotes,
            itemsWithPhotos: itemsWithPhotos,
            historyCoverage: fraction(
                numerator: itemsWithHistory,
                denominator: scopedItems.count
            ),
            noteCoverage: fraction(
                numerator: itemsWithNotes,
                denominator: scopedItems.count
            ),
            photoCoverage: fraction(
                numerator: itemsWithPhotos,
                denominator: scopedItems.count
            ),
            archivedShare: fraction(
                numerator: archivedItems,
                denominator: scopedItems.count
            ),
            averageItemAgeDays: averageItemAgeDays(
                from: scopedItems,
                referenceDate: referenceDate,
                calendar: calendar
            ),
            recentlyAddedCount: recentlyAddedCount
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

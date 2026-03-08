import Foundation

/// Derives review-oriented snapshots and summaries from items.
public enum ItemReviewCalculator {
    /// Builds a review snapshot for one item.
    public static func snapshot(
        for item: Item,
        policy: ItemReviewPolicy = .init(),
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> ItemReviewSnapshot {
        let insightSummary = ItemInsightsCalculator.summary(
            for: item,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let daysSinceCreated = elapsedDays(
            since: item.createdAt,
            until: referenceDate,
            calendar: calendar
        )
        let daysSinceLastMark = insightSummary.lastMarkedAt.map { lastMarkedAt in
            elapsedDays(
                since: lastMarkedAt,
                until: referenceDate,
                calendar: calendar
            )
        }

        return .init(
            itemID: item.id,
            status: status(
                for: item,
                totalMarks: insightSummary.totalMarks,
                daysSinceCreated: daysSinceCreated,
                daysSinceLastMark: daysSinceLastMark,
                policy: policy
            ),
            totalMarks: insightSummary.totalMarks,
            createdAt: item.createdAt,
            archivedAt: item.archivedAt,
            lastMarkedAt: insightSummary.lastMarkedAt,
            daysSinceCreated: daysSinceCreated,
            daysSinceLastMark: daysSinceLastMark
        )
    }

    /// Builds review snapshots for all items.
    public static func snapshots(
        from items: [Item],
        policy: ItemReviewPolicy = .init(),
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [ItemReviewSnapshot] {
        items.map { item in
            snapshot(
                for: item,
                policy: policy,
                referenceDate: referenceDate,
                calendar: calendar
            )
        }
    }

    /// Filters items by one review status.
    public static func items(
        from items: [Item],
        with status: ItemReviewStatus,
        policy: ItemReviewPolicy = .init(),
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [Item] {
        let snapshotsByID = Dictionary(
            uniqueKeysWithValues: snapshots(
                from: items,
                policy: policy,
                referenceDate: referenceDate,
                calendar: calendar
            ).map { snapshot in
                (snapshot.itemID, snapshot)
            }
        )

        return items.filter { item in
            snapshotsByID[item.id]?.status == status
        }
    }

    /// Summarizes review counts for all items.
    public static func summary(
        from items: [Item],
        policy: ItemReviewPolicy = .init(),
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> ItemReviewSummary {
        let snapshots = snapshots(
            from: items,
            policy: policy,
            referenceDate: referenceDate,
            calendar: calendar
        )

        return .init(
            totalItems: snapshots.count,
            untouchedCount: count(of: .untouched, in: snapshots),
            dormantCount: count(of: .dormant, in: snapshots),
            healthyCount: count(of: .healthy, in: snapshots),
            recoveryCandidateCount: count(of: .recoveryCandidate, in: snapshots),
            coldArchiveCount: count(of: .coldArchive, in: snapshots)
        )
    }
}

private extension ItemReviewCalculator {
    static func status(
        for item: Item,
        totalMarks: Int,
        daysSinceCreated: Int,
        daysSinceLastMark: Int?,
        policy: ItemReviewPolicy
    ) -> ItemReviewStatus {
        if item.isArchived {
            return totalMarks > .zero ? .recoveryCandidate : .coldArchive
        }

        if totalMarks == .zero {
            return daysSinceCreated >= policy.untouchedGraceDays
                ? .untouched
                : .healthy
        }

        if let daysSinceLastMark,
           daysSinceLastMark >= policy.dormantAfterDays {
            return .dormant
        }

        return .healthy
    }

    static func elapsedDays(
        since startDate: Date,
        until endDate: Date,
        calendar: Calendar
    ) -> Int {
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.startOfDay(for: endDate)

        return max(
            .zero,
            calendar.dateComponents([.day], from: startOfDay, to: endOfDay).day ?? .zero
        )
    }

    static func count(
        of status: ItemReviewStatus,
        in snapshots: [ItemReviewSnapshot]
    ) -> Int {
        snapshots.reduce(into: .zero) { partialResult, snapshot in
            if snapshot.status == status {
                partialResult += 1
            }
        }
    }
}

import Foundation

public enum ItemReviewStatus: String, CaseIterable, Equatable, Sendable {
    case untouched
    case dormant
    case healthy
    case recoveryCandidate
    case coldArchive

    public var needsReview: Bool {
        switch self {
        case .untouched, .dormant, .recoveryCandidate:
            true
        case .healthy, .coldArchive:
            false
        }
    }
}

public struct ItemReviewPolicy: Codable, Equatable, Sendable {
    public let untouchedGraceDays: Int
    public let dormantAfterDays: Int

    public init(
        untouchedGraceDays: Int = 14,
        dormantAfterDays: Int = 30
    ) {
        self.untouchedGraceDays = max(1, untouchedGraceDays)
        self.dormantAfterDays = max(1, dormantAfterDays)
    }
}

public struct ItemReviewSnapshot: Equatable, Identifiable, Sendable {
    public let itemID: UUID
    public let status: ItemReviewStatus
    public let totalMarks: Int
    public let createdAt: Date
    public let archivedAt: Date?
    public let lastMarkedAt: Date?
    public let daysSinceCreated: Int
    public let daysSinceLastMark: Int?

    public var id: UUID {
        itemID
    }

    public var needsReview: Bool {
        status.needsReview
    }
}

public struct ItemReviewSummary: Equatable, Sendable {
    public let totalItems: Int
    public let untouchedCount: Int
    public let dormantCount: Int
    public let healthyCount: Int
    public let recoveryCandidateCount: Int
    public let coldArchiveCount: Int

    public var totalReviewCount: Int {
        untouchedCount + dormantCount + recoveryCandidateCount
    }

    public var activeReviewCount: Int {
        untouchedCount + dormantCount
    }
}

public enum ItemReviewCalculator {
    public static func snapshot(
        for item: Item,
        policy: ItemReviewPolicy = .init(),
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> ItemReviewSnapshot {
        let summary = ItemInsightsCalculator.summary(
            for: item,
            referenceDate: referenceDate,
            calendar: calendar
        )
        let daysSinceCreated = elapsedDays(
            since: item.createdAt,
            until: referenceDate,
            calendar: calendar
        )
        let daysSinceLastMark = summary.lastMarkedAt.map { lastMarkedAt in
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
                totalMarks: summary.totalMarks,
                daysSinceCreated: daysSinceCreated,
                daysSinceLastMark: daysSinceLastMark,
                policy: policy
            ),
            totalMarks: summary.totalMarks,
            createdAt: item.createdAt,
            archivedAt: item.archivedAt,
            lastMarkedAt: summary.lastMarkedAt,
            daysSinceCreated: daysSinceCreated,
            daysSinceLastMark: daysSinceLastMark
        )
    }

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

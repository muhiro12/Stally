//
//  ReviewOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import SwiftData

/// Cross-surface Review use cases for attention lanes.
public enum ReviewOperations {
    /// Applies the lane's primary next step to one item.
    @discardableResult
    public static func performPrimaryAction(
        for item: Item,
        in lane: ReviewLane,
        context: ModelContext,
        on date: Date = .now
    ) throws -> Bool {
        try performPrimaryActions(
            [.init(item: item, lane: lane)],
            context: context,
            on: date
        ) == 1
    }

    /// Applies every requested lane action and saves them as one transaction.
    @discardableResult
    public static func performPrimaryActions(
        _ requests: [ReviewActionRequest],
        context: ModelContext,
        on date: Date = .now
    ) throws -> Int {
        try performPrimaryActions(requests, on: date, context: context) { context in
            try context.save()
        }
    }

    /// Builds the current Review lane snapshot.
    public static func snapshot(
        for items: [Item],
        settings: ReviewSettings = .default,
        timeZone: TimeZone = .current,
        now: Date = .now
    ) -> ReviewSnapshot {
        guard let today = LocalDay(containing: now, in: timeZone) else {
            return .init(
                needsFirstMark: [],
                dormant: [],
                recoveryCandidates: []
            )
        }

        return .init(
            needsFirstMark: needsFirstMarkItems(
                from: items,
                settings: settings,
                today: today,
                timeZone: timeZone
            ),
            dormant: dormantItems(
                from: items,
                settings: settings,
                today: today,
                timeZone: timeZone
            ),
            recoveryCandidates: recoveryCandidates(
                from: items,
                settings: settings,
                today: today,
                timeZone: timeZone
            )
        )
    }

    private static func needsFirstMarkItems(
        from items: [Item],
        settings: ReviewSettings,
        today: LocalDay,
        timeZone: TimeZone
    ) -> [Item] {
        items
            .filter { item in
                isNeedsFirstMarkCandidate(
                    item,
                    settings: settings,
                    today: today,
                    timeZone: timeZone
                )
            }
            .sorted { lhsItem, rhsItem in
                isEarlier(
                    lhsItem.createdAt,
                    than: rhsItem.createdAt,
                    timeZone: timeZone
                )
            }
    }

    static func performPrimaryActions(
        _ requests: [ReviewActionRequest],
        on date: Date,
        context: ModelContext,
        saving save: (ModelContext) throws -> Void
    ) throws -> Int {
        var changedItemIDs = Set<UUID>()

        for request in requests where !changedItemIDs.contains(request.item.uuid) {
            switch request.lane {
            case .dormant, .needsFirstMark:
                guard !request.item.isArchived else {
                    continue
                }

                request.item.archivedAt = date
            case .recoveryCandidates:
                guard request.item.isArchived else {
                    continue
                }

                request.item.archivedAt = nil
            }

            changedItemIDs.insert(request.item.uuid)
        }

        guard !changedItemIDs.isEmpty else {
            return 0
        }

        do {
            try save(context)
            return changedItemIDs.count
        } catch {
            context.rollback()
            throw error
        }
    }

    private static func dormantItems(
        from items: [Item],
        settings: ReviewSettings,
        today: LocalDay,
        timeZone: TimeZone
    ) -> [Item] {
        items
            .filter { item in
                isDormantCandidate(
                    item,
                    settings: settings,
                    today: today
                )
            }
            .sorted { lhsItem, rhsItem in
                let lhsLastMarkedDay = lastRelevantDay(
                    for: lhsItem,
                    today: today,
                    timeZone: timeZone
                )
                let rhsLastMarkedDay = lastRelevantDay(
                    for: rhsItem,
                    today: today,
                    timeZone: timeZone
                )

                if let lhsLastMarkedDay,
                   let rhsLastMarkedDay,
                   lhsLastMarkedDay != rhsLastMarkedDay {
                    return lhsLastMarkedDay < rhsLastMarkedDay
                }

                return lhsItem.createdAt < rhsItem.createdAt
            }
    }

    private static func recoveryCandidates(
        from items: [Item],
        settings: ReviewSettings,
        today: LocalDay,
        timeZone: TimeZone
    ) -> [Item] {
        items
            .filter { item in
                isRecoveryCandidate(
                    item,
                    settings: settings,
                    today: today
                )
            }
            .sorted { lhsItem, rhsItem in
                let lhsReferenceDate = lhsItem.archivedAt ?? lhsItem.createdAt
                let rhsReferenceDate = rhsItem.archivedAt ?? rhsItem.createdAt
                let lhsReferenceDay = LocalDay(containing: lhsReferenceDate, in: timeZone)
                let rhsReferenceDay = LocalDay(containing: rhsReferenceDate, in: timeZone)
                let lhsHistory = ItemOperations.historySnapshot(for: lhsItem, today: today)
                let rhsHistory = ItemOperations.historySnapshot(for: rhsItem, today: today)

                if lhsHistory.totalMarks == rhsHistory.totalMarks {
                    if let lhsReferenceDay,
                       let rhsReferenceDay,
                       lhsReferenceDay != rhsReferenceDay {
                        return lhsReferenceDay > rhsReferenceDay
                    }

                    return lhsReferenceDate > rhsReferenceDate
                }

                return lhsHistory.totalMarks > rhsHistory.totalMarks
            }
    }

    private static func isNeedsFirstMarkCandidate(
        _ item: Item,
        settings: ReviewSettings,
        today: LocalDay,
        timeZone: TimeZone
    ) -> Bool {
        guard !item.isArchived else {
            return false
        }

        let history = ItemOperations.historySnapshot(for: item, today: today)

        guard history.totalMarks == 0,
              let createdDay = LocalDay(containing: item.createdAt, in: timeZone) else {
            return false
        }

        return daysSince(createdDay, today: today) >= settings.needsFirstMarkAfterDays
    }

    private static func isDormantCandidate(
        _ item: Item,
        settings: ReviewSettings,
        today: LocalDay
    ) -> Bool {
        guard !item.isArchived else {
            return false
        }

        let history = ItemOperations.historySnapshot(for: item, today: today)

        guard let daysSinceLastMark = history.daysSinceLastMark else {
            return false
        }

        return daysSinceLastMark >= settings.dormantAfterDays
    }

    private static func isRecoveryCandidate(
        _ item: Item,
        settings: ReviewSettings,
        today: LocalDay
    ) -> Bool {
        guard item.isArchived else {
            return false
        }

        let history = ItemOperations.historySnapshot(for: item, today: today)
        return history.totalMarks >= settings.recoveryMinimumMarks
    }

    private static func lastRelevantDay(
        for item: Item,
        today: LocalDay,
        timeZone: TimeZone
    ) -> LocalDay? {
        ItemOperations.historySnapshot(for: item, today: today).lastMarkedDay
            ?? LocalDay(containing: item.createdAt, in: timeZone)
    }

    private static func isEarlier(
        _ lhsDate: Date,
        than rhsDate: Date,
        timeZone: TimeZone
    ) -> Bool {
        let lhsDay = LocalDay(containing: lhsDate, in: timeZone)
        let rhsDay = LocalDay(containing: rhsDate, in: timeZone)

        if let lhsDay,
           let rhsDay,
           lhsDay != rhsDay {
            return lhsDay < rhsDay
        }

        return lhsDate < rhsDate
    }

    private static func daysSince(
        _ startDay: LocalDay,
        today: LocalDay
    ) -> Int {
        max(0, startDay.distance(to: today))
    }
}

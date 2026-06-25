//
//  ReviewOperations.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Cross-surface Review use cases for attention lanes.
public enum ReviewOperations {
    /// Builds the current Review lane snapshot.
    public static func snapshot(
        for items: [Item],
        settings: ReviewSettings = .default,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> ReviewSnapshot {
        let needsFirstMark = items
            .filter { item in
                isNeedsFirstMarkCandidate(
                    item,
                    settings: settings,
                    calendar: calendar,
                    now: now
                )
            }
            .sorted { lhsItem, rhsItem in
                lhsItem.createdAt < rhsItem.createdAt
            }
        let dormant = items
            .filter { item in
                isDormantCandidate(
                    item,
                    settings: settings,
                    calendar: calendar,
                    now: now
                )
            }
            .sorted { lhsItem, rhsItem in
                let lhsLastMarkedDay = lastMarkedDay(for: lhsItem, calendar: calendar, now: now) ?? lhsItem.createdAt
                let rhsLastMarkedDay = lastMarkedDay(for: rhsItem, calendar: calendar, now: now) ?? rhsItem.createdAt
                return lhsLastMarkedDay < rhsLastMarkedDay
            }
        let recoveryCandidates = items
            .filter { item in
                isRecoveryCandidate(
                    item,
                    settings: settings,
                    calendar: calendar,
                    now: now
                )
            }
            .sorted { lhsItem, rhsItem in
                let lhsHistory = ItemOperations.historySnapshot(for: lhsItem, calendar: calendar, now: now)
                let rhsHistory = ItemOperations.historySnapshot(for: rhsItem, calendar: calendar, now: now)

                if lhsHistory.totalMarks == rhsHistory.totalMarks {
                    return (lhsItem.archivedAt ?? lhsItem.createdAt) > (rhsItem.archivedAt ?? rhsItem.createdAt)
                }

                return lhsHistory.totalMarks > rhsHistory.totalMarks
            }

        return .init(
            needsFirstMark: needsFirstMark,
            dormant: dormant,
            recoveryCandidates: recoveryCandidates
        )
    }

    private static func isNeedsFirstMarkCandidate(
        _ item: Item,
        settings: ReviewSettings,
        calendar: Calendar,
        now: Date
    ) -> Bool {
        guard !item.isArchived else {
            return false
        }

        let history = ItemOperations.historySnapshot(for: item, calendar: calendar, now: now)

        guard history.totalMarks == 0 else {
            return false
        }

        return daysSince(item.createdAt, calendar: calendar, now: now) >= settings.needsFirstMarkAfterDays
    }

    private static func isDormantCandidate(
        _ item: Item,
        settings: ReviewSettings,
        calendar: Calendar,
        now: Date
    ) -> Bool {
        guard !item.isArchived else {
            return false
        }

        let history = ItemOperations.historySnapshot(for: item, calendar: calendar, now: now)

        guard let daysSinceLastMark = history.daysSinceLastMark else {
            return false
        }

        return daysSinceLastMark >= settings.dormantAfterDays
    }

    private static func isRecoveryCandidate(
        _ item: Item,
        settings: ReviewSettings,
        calendar: Calendar,
        now: Date
    ) -> Bool {
        guard item.isArchived else {
            return false
        }

        let history = ItemOperations.historySnapshot(for: item, calendar: calendar, now: now)
        return history.totalMarks >= settings.recoveryMinimumMarks
    }

    private static func lastMarkedDay(
        for item: Item,
        calendar: Calendar,
        now: Date
    ) -> Date? {
        ItemOperations.historySnapshot(for: item, calendar: calendar, now: now).lastMarkedDay
    }

    private static func daysSince(
        _ date: Date,
        calendar: Calendar,
        now: Date
    ) -> Int {
        let startDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: startDay, to: today).day ?? 0
    }
}

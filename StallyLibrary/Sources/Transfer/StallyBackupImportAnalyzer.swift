import Foundation

/// Validates backup snapshots before import.
public enum StallyBackupImportAnalyzer {
    /// Analyzes one snapshot against the current local item identifiers.
    public static func analyze(
        snapshot: StallyBackupSnapshot,
        existingItemIDs: Set<UUID> = []
    ) -> StallyBackupImportAnalysis {
        .init(
            snapshot: snapshot,
            summary: makeSummary(
                snapshot: snapshot,
                existingItemIDs: existingItemIDs
            ),
            issues: makeIssues(snapshot: snapshot)
        )
    }
}

private extension StallyBackupImportAnalyzer {
    static func makeSummary(
        snapshot: StallyBackupSnapshot,
        existingItemIDs: Set<UUID>
    ) -> StallyBackupImportAnalysisSummary {
        let totalItems = snapshot.items.count
        let archivedItems = snapshot.items.filter(\.isArchived).count
        let totalMarks = snapshot.items.reduce(into: 0) { partialResult, item in
            partialResult += item.marks.count
        }
        let existingItems = snapshot.items.reduce(into: 0) { partialResult, item in
            if existingItemIDs.contains(item.id) {
                partialResult += 1
            }
        }

        return .init(
            totalItems: totalItems,
            archivedItems: archivedItems,
            totalMarks: totalMarks,
            existingItems: existingItems,
            newItems: totalItems - existingItems
        )
    }

    static func makeIssues(
        snapshot: StallyBackupSnapshot
    ) -> [StallyBackupImportIssue] {
        let issues =
            schemaIssues(snapshot: snapshot)
            + duplicateAndCategoryIssues(snapshot: snapshot)

        return issues.sorted(by: issueSort)
    }

    static func schemaIssues(
        snapshot: StallyBackupSnapshot
    ) -> [StallyBackupImportIssue] {
        guard snapshot.schemaVersion != StallyBackupSnapshot.currentSchemaVersion else {
            return []
        }

        return [
            .init(
                severity: .error,
                code: .unsupportedSchemaVersion,
                message: "Backup schema version \(snapshot.schemaVersion) is unsupported."
            )
        ]
    }

    static func duplicateAndCategoryIssues(
        snapshot: StallyBackupSnapshot
    ) -> [StallyBackupImportIssue] {
        var issues: [StallyBackupImportIssue] = []
        var seenItemIDs: Set<UUID> = []
        var seenMarkIDs: Set<UUID> = []

        for item in snapshot.items {
            collectItemIssues(
                for: item,
                seenItemIDs: &seenItemIDs,
                seenMarkIDs: &seenMarkIDs,
                issues: &issues
            )
        }

        return issues
    }

    static func collectItemIssues(
        for item: StallyBackupItem,
        seenItemIDs: inout Set<UUID>,
        seenMarkIDs: inout Set<UUID>,
        issues: inout [StallyBackupImportIssue]
    ) {
        if !seenItemIDs.insert(item.id).inserted {
            issues.append(
                .init(
                    severity: .error,
                    code: .duplicateItemID,
                    message: "Backup contains duplicate item ID \(item.id.uuidString).",
                    itemID: item.id
                )
            )
        }

        if !item.hasKnownCategory {
            issues.append(
                .init(
                    severity: .warning,
                    code: .unknownCategory,
                    message: "Unknown category '\(item.categoryRawValue)' will be imported as Other.",
                    itemID: item.id,
                    categoryRawValue: item.categoryRawValue
                )
            )
        }

        collectDuplicateMarkIssues(
            for: item,
            seenMarkIDs: &seenMarkIDs,
            issues: &issues
        )
    }

    static func collectDuplicateMarkIssues(
        for item: StallyBackupItem,
        seenMarkIDs: inout Set<UUID>,
        issues: inout [StallyBackupImportIssue]
    ) {
        for mark in item.marks where !seenMarkIDs.insert(mark.id).inserted {
            issues.append(
                .init(
                    severity: .error,
                    code: .duplicateMarkID,
                    message: "Backup contains duplicate mark ID \(mark.id.uuidString).",
                    itemID: item.id,
                    markID: mark.id
                )
            )
        }
    }

    static func issueSort(
        _ lhs: StallyBackupImportIssue,
        _ rhs: StallyBackupImportIssue
    ) -> Bool {
        if lhs.severity != rhs.severity {
            return lhs.severity == .error
        }

        if lhs.code != rhs.code {
            return lhs.code.rawValue < rhs.code.rawValue
        }

        if lhs.itemID != rhs.itemID {
            return (lhs.itemID?.uuidString ?? "") < (rhs.itemID?.uuidString ?? "")
        }

        return (lhs.markID?.uuidString ?? "") < (rhs.markID?.uuidString ?? "")
    }
}

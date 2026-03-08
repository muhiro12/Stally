import Foundation

public struct StallyBackupImportAnalysis: Equatable, Sendable {
    public struct Summary: Equatable, Sendable {
        public let totalItems: Int
        public let archivedItems: Int
        public let totalMarks: Int
        public let existingItems: Int
        public let newItems: Int

        public init(
            totalItems: Int,
            archivedItems: Int,
            totalMarks: Int,
            existingItems: Int,
            newItems: Int
        ) {
            self.totalItems = totalItems
            self.archivedItems = archivedItems
            self.totalMarks = totalMarks
            self.existingItems = existingItems
            self.newItems = newItems
        }
    }

    public let snapshot: StallyBackupSnapshot
    public let summary: Summary
    public let issues: [StallyBackupImportIssue]

    public init(
        snapshot: StallyBackupSnapshot,
        summary: Summary,
        issues: [StallyBackupImportIssue]
    ) {
        self.snapshot = snapshot
        self.summary = summary
        self.issues = issues
    }

    public var errors: [StallyBackupImportIssue] {
        issues.filter { $0.severity == .error }
    }

    public var warnings: [StallyBackupImportIssue] {
        issues.filter { $0.severity == .warning }
    }

    public var canImport: Bool {
        errors.isEmpty
    }
}

public struct StallyBackupImportIssue: Equatable, Sendable, Identifiable {
    public enum Severity: String, Equatable, Sendable {
        case warning
        case error
    }

    public enum Code: String, Equatable, Sendable {
        case unsupportedSchemaVersion
        case duplicateItemID
        case duplicateMarkID
        case unknownCategory
    }

    public let severity: Severity
    public let code: Code
    public let itemID: UUID?
    public let markID: UUID?
    public let categoryRawValue: String?
    public let message: String

    public init(
        severity: Severity,
        code: Code,
        itemID: UUID? = nil,
        markID: UUID? = nil,
        categoryRawValue: String? = nil,
        message: String
    ) {
        self.severity = severity
        self.code = code
        self.itemID = itemID
        self.markID = markID
        self.categoryRawValue = categoryRawValue
        self.message = message
    }

    public var id: String {
        [
            severity.rawValue,
            code.rawValue,
            itemID?.uuidString ?? "-",
            markID?.uuidString ?? "-",
            categoryRawValue ?? "-"
        ].joined(separator: "|")
    }
}

public enum StallyBackupImportAnalyzer {
    public static func analyze(
        snapshot: StallyBackupSnapshot,
        existingItemIDs: Set<UUID> = []
    ) -> StallyBackupImportAnalysis {
        var issues: [StallyBackupImportIssue] = []
        var seenItemIDs: Set<UUID> = []
        var seenMarkIDs: Set<UUID> = []

        if snapshot.schemaVersion != StallyBackupSnapshot.currentSchemaVersion {
            issues.append(
                .init(
                    severity: .error,
                    code: .unsupportedSchemaVersion,
                    message: "Backup schema version \(snapshot.schemaVersion) is unsupported."
                )
            )
        }

        for item in snapshot.items {
            if !seenItemIDs.insert(item.id).inserted {
                issues.append(
                    .init(
                        severity: .error,
                        code: .duplicateItemID,
                        itemID: item.id,
                        message: "Backup contains duplicate item ID \(item.id.uuidString)."
                    )
                )
            }

            if !item.hasKnownCategory {
                issues.append(
                    .init(
                        severity: .warning,
                        code: .unknownCategory,
                        itemID: item.id,
                        categoryRawValue: item.categoryRawValue,
                        message: "Unknown category '\(item.categoryRawValue)' will be imported as Other."
                    )
                )
            }

            for mark in item.marks {
                if !seenMarkIDs.insert(mark.id).inserted {
                    issues.append(
                        .init(
                            severity: .error,
                            code: .duplicateMarkID,
                            itemID: item.id,
                            markID: mark.id,
                            message: "Backup contains duplicate mark ID \(mark.id.uuidString)."
                        )
                    )
                }
            }
        }

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
            snapshot: snapshot,
            summary: .init(
                totalItems: totalItems,
                archivedItems: archivedItems,
                totalMarks: totalMarks,
                existingItems: existingItems,
                newItems: totalItems - existingItems
            ),
            issues: issues.sorted(by: issueSort)
        )
    }
}

public extension StallyBackupItem {
    var category: ItemCategory {
        .init(rawValue: categoryRawValue) ?? .other
    }

    var hasKnownCategory: Bool {
        ItemCategory(rawValue: categoryRawValue) != nil
    }

    var isArchived: Bool {
        archivedAt != nil
    }

    var lastMarkedAt: Date? {
        marks.map(\.day).max()
    }
}

private extension StallyBackupImportAnalyzer {
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

extension BackupOperations {
    static func trackingIssues(in snapshot: BackupSnapshot) -> [BackupValidationIssue] {
        snapshot.items.flatMap { item in
            var issues: [BackupValidationIssue] = []
            if let rawValue = item.startRawValue, ItemStart(rawValue: rawValue) == nil {
                issues.append(.init(kind: .invalidItemStart, value: item.id.uuidString))
            }
            if !item.recordsMarks, !item.marks.isEmpty {
                issues.append(.init(kind: .nonMarkHistoryConflict, value: item.id.uuidString))
            }
            if snapshot.schemaVersion == BackupSnapshot.legacySchemaVersion, !item.isLegacyCompatible {
                issues.append(.init(kind: .unsupportedTrackingFields, value: item.id.uuidString))
            }
            return issues
        }
    }

    static func markPolicyMergeIssues(
        in items: [BackupItem],
        currentItems: [Item]
    ) -> [BackupValidationIssue] {
        let nonMarkIDs = Set(currentItems.filter { item in
            !item.recordsMarks
        }
        .map(\.uuid))
        return items.compactMap { item in
            guard nonMarkIDs.contains(item.id), !item.marks.isEmpty else {
                return nil
            }
            return .init(kind: .markPolicyMergeConflict, value: item.id.uuidString)
        }
    }
}

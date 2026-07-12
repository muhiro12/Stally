//
//  BackupOperations+ImportValidation.swift
//  StallyLibrary
//
//  Created by Codex on 2026/07/12.
//

extension BackupOperations {
    static func oversizedBackupPreview(dataByteCount: Int) -> BackupPreview {
        .init(
            itemCount: 0,
            archivedItemCount: 0,
            markCount: 0,
            existingItemCount: 0,
            newItemCount: 0,
            skippedItemCount: 0,
            marksAddedCount: 0,
            validationIssues: [
                .init(
                    kind: .backupFileTooLarge,
                    value: "\(dataByteCount)"
                )
            ]
        )
    }

    static func invalidItemPhotoIdentifiers(
        in issues: [BackupValidationIssue]
    ) -> Set<String> {
        Set(
            issues.compactMap { issue in
                guard issue.kind == .invalidItemPhoto else {
                    return nil
                }

                return issue.value
            }
        )
    }

    static func itemPhotoValidationIssues(in items: [BackupItem]) -> [BackupValidationIssue] {
        items.compactMap { item in
            do {
                try ItemPhotoOperations.validate(item.photoData)
                return nil
            } catch {
                return .init(
                    kind: .invalidItemPhoto,
                    value: item.id.uuidString
                )
            }
        }
    }

    static func photoStorageLimitIssue(in items: [BackupItem]) -> BackupValidationIssue? {
        var totalPhotoDataByteCount = 0

        for item in items {
            guard let photoData = item.photoData else {
                continue
            }

            let addition = totalPhotoDataByteCount.addingReportingOverflow(photoData.count)
            totalPhotoDataByteCount = addition.overflow ? .max : addition.partialValue
        }

        guard totalPhotoDataByteCount > maximumImportPhotoDataByteCount else {
            return nil
        }

        return .init(
            kind: .photoStorageLimitExceeded,
            value: "\(totalPhotoDataByteCount)"
        )
    }
}

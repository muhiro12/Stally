//
//  BackupOperations+Export.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

public extension BackupOperations {
    /// Builds a versioned backup snapshot from local items.
    static func snapshot(
        for items: [Item],
        exportedAt: Date = .now
    ) -> BackupSnapshot {
        .init(
            exportedAt: exportedAt,
            items: items
                .sorted { lhsItem, rhsItem in
                    lhsItem.createdAt < rhsItem.createdAt
                }
                .map(backupItem)
        )
    }

    /// Encodes a backup that satisfies the current import validation and size limits.
    /// Throws `BackupError.validationFailed` without changing the source items when
    /// the snapshot cannot be restored by the current backup contract.
    static func exportData(
        for items: [Item],
        exportedAt: Date = .now,
        encoder: JSONEncoder = .init()
    ) throws -> Data {
        let snapshot = snapshot(for: items, exportedAt: exportedAt)
        let preview = preview(snapshot: snapshot, currentItems: [])

        guard preview.canImport else {
            throw BackupError.validationFailed(preview)
        }

        let data = try encoder.encode(snapshot)

        guard data.count <= maximumImportDataByteCount else {
            throw BackupError.validationFailed(
                oversizedImportPreview(dataByteCount: data.count)
            )
        }

        return data
    }
}

private extension BackupOperations {
    static func backupItem(_ item: Item) -> BackupItem {
        .init(
            id: item.uuid,
            name: item.name,
            categoryRawValue: item.categoryRawValue,
            note: item.note,
            photoData: item.photoData,
            createdAt: item.createdAt,
            archivedAt: item.archivedAt,
            marks: item.marks
                .sorted { lhsMark, rhsMark in
                    lhsMark.day < rhsMark.day
                }
                .map { mark in
                    .init(
                        id: mark.uuid,
                        day: mark.day,
                        createdAt: mark.createdAt
                    )
                },
            recordsMarks: item.recordsMarks,
            startRawValue: item.startRawValue
        )
    }
}

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

    /// Encodes a backup snapshot as portable JSON data.
    static func exportData(
        for items: [Item],
        exportedAt: Date = .now,
        encoder: JSONEncoder = .init()
    ) throws -> Data {
        try encoder.encode(snapshot(for: items, exportedAt: exportedAt))
    }
}

private extension BackupOperations {
    static func backupItem(_ item: Item) -> BackupItem {
        .init(
            id: item.uuid,
            name: item.name,
            categoryRawValue: item.category.rawValue,
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
                }
        )
    }
}

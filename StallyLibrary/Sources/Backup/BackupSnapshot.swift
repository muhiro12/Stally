//
//  BackupSnapshot.swift
//  StallyLibrary
//
//  Created by Codex on 2026/06/26.
//

import Foundation

/// Versioned portable snapshot of the Stally collection.
public struct BackupSnapshot: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case exportedAt
        case items
    }

    /// Current supported backup schema version.
    public static let currentSchemaVersion = 2

    /// Backup schema version.
    public let schemaVersion: Int
    /// Date when the backup was exported.
    public let exportedAt: Date
    /// Items included in the backup.
    public let items: [BackupItem]

    /// Creates a backup snapshot.
    public init(
        exportedAt: Date,
        items: [BackupItem],
        schemaVersion: Int = Self.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.items = items
    }
}

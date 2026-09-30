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
    public static let currentSchemaVersion = StallyDataContract.interchangeVersion
    static let legacySchemaVersion = 2

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

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        guard Self.supports(schemaVersion: schemaVersion) else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion, in: values, debugDescription: "Unsupported backup version."
            )
        }
        exportedAt = try values.decode(Date.self, forKey: .exportedAt)
        if schemaVersion == Self.legacySchemaVersion {
            items = try values.decode([LegacyBackupItemV2].self, forKey: .items).map(\.currentItem)
        } else {
            items = try values.decode([BackupItem].self, forKey: .items)
        }
    }

    static func supports(schemaVersion: Int) -> Bool {
        schemaVersion == currentSchemaVersion || schemaVersion == legacySchemaVersion
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schemaVersion, forKey: .schemaVersion)
        try values.encode(exportedAt, forKey: .exportedAt)
        if schemaVersion == Self.legacySchemaVersion {
            try values.encode(items.map(LegacyBackupItemV2.init), forKey: .items)
        } else {
            try values.encode(items, forKey: .items)
        }
    }
}

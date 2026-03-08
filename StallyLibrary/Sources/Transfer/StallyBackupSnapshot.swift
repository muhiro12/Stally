import Foundation

/// Serializable top-level backup payload.
public struct StallyBackupSnapshot: Codable, Equatable, Sendable {
    /// Current supported backup schema version.
    public static let currentSchemaVersion = 1

    /// Schema version stored in the payload.
    public let schemaVersion: Int

    /// Export timestamp for the snapshot.
    public let exportedAt: Date

    /// Backed-up item records.
    public let items: [StallyBackupItem]

    /// Creates a backup snapshot.
    public init(
        exportedAt: Date,
        items: [StallyBackupItem],
        schemaVersion: Int = Self.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.items = items.sorted(by: StallyBackupItem.sortForBackup)
    }
}

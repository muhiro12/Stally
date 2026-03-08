import Foundation

/// Serializable item payload stored inside a backup snapshot.
public struct StallyBackupItem: Codable, Equatable, Identifiable, Sendable {
    /// Stable item identifier.
    public let id: UUID

    /// Item display name.
    public let name: String

    /// Raw category value captured at export time.
    public let categoryRawValue: String

    /// Optional exported photo payload.
    public let photoData: Data?

    /// Optional exported note.
    public let note: String?

    /// Item creation timestamp.
    public let createdAt: Date

    /// Last update timestamp for item metadata.
    public let updatedAt: Date

    /// Archive timestamp when exported as archived.
    public let archivedAt: Date?

    /// Exported marks for the item.
    public let marks: [StallyBackupMark]

    /// Creates a backup item payload.
    public init(
        id: UUID,
        name: String,
        categoryRawValue: String,
        photoData: Data?,
        note: String?,
        createdAt: Date,
        updatedAt: Date,
        archivedAt: Date?,
        marks: [StallyBackupMark]
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = categoryRawValue
        self.photoData = photoData
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
        self.marks = marks.sorted(by: StallyBackupMark.sortForBackup)
    }
}

public extension StallyBackupItem {
    /// Strongly typed category inferred from the stored raw value.
    var category: ItemCategory {
        .init(rawValue: categoryRawValue) ?? .other
    }

    /// Indicates whether the exported category is currently recognized.
    var hasKnownCategory: Bool {
        ItemCategory(rawValue: categoryRawValue) != nil
    }

    /// Indicates whether the item was archived when exported.
    var isArchived: Bool {
        archivedAt != nil
    }

    /// Latest marked day captured by the export.
    var lastMarkedAt: Date? {
        marks.map(\.day).max()
    }
}

extension StallyBackupItem {
    static func sortForBackup(
        _ lhs: StallyBackupItem,
        _ rhs: StallyBackupItem
    ) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt < rhs.updatedAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }
}

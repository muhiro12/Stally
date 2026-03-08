import Foundation
import SwiftData

/// A personal item the user can repeatedly mark as chosen on a given day.
@Model
public final class Item {
    /// Stable item identifier.
    @Attribute(.unique)
    public private(set) var id: UUID

    /// Display name shown throughout the app.
    public private(set) var name: String

    private var categoryRawValue: String

    /// Optional attached photo stored outside the primary row payload.
    @Attribute(.externalStorage)
    public private(set) var photoData: Data?

    /// Optional free-form note for the item.
    public private(set) var note: String?

    /// Creation timestamp for the item record.
    public private(set) var createdAt: Date

    /// Last update timestamp for editable metadata.
    public private(set) var updatedAt: Date

    /// Archive timestamp when the item is currently archived.
    public private(set) var archivedAt: Date?

    /// All marks recorded for the item.
    @Relationship(deleteRule: .cascade, inverse: \Mark.item)
    public private(set) var marks: [Mark]

    /// Creates an item.
    public init(
        name: String,
        category: ItemCategory,
        photoData: Data? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        archivedAt: Date? = nil,
        id: UUID = .init()
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = category.rawValue
        self.photoData = photoData
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.archivedAt = archivedAt
        marks = []
    }
}

public extension Item {
    /// Strongly typed category backed by the stored raw value.
    var category: ItemCategory {
        get {
            .init(rawValue: categoryRawValue) ?? .other
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    /// Indicates whether the item is currently archived.
    var isArchived: Bool {
        archivedAt != nil
    }

    /// Applies validated editor input to the item.
    func apply(
        input: ItemFormInput,
        updatedAt: Date = .now
    ) throws {
        let validatedInput = try input.validated()

        name = validatedInput.name
        category = validatedInput.category
        photoData = validatedInput.photoData
        note = validatedInput.note
        self.updatedAt = updatedAt
    }

    /// Applies imported backup metadata to the item.
    func applyImportedSnapshot(
        _ backupItem: StallyBackupItem
    ) {
        name = backupItem.name
        category = backupItem.category
        photoData = backupItem.photoData
        note = backupItem.note
        createdAt = backupItem.createdAt
        updatedAt = backupItem.updatedAt
        archivedAt = backupItem.archivedAt
    }

    /// Archives the item at the given timestamp.
    func archive(at date: Date = .now) {
        archivedAt = date
        updatedAt = date
    }

    /// Removes the item from archive at the given timestamp.
    func unarchive(at date: Date = .now) {
        archivedAt = nil
        updatedAt = date
    }
}

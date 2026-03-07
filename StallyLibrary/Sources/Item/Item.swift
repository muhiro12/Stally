import Foundation
import SwiftData

/// A personal item the user can repeatedly mark as chosen on a given day.
@Model
public final class Item {
    @Attribute(.unique)
    public private(set) var id: UUID
    public private(set) var name: String
    private var categoryRawValue: String
    @Attribute(.externalStorage)
    public private(set) var photoData: Data?
    public private(set) var note: String?
    public private(set) var createdAt: Date
    public private(set) var updatedAt: Date
    public private(set) var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Mark.item)
    public private(set) var marks: [Mark]

    public init(
        id: UUID = .init(),
        name: String,
        category: ItemCategory,
        photoData: Data? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        archivedAt: Date? = nil
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
    var category: ItemCategory {
        get {
            .init(rawValue: categoryRawValue) ?? .other
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    var isArchived: Bool {
        archivedAt != nil
    }

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

    func archive(at date: Date = .now) {
        archivedAt = date
        updatedAt = date
    }

    func unarchive(at date: Date = .now) {
        archivedAt = nil
        updatedAt = date
    }
}

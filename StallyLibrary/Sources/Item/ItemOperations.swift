import Foundation
import SwiftData

/// Item identity, metadata, and independent user-selected state.
public enum ItemOperations {
    private static let ambiguousIdentityLimit = 2

    /// Creates an Item without implicitly recording a Mark or period.
    @discardableResult
    public static func create(context: ModelContext, name: String, note: String = "") throws -> Item {
        try RecordMutation.validate(context, models: [])
        try RecordMutation.validateName(name)
        let item = Item(name: name, note: note)
        context.insert(item)
        try RecordMutation.save(context)
        return item
    }

    /// Corrects metadata without changing identity, history, or state.
    public static func update(_ item: Item, name: String, note: String, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item])
        try RecordMutation.validateName(name)
        item.name = name
        item.note = note
        try RecordMutation.save(context)
    }

    /// Changes Library placement without ending periods or altering history.
    public static func setArchived(_ item: Item, to value: Bool, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item])
        item.isArchived = value
        try RecordMutation.save(context)
    }

    /// Changes only the favorite preference.
    public static func setFavorite(_ item: Item, to value: Bool, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item])
        item.isFavorite = value
        try RecordMutation.save(context)
    }

    /// Pausing preserves history and permits correction of existing occurrences.
    public static func setMarkRecordingEnabled(_ item: Item, to value: Bool, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item])
        item.isMarkRecordingEnabled = value
        try RecordMutation.save(context)
    }

    /// Deletes this Item and its owned children; shared Tags and unrelated records survive.
    public static func delete(_ item: Item, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item])
        context.delete(item)
        try RecordMutation.save(context)
    }

    /// Reads Items in registration order, without grouping equal names.
    public static func items(context: ModelContext) throws -> [Item] {
        try context.fetch(FetchDescriptor<Item>(sortBy: [.init(\.createdAt, order: .reverse)]))
    }

    /// Duplicate UUIDs are a conflict, never an instruction to choose or merge a record.
    public static func item(context: ModelContext, uuid: UUID) throws -> Item {
        var descriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = ambiguousIdentityLimit
        let items = try context.fetch(descriptor)
        guard items.count < ambiguousIdentityLimit else {
            throw RecordError.ambiguousIdentity
        }
        guard let item = items.first else {
            throw RecordError.missingRecord
        }
        return item
    }
}

import Foundation
import SwiftData

/// Item identity, metadata, and independent user-selected state.
public enum ItemOperations {
    private static let ambiguousIdentityLimit = 2

    /// Readable name, note, and representative URL for external use, without identity or history.
    /// This plain text is not a portable file or a supported import grammar.
    public static func shareText(for item: Item) -> String {
        [item.name, item.note, item.representativeURL]
            .compactMap { TextInput.optional($0) }
            .joined(separator: "\n\n")
    }

    /// Returns the saved photo sequence, resolving equal positions by attachment identity.
    public static func orderedPhotos(for item: Item) -> [ItemPhoto] {
        (item.photos ?? []).sorted { first, second in
            if first.sortOrder != second.sortOrder {
                return first.sortOrder < second.sortOrder
            }
            return first.uuid.uuidString < second.uuid.uuidString
        }
    }

    /// Takes editing values without creating pending model changes.
    public static func draft(for item: Item) -> ItemDraft {
        .init(item: item)
    }

    /// Commits metadata, Tag changes, and prepared photos together; failure preserves the draft.
    @discardableResult
    public static func save(_ draft: ItemDraft, context: ModelContext) throws -> Item {
        try RecordMutation.validate(context, models: [])
        // A failed graph save must not expose rolled-back relationship snapshots to the editor.
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let identity = try ItemDraftMutation.save(draft, context: writer).uuid
        return try item(context: context, uuid: identity)
    }

    /// Creates an Item without implicitly recording a Mark or period.
    @discardableResult
    public static func create(context: ModelContext, name: String, note: String? = nil) throws -> Item {
        try RecordMutation.validate(context, models: [])
        try RecordMutation.validateName(name)
        let item = Item(name: name, note: note)
        context.insert(item)
        try RecordMutation.save(context)
        return item
    }

    /// Corrects metadata without changing identity, history, or state.
    public static func update(_ item: Item, name: String, note: String?, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item])
        try RecordMutation.validateName(name)
        try mutate(item, context: context) { saved in
            saved.name = name
            saved.note = TextInput.optional(note)
        }
    }

    /// Changes Library placement without ending periods or altering history.
    public static func setArchived(_ item: Item, to value: Bool, context: ModelContext) throws {
        try mutate(item, context: context) { saved in
            saved.isArchived = value
        }
    }

    /// Changes only the favorite preference.
    public static func setFavorite(_ item: Item, to value: Bool, context: ModelContext) throws {
        try mutate(item, context: context) { saved in
            saved.isFavorite = value
        }
    }

    /// Pausing preserves history and permits correction of existing occurrences.
    public static func setMarkRecordingEnabled(_ item: Item, to value: Bool, context: ModelContext) throws {
        try mutate(item, context: context) { saved in
            saved.isMarkRecordingEnabled = value
        }
    }

    /// Deletes this Item and its owned children; shared Tags and unrelated records survive.
    public static func delete(_ item: Item, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item])
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let saved = try self.item(context: writer, uuid: item.uuid)
        writer.delete(saved)
        try RecordMutation.save(writer)
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

    private static func mutate(_ item: Item, context: ModelContext, change: (Item) throws -> Void) throws {
        try RecordMutation.validate(context, models: [item])
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let saved = try self.item(context: writer, uuid: item.uuid)
        try change(saved)
        try RecordMutation.save(writer)
        _ = try self.item(context: context, uuid: item.uuid)
    }
}

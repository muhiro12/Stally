import SwiftData

/// Explicit shared identities and assignments; names are never merge keys.
public enum TagOperations {
    /// Creates a distinct Tag, retaining exact confirmed spelling.
    @discardableResult
    public static func create(name: String, context: ModelContext) throws -> Tag {
        try RecordMutation.validate(context, models: [])
        try RecordMutation.validateName(name)
        let tag = Tag(name: name)
        context.insert(tag)
        try RecordMutation.save(context)
        return tag
    }

    /// Renames the chosen identity without merging equal names.
    public static func rename(_ tag: Tag, name: String, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [tag])
        try RecordMutation.validateName(name)
        tag.name = name
        try RecordMutation.save(context)
    }

    /// Replaces this Item’s explicit assignments using live identities from the same context.
    public static func assign(_ tags: [Tag], to item: Item, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item] + tags)
        var identifiers = Set<PersistentIdentifier>()
        item.tags = tags.filter { identifiers.insert($0.persistentModelID).inserted }
        try RecordMutation.save(context)
    }

    /// Removes this Tag and its assignments, preserving all Items.
    public static func delete(_ tag: Tag, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [tag])
        context.delete(tag)
        try RecordMutation.save(context)
    }
}

import Foundation
import SwiftData

/// Explicit shared identities and assignments; names are never merge keys.
public enum TagOperations {
    /// Returns localized name order, retaining distinct same-name Tags in UUID order.
    public static func orderedTags(for item: Item) -> [Tag] {
        (item.tags ?? []).sorted { first, second in
            let comparison = first.name.localizedStandardCompare(second.name)
            if comparison != .orderedSame {
                return comparison == .orderedAscending
            }
            return first.uuid.uuidString < second.uuid.uuidString
        }
    }

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
    /// A delayed editor supplies its original name to reject an intervening rename.
    public static func rename(_ tag: Tag, name: String, context: ModelContext, original: String? = nil) throws {
        try RecordMutation.validate(context, models: [tag])
        try RecordMutation.validateName(name)
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let saved = try self.tag(uuid: tag.uuid, context: writer)
        if let original, saved.name != original {
            throw RecordError.staleReview
        }
        saved.name = name
        try RecordMutation.save(writer)
        _ = try self.tag(uuid: tag.uuid, context: context)
    }

    /// Replaces this Item’s explicit assignments using live identities from the same context.
    public static func assign(_ tags: [Tag], to item: Item, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [item] + tags)
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let savedItem = try ItemOperations.item(context: writer, uuid: item.uuid)
        let savedTags = try Set(tags.map(\.uuid)).map { uuid in
            try tag(uuid: uuid, context: writer)
        }
        savedItem.tags = savedTags
        try RecordMutation.save(writer)
        _ = try ItemOperations.item(context: context, uuid: item.uuid)
        for selected in tags {
            _ = try tag(uuid: selected.uuid, context: context)
        }
    }

    /// Applies a delayed selection only while this Item's saved assignments still match its original set.
    /// Resolves every selected identity; a removed or ambiguous Tag never becomes a silent omission.
    public static func assign(
        uuids: Set<UUID>, to item: Item, context: ModelContext, original: Set<UUID>
    ) throws {
        try RecordMutation.validate(context, models: [item])
        // Saving a retained Item can also restore its stale scalar fields when relationships change.
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let savedItem = try ItemOperations.item(context: writer, uuid: item.uuid)
        let savedTags = try RecordMutation.index(savedItem.tags ?? [], identity: \.uuid)
        guard Set(savedTags.keys) == original else {
            throw RecordError.staleReview
        }
        let tags = try uuids.map { uuid in
            try tag(uuid: uuid, context: writer)
        }
        savedItem.tags = tags
        try RecordMutation.save(writer)
        _ = try ItemOperations.item(context: context, uuid: item.uuid)
    }

    /// Removes this Tag and its assignments, preserving all Items.
    public static func delete(_ tag: Tag, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [tag])
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let saved = try self.tag(uuid: tag.uuid, context: writer)
        let itemIDs = (saved.items ?? []).map(\.uuid)
        for itemID in itemIDs {
            _ = try ItemOperations.item(context: writer, uuid: itemID)
        }
        writer.delete(saved)
        try RecordMutation.save(writer)
        for itemID in itemIDs {
            _ = try ItemOperations.item(context: context, uuid: itemID)
        }
    }
}

private extension TagOperations {
    static func tag(uuid: UUID, context: ModelContext) throws -> Tag {
        var descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.uuid == uuid })
        let ambiguousIdentityLimit = 2
        descriptor.fetchLimit = ambiguousIdentityLimit
        let matches = try context.fetch(descriptor)
        guard matches.count < ambiguousIdentityLimit else {
            throw RecordError.ambiguousIdentity
        }
        guard let tag = matches.first else {
            throw RecordError.missingRecord
        }
        return tag
    }
}

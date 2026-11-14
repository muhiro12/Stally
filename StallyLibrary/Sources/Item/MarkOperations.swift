import Foundation
import SwiftData

/// Occurrence writes address individual records, including several on the same day.
public enum MarkOperations {
    /// Returns occurrence date/minute descending, then registration time descending and UUID ascending.
    public static func orderedMarks(for item: Item) -> [ItemMark] {
        (item.marks ?? []).sorted { first, second in
            if first.localDateTime != second.localDateTime {
                return first.localDateTime > second.localDateTime
            }
            if first.createdAt != second.createdAt {
                return first.createdAt > second.createdAt
            }
            return first.uuid.uuidString < second.uuid.uuidString
        }
    }

    /// Captures the caller's local Gregorian day or minute; no absolute timestamp is inferred.
    public static func localDateTime(at date: Date, includesTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = includesTime ? "yyyy-MM-dd'T'HH:mm" : "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Adds a new occurrence even when another has identical date knowledge.
    @discardableResult
    public static func add(to item: Item, localDateTime: String, context: ModelContext) throws -> ItemMark {
        try RecordMutation.validate(context, models: [item])
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let savedItem = try ItemOperations.item(context: writer, uuid: item.uuid)
        guard savedItem.isMarkRecordingEnabled else {
            throw RecordError.recordingPaused
        }
        try CivilDate.validateMark(localDateTime)
        let mark = ItemMark(item: savedItem, localDateTime: localDateTime)
        writer.insert(mark)
        try RecordMutation.save(writer)
        _ = try ItemOperations.item(context: context, uuid: item.uuid)
        return try self.mark(uuid: mark.uuid, context: context)
    }

    /// Correction remains available while recording is paused and retains registration metadata.
    /// Delayed editors supply the original date/minute to reject changes saved since review.
    public static func correct(
        _ mark: ItemMark,
        localDateTime: String,
        context: ModelContext,
        original: String? = nil
    ) throws {
        try RecordMutation.validate(context, models: [mark])
        try CivilDate.validateMark(localDateTime)
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let saved = try self.mark(uuid: mark.uuid, context: writer)
        if let original {
            guard saved.localDateTime == original else {
                throw RecordError.staleReview
            }
        }
        saved.localDateTime = localDateTime
        try RecordMutation.save(writer)
        _ = try self.mark(uuid: mark.uuid, context: context)
    }

    /// Undoes the acknowledged addition by identity, even if another Mark was added afterward.
    public static func undoAddition(uuid: UUID, context: ModelContext) throws {
        let mark = try mark(uuid: uuid, context: context)
        try delete(mark, context: context)
    }

    /// Deletes exactly this occurrence, preserving its Item and sibling Marks.
    public static func delete(_ mark: ItemMark, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [mark])
        let writer = ModelContext(context.container)
        writer.autosaveEnabled = false
        let saved = try self.mark(uuid: mark.uuid, context: writer)
        let itemID = saved.item?.uuid
        if let itemID {
            _ = try ItemOperations.item(context: writer, uuid: itemID)
        }
        writer.delete(saved)
        try RecordMutation.save(writer)
        if let itemID {
            _ = try ItemOperations.item(context: context, uuid: itemID)
        }
    }

    private static func mark(uuid: UUID, context: ModelContext) throws -> ItemMark {
        var descriptor = FetchDescriptor<ItemMark>(predicate: #Predicate { $0.uuid == uuid })
        let ambiguousIdentityLimit = 2
        descriptor.fetchLimit = ambiguousIdentityLimit
        let matches = try context.fetch(descriptor)
        guard matches.count < ambiguousIdentityLimit else {
            throw RecordError.ambiguousIdentity
        }
        guard let mark = matches.first else {
            throw RecordError.missingRecord
        }
        return mark
    }
}

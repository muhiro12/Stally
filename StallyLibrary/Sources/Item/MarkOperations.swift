import Foundation
import SwiftData

/// Occurrence writes address individual records, including several on the same day.
public enum MarkOperations {
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
        guard item.isMarkRecordingEnabled else {
            throw RecordError.recordingPaused
        }
        try CivilDate.validateMark(localDateTime)
        let mark = ItemMark(item: item, localDateTime: localDateTime)
        context.insert(mark)
        try RecordMutation.save(context)
        return mark
    }

    /// Correction remains available while recording is paused and retains registration metadata.
    public static func correct(_ mark: ItemMark, localDateTime: String, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [mark])
        try CivilDate.validateMark(localDateTime)
        mark.localDateTime = localDateTime
        try RecordMutation.save(context)
    }

    /// Undoes the acknowledged addition by identity, even if another Mark was added afterward.
    public static func undoAddition(uuid: UUID, context: ModelContext) throws {
        let matches = try context.fetch(FetchDescriptor<ItemMark>(predicate: #Predicate { $0.uuid == uuid }))
        guard matches.count <= 1 else { throw RecordError.ambiguousIdentity }
        guard let mark = matches.first else { throw RecordError.missingRecord }
        try delete(mark, context: context)
    }

    /// Deletes exactly this occurrence, preserving its Item and sibling Marks.
    public static func delete(_ mark: ItemMark, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [mark])
        context.delete(mark)
        try RecordMutation.save(context)
    }
}

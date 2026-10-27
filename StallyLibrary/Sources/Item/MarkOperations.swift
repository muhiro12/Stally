import SwiftData

/// Occurrence writes address individual records, including several on the same day.
public enum MarkOperations {
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

    /// Deletes exactly this occurrence, preserving its Item and sibling Marks.
    public static func delete(_ mark: ItemMark, context: ModelContext) throws {
        try RecordMutation.validate(context, models: [mark])
        context.delete(mark)
        try RecordMutation.save(context)
    }
}

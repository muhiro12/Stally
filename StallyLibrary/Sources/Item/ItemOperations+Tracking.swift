import Foundation
import SwiftData

public extension ItemOperations {
    /// Creates an Item with explicitly selected Mark policy and start knowledge.
    @discardableResult
    static func create(
        context: ModelContext,
        input: ItemFormInput,
        tracking: ItemTrackingInput,
        today: LocalDay,
        createdAt: Date = .now
    ) throws -> Item {
        try validateStart(tracking.start, today: today)
        let item = try makeItem(input: input, createdAt: createdAt, uuid: .init())
        item.recordsMarks = tracking.recordsMarks
        item.startRawValue = tracking.start?.rawValue
        context.insert(item)
        try saveOrRollback(context)
        return item
    }

    /// Atomically edits context and tracking, preserving all existing identity and history.
    static func update(
        _ item: Item,
        input: ItemFormInput,
        tracking: ItemTrackingInput,
        today: LocalDay,
        context: ModelContext
    ) throws {
        try validateMarkPolicy(tracking.recordsMarks, for: item)
        if tracking.start?.rawValue != item.startRawValue {
            try validateStart(tracking.start, today: today)
        }
        try applyFormInput(input, to: item)
        item.recordsMarks = tracking.recordsMarks
        item.startRawValue = tracking.start?.rawValue
        try saveOrRollback(context)
    }

    /// Reads tracking input without silently discarding malformed stored start text.
    /// A Mark/history conflict can be repaired by explicitly enabling Marks on update.
    static func trackingInput(for item: Item) throws -> ItemTrackingInput {
        guard let rawValue = item.startRawValue else {
            return .init(recordsMarks: item.recordsMarks, start: nil)
        }
        guard let start = ItemStart(rawValue: rawValue) else {
            throw ItemValidationError.invalidStart
        }
        return .init(recordsMarks: item.recordsMarks, start: start)
    }
}

extension ItemOperations {
    static func validateMarkPolicy(_ recordsMarks: Bool, for item: Item) throws {
        guard recordsMarks || capabilities(for: item).canDisableMarkRecording else {
            throw ItemValidationError.existingMarksRequireRecording
        }
    }

    private static func validateStart(_ start: ItemStart?, today: LocalDay) throws {
        if let start, start.earliestDay > today {
            throw ItemValidationError.futureStartNotAllowed
        }
    }
}

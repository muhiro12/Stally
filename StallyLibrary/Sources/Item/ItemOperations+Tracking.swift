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

    /// The shared guard for Mark, Undo, history editing, and their suggestions.
    static func historyChangeError(for item: Item) -> ItemValidationError? {
        if !item.recordsMarks {
            return .marksNotEnabled
        }
        if item.isArchived {
            return .archivedItemsCannotChangeHistory
        }
        return nil
    }

    /// Returns active Mark-enabled Items without changing generic entity resolution.
    static func itemsEligibleForHistoryChanges(from items: [Item]) -> [Item] {
        activeItems(from: items).filter { item in
            historyChangeError(for: item) == nil
        }
    }

    /// Detects an inconsistent sync/import state while retaining every existing Mark.
    static func hasNonMarkHistoryConflict(_ item: Item) -> Bool {
        !item.recordsMarks && !item.marks.isEmpty
    }

    /// Disabling Marks must never remove or hide an existing history.
    static func canDisableMarkRecording(_ item: Item) -> Bool {
        item.marks.isEmpty
    }
}

extension ItemOperations {
    static func validateMarkPolicy(_ recordsMarks: Bool, for item: Item) throws {
        guard recordsMarks || item.marks.isEmpty else {
            throw ItemValidationError.existingMarksRequireRecording
        }
    }

    private static func validateStart(_ start: ItemStart?, today: LocalDay) throws {
        if let start, start.earliestDay > today {
            throw ItemValidationError.futureStartNotAllowed
        }
    }
}

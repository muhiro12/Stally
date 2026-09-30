/// A captured reading of allowed Item actions, independent of a live model's lifetime.
public struct ItemCapabilities: Equatable, Sendable {
    /// Why Mark, Undo, and history editing are unavailable; nil permits those actions.
    public let historyChangeError: ItemValidationError?
    /// Whether existing history permits switching off Mark recording.
    public let canDisableMarkRecording: Bool
    /// Whether Archive would change the current collection placement.
    public let canArchive: Bool
    /// Whether moving back to Library would change the current collection placement.
    public let canMoveBackToLibrary: Bool
    /// Whether disabled recording conflicts with retained history.
    public let hasNonMarkHistoryConflict: Bool

    /// Whether daily choice history may currently be changed.
    public var canChangeHistory: Bool {
        historyChangeError == nil
    }

    init(item: Item) {
        if item.markPolicy == .disabled {
            historyChangeError = .marksNotEnabled
        } else if item.isArchived {
            historyChangeError = .archivedItemsCannotChangeHistory
        } else {
            historyChangeError = nil
        }
        canDisableMarkRecording = item.marks.isEmpty
        canArchive = !item.isArchived
        canMoveBackToLibrary = item.isArchived
        hasNonMarkHistoryConflict = item.markPolicy == .disabled && !item.marks.isEmpty
    }
}

public extension ItemOperations {
    /// Captures current action eligibility. Mutations always recheck the live model.
    static func capabilities(for item: Item) -> ItemCapabilities {
        .init(item: item)
    }

    /// The shared guard for Mark, Undo, history editing, and their suggestions.
    static func historyChangeError(for item: Item) -> ItemValidationError? {
        capabilities(for: item).historyChangeError
    }

    /// Returns eligible Items without narrowing generic identity or name resolution.
    static func itemsEligibleForHistoryChanges(from items: [Item]) -> [Item] {
        activeItems(from: items).filter { item in
            capabilities(for: item).canChangeHistory
        }
    }

    /// Detects inconsistent recording policy without discarding retained history.
    static func hasNonMarkHistoryConflict(_ item: Item) -> Bool {
        capabilities(for: item).hasNonMarkHistoryConflict
    }

    /// Whether switching off recording would preserve all existing history.
    static func canDisableMarkRecording(_ item: Item) -> Bool {
        capabilities(for: item).canDisableMarkRecording
    }
}

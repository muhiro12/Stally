import Foundation

/// Serializes writes and retains attempted identities so interrupted writes can be pruned.
public actor ItemSearchIndexSynchronizer {
    private struct SuccessfulSnapshot {
        let entries: [ItemSearchIndexEntry]
    }

    private enum LedgerState {
        case needsRebuild
        case tracked(Set<UUID>)
    }

    private let sink: any ItemSearchIndexSink
    private let ledgerURL: URL
    private var latestRevision: UInt64 = 0
    private var queuedTask: (identifier: UUID, task: Task<Void, any Error>)?
    private var lastSuccessfulSnapshot: SuccessfulSnapshot?

    /// Creates a serialized writer with a namespace-specific recovery ledger.
    public init(sink: any ItemSearchIndexSink, ledgerURL: URL) {
        self.sink = sink
        self.ledgerURL = ledgerURL
    }

    /// Applies a current saved snapshot; older revisions cannot overwrite newer ones.
    public func synchronize(_ entries: [ItemSearchIndexEntry], revision: UInt64, force: Bool) async throws {
        guard revision > latestRevision else {
            return
        }
        latestRevision = revision
        let previousTask = queuedTask?.task
        let identifier = UUID()
        let task = Task {
            _ = await previousTask?.result
            try await apply(entries, force: force)
        }
        queuedTask = (identifier, task)
        defer {
            if queuedTask?.identifier == identifier {
                queuedTask = nil
            }
        }
        try await task.value
    }

    private func apply(_ entries: [ItemSearchIndexEntry], force: Bool) async throws {
        guard force || entries != lastSuccessfulSnapshot?.entries else {
            return
        }
        lastSuccessfulSnapshot = nil
        let tracked = try readLedger()
        let previous: Set<UUID>
        switch tracked {
        case .needsRebuild:
            try await sink.resetNamespace()
            previous = []
        case .tracked(let identifiers):
            previous = identifiers
        }
        let current = ItemSearchIndexOperations.identifiers(for: entries)
        // Record possible additions before the OS write. A crash must not orphan them.
        try writeLedger(previous.union(current))
        try await sink.upsert(entries)
        try await sink.remove(ItemSearchIndexOperations.removedIdentifiers(previous: previous, current: entries))
        try writeLedger(current)
        lastSuccessfulSnapshot = .init(entries: entries)
    }

    private func readLedger() throws -> LedgerState {
        guard FileManager.default.fileExists(atPath: ledgerURL.path) else {
            return .needsRebuild
        }
        let data = try Data(contentsOf: ledgerURL)
        do {
            return .tracked(Set(try JSONDecoder().decode([UUID].self, from: data)))
        } catch is DecodingError {
            return .needsRebuild
        }
    }

    private func writeLedger(_ identifiers: Set<UUID>) throws {
        try FileManager.default.createDirectory(
            at: ledgerURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let ordered = identifiers.sorted { first, second in
            first.uuidString < second.uuidString
        }
        try JSONEncoder().encode(ordered).write(to: ledgerURL, options: .atomic)
    }
}

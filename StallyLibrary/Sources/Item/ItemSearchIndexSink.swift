import Foundation

/// A platform adapter implements idempotent writes for its own namespace.
public protocol ItemSearchIndexSink: Sendable {
    /// Adds or updates selected entries in the owned namespace.
    func upsert(_ entries: [ItemSearchIndexEntry]) async throws
    /// Removes only the supplied stable identities from the owned namespace.
    func remove(_ identifiers: [UUID]) async throws
    /// Clears only owned derived search metadata when recovery state is unavailable.
    func resetNamespace() async throws
}

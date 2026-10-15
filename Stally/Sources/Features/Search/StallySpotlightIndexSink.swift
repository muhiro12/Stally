import AppIntents
// The Objective-C delegate permits an asynchronous reply but does not annotate it Sendable.
@preconcurrency import CoreSpotlight
import SwiftData

@MainActor
final class StallySpotlightIndexSink: NSObject, ItemSearchIndexSink, CSSearchableIndexDelegate {
    private enum IndexError: Error {
        case sourceChanged
    }

    var reindex: (@MainActor @Sendable () async -> Void)?
    private let modelContainer: ModelContainer
    private let scope: StallySearchIndexCoordinator.Scope
    private let index: CSSearchableIndex

    init(modelContainer: ModelContainer, scope: StallySearchIndexCoordinator.Scope) {
        self.modelContainer = modelContainer
        self.scope = scope
        index = .init(name: scope.namespace ?? "disabled", protectionClass: .complete)
        super.init()
        index.indexDelegate = self
    }

    func upsert(_ entries: [ItemSearchIndexEntry]) async throws {
        guard let namespace = scope.namespace else {
            return
        }
        let context = ModelContext(modelContainer)
        let models = try ItemOperations.items(context: context, uuids: entries.map(\.uuid))
        // A queued snapshot must not certify newer or missing source values as indexed.
        guard ItemSearchIndexOperations.entries(for: models) == entries else {
            throw IndexError.sourceChanged
        }
        let entities = models.map { model in
            StallyItemEntity(model, hidesInSpotlight: scope.hidesResults)
        }
        var searchableItems = [CSSearchableItem]()
        for entity in entities {
            let searchableItem = await CSSearchableItem(appEntity: entity)
            searchableItem.uniqueIdentifier = ItemSearchIndexOperations.activityIdentifier(
                itemID: entity.uuid,
                namespace: namespace
            )
            searchableItem.domainIdentifier = namespace
            searchableItems.append(searchableItem)
        }
        guard !searchableItems.isEmpty else {
            return
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            index.indexSearchableItems(searchableItems) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func remove(_ identifiers: [UUID]) async throws {
        guard let namespace = scope.namespace, !identifiers.isEmpty else {
            return
        }
        let searchableIdentifiers = identifiers.map { identifier in
            ItemSearchIndexOperations.activityIdentifier(itemID: identifier, namespace: namespace)
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            index.deleteSearchableItems(withIdentifiers: searchableIdentifiers) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func resetNamespace() async throws {
        guard let namespace = scope.namespace else {
            return
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            index.deleteSearchableItems(withDomainIdentifiers: [namespace]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    nonisolated func searchableIndex(
        _: CSSearchableIndex,
        reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping @Sendable () -> Void
    ) {
        scheduleReindex(acknowledgementHandler: acknowledgementHandler)
    }

    nonisolated func searchableIndex(
        _: CSSearchableIndex,
        reindexSearchableItemsWithIdentifiers _: [String],
        acknowledgementHandler: @escaping @Sendable () -> Void
    ) {
        scheduleReindex(acknowledgementHandler: acknowledgementHandler)
    }

    nonisolated private func scheduleReindex(acknowledgementHandler: @escaping @Sendable () -> Void) {
        Task {
            await reindex?()
            acknowledgementHandler()
        }
    }
}

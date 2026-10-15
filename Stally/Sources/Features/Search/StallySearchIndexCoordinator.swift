import Combine
import CoreSpotlight
import MHPlatform
import Observation
import SwiftData

@MainActor
@Observable
final class StallySearchIndexCoordinator {
    private enum SynchronizationError: Error {
        case pendingChanges
        case indexingUnavailable
    }

    enum Scope {
        case disabled
        case production
        case test(UUID)

        var namespace: String? {
            switch self {
            case .disabled:
                nil
            case .production:
                "com.muhiro12.Stally.items"
            case .test(let identifier):
                "com.muhiro12.Stally.search-tests.\(identifier.uuidString)"
            }
        }

        var hidesResults: Bool {
            if case .test = self {
                return true
            }
            return false
        }
    }

    let scope: Scope
    private let modelContainer: ModelContainer
    private let logger: MHLogger
    private let synchronizer: ItemSearchIndexSynchronizer?
    private var sourceRevision: UInt64 = 0
    private var saveObserver: AnyCancellable?

    init(modelContainer: ModelContainer, scope: Scope, logging: MHLoggingBootstrap) {
        self.modelContainer = modelContainer
        self.scope = scope
        logger = StallyLogging.logger(logging: logging, category: "Spotlight", source: #fileID)
        if let namespace = scope.namespace {
            let directory = URL.applicationSupportDirectory
                .appendingPathComponent("Stally/SearchIndex", isDirectory: true)
            let sink = StallySpotlightIndexSink(modelContainer: modelContainer, scope: scope)
            synchronizer = .init(
                sink: sink,
                ledgerURL: directory.appendingPathComponent("\(namespace).json")
            )
            sink.reindex = { [weak self] in
                await self?.refresh(force: true)
            }
        } else {
            synchronizer = nil
        }
        guard synchronizer != nil else {
            return
        }
        saveObserver = NotificationCenter.default.publisher(for: ModelContext.didSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refresh(force: false)
                }
            }
    }

    func synchronize(force: Bool) async throws {
        guard let synchronizer else {
            return
        }
        guard CSSearchableIndex.isIndexingAvailable() else {
            throw SynchronizationError.indexingUnavailable
        }
        guard !modelContainer.mainContext.hasChanges else {
            throw SynchronizationError.pendingChanges
        }
        let context = ModelContext(modelContainer)
        let entries = ItemSearchIndexOperations.entries(for: try ItemOperations.items(context: context))
        sourceRevision += 1
        try await synchronizer.synchronize(entries, revision: sourceRevision, force: force)
    }

    func refresh(force: Bool) async {
        do {
            try await synchronize(force: force)
        } catch {
            logger.error("search_index.synchronization_failed", metadata: StallyLogging.errorMetadata(error))
        }
    }
}

#if DEBUG
import Foundation
import SwiftData

/// Manual sample insertion is restricted to the isolated local development store.
@preconcurrency
@MainActor
public enum DevelopmentSampleOperations {
    /// Refusals never replace, clear, or switch the open store.
    public enum InsertionError: LocalizedError, Equatable {
        case unsupportedStore
        case containsRecords

        public var errorDescription: String? {
            switch self {
            case .unsupportedStore:
                String(localized: "Samples can only be added to the local development store.", bundle: .module)
            case .containsRecords:
                String(localized: "Samples can only be added when all development records are empty.", bundle: .module)
            }
        }
    }

    /// Checks the current store and all five record types without changing data.
    public static func validateInsertion(context: ModelContext) throws {
        try validateInsertion(context: context, developmentDirectory: StallyDevelopmentStore.directory)
    }

    /// Rechecks eligibility and saves the representative graph, independently of automatic seeding.
    public static func insert(context: ModelContext) throws {
        try insert(context: context, developmentDirectory: StallyDevelopmentStore.directory)
    }

    // Tests substitute a disposable directory; app callers cannot select another insertion target.
    static func insert(context: ModelContext, developmentDirectory: URL) throws {
        try validateInsertion(context: context, developmentDirectory: developmentDirectory)
        try StallyDevelopmentSeed.insert(in: context)
    }

    static func validateInsertion(context: ModelContext, developmentDirectory: URL) throws {
        try validateStore(context.container.configurations, developmentDirectory: developmentDirectory)
        guard context === context.container.mainContext else {
            throw RecordError.wrongContext
        }
        try RecordMutation.validate(context, models: [])
        let snapshot = try DiagnosticsOperations.snapshot(context: context)
        guard snapshot.items == 0, snapshot.marks == 0, snapshot.periods == 0,
              snapshot.photos == 0, snapshot.tags == 0
        else {
            throw InsertionError.containsRecords
        }
    }

    static func validateStore(_ configurations: Set<ModelConfiguration>, developmentDirectory: URL) throws {
        let expectedURL = developmentDirectory
            .deletingLastPathComponent()
            .resolvingSymlinksInPath()
            .appending(path: developmentDirectory.lastPathComponent, directoryHint: .isDirectory)
            .appending(path: "Development.store")
        guard configurations.count == 1, let configuration = configurations.first,
              !configuration.isStoredInMemoryOnly, configuration.allowsSave,
              configuration.cloudKitContainerIdentifier == nil,
              configuration.groupAppContainerIdentifier == nil,
              developmentDirectory.resolvingSymlinksInPath().path == expectedURL.deletingLastPathComponent().path,
              configuration.url.standardizedFileURL.resolvingSymlinksInPath() == expectedURL,
              expectedURL.resolvingSymlinksInPath() == expectedURL
        else {
            throw InsertionError.unsupportedStore
        }
    }
}
#endif

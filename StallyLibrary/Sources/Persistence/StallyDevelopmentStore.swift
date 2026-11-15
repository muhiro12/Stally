#if DEBUG
import Foundation
import SwiftData

/// Local development data never shares a store or CloudKit configuration with the app family.
@preconcurrency
@MainActor
public enum StallyDevelopmentStore {
    /// The app sandbox, deliberately outside its shared App Group directory.
    public static var directory: URL {
        URL.applicationSupportDirectory.appending(path: "StallyDevelopment", directoryHint: .isDirectory)
    }

    /// Seeds only the first creation of this directory, never an existing empty database.
    /// Opting out still consumes initial setup. Errors retain the directory and store for inspection.
    public static func open(in directory: URL = directory, automaticallySeed: Bool = true) throws
    -> ModelContainer {
        let isNew = !FileManager.default.fileExists(atPath: directory.path)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let container = try StallyModelContainerFactory.disk(
            at: directory.appending(path: "Development.store"),
            cloudKitDatabase: .none
        )
        container.mainContext.autosaveEnabled = false
        if isNew, automaticallySeed {
            try StallyDevelopmentSeed.insert(in: container.mainContext)
        }
        return container
    }

    /// Fresh isolated data for Previews and behavior tests, using the same representative graph.
    public static func preview() throws -> ModelContainer {
        let container = try StallyModelContainerFactory.inMemory()
        container.mainContext.autosaveEnabled = false
        try StallyDevelopmentSeed.insert(in: container.mainContext)
        return container
    }
}
#endif

import Foundation
import SwiftData

/// One explicit shared store for app and future extension processes.
public enum StallyModelContainerFactory {
    /// Shared device-local container selected for the first-release app family.
    public static let appGroupIdentifier = "group.com.muhiro12.Stally"
    /// Existing iCloud identity; this declaration makes no production-schema assumption.
    public static let cloudKitContainerIdentifier = "iCloud.com.muhiro12.Stally"

    /// The complete five-model schema used by every new container.
    public static var schema: Schema { .init(versionedSchema: StallySchema.self) }

    /// Opens the shared store with native iCloud mirroring; errors never select another store.
    public static func persistent() throws -> ModelContainer {
        guard
            let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
            )
        else {
            throw StallyPersistenceError.appGroupUnavailable
        }
        let storeURL = groupURL.appending(path: "Library/Application Support/Stally.store")
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return try disk(at: storeURL, cloudKitDatabase: .private(cloudKitContainerIdentifier))
    }

    /// Explicit disk entry point for isolated verification. CloudKit is off unless requested.
    public static func disk(
        at url: URL,
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none
    ) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: [
                ModelConfiguration("Stally", schema: schema, url: url, cloudKitDatabase: cloudKitDatabase)
            ]
        )
    }

    /// Ephemeral storage is available only through an explicit test or preview call.
    public static func inMemory() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: [
                ModelConfiguration(
                    "StallyPreview",
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    groupContainer: .none,
                    cloudKitDatabase: .none
                )
            ]
        )
    }
}

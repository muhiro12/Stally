#if DEBUG
import Foundation
import SwiftData

/// Read-only development diagnostics for the actual open container.
@preconcurrency
@MainActor
public enum DevelopmentOperations {
    /// Counts and configuration describe this local snapshot, not remote sync completion.
    public struct Snapshot {
        /// Number of Items visible to this context.
        public let items: Int
        /// Number of individual Mark records.
        public let marks: Int
        /// Number of recorded periods, including ended history.
        public let periods: Int
        /// Number of attachment records; image payloads are not fetched.
        public let photos: Int
        /// Number of Tag identities, without merging equal names.
        public let tags: Int
        /// Whether every configured store is ephemeral.
        public let isInMemory: Bool
        /// URLs of the actual open configurations, for local inspection only.
        public let storeLocations: [URL]
        /// Configured CloudKit identities; their presence does not prove synchronization.
        public let cloudKitContainers: [String]
    }

    /// Does not save, roll back, or alter pending edits in the supplied context.
    public static func snapshot(context: ModelContext) throws -> Snapshot {
        let configurations = context.container.configurations
        return try .init(
            items: context.fetchCount(FetchDescriptor<Item>()),
            marks: context.fetchCount(FetchDescriptor<ItemMark>()),
            periods: context.fetchCount(FetchDescriptor<ItemPeriod>()),
            photos: context.fetchCount(FetchDescriptor<ItemPhoto>()),
            tags: context.fetchCount(FetchDescriptor<Tag>()),
            isInMemory: configurations.allSatisfy(\.isStoredInMemoryOnly),
            storeLocations: configurations.map(\.url).sorted { $0.path < $1.path },
            cloudKitContainers: configurations.compactMap(\.cloudKitContainerIdentifier).sorted()
        )
    }
}
#endif

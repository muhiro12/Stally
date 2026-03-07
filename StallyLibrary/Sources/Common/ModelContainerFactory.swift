import SwiftData

/// Factory helpers to create shared SwiftData containers for Stally.
public enum ModelContainerFactory {
    /// Creates the persistent app container backed by `Database.url`.
    public static func shared() throws -> ModelContainer {
        try .init(
            for: Item.self,
            Mark.self,
            configurations: .init(
                url: Database.url
            )
        )
    }
}

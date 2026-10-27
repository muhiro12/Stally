import SwiftData

/// The first-release five-model schema. Versions 1 and 2 were development stores.
public enum StallySchemaV3: VersionedSchema {
    private static let majorVersion = 3

    public static var versionIdentifier: Schema.Version { .init(majorVersion, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [Item.self, ItemMark.self, ItemPeriod.self, ItemPhoto.self, Tag.self]
    }
}

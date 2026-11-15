import SwiftData

/// The first-release baseline; prerelease development stores are not migration inputs.
public enum StallySchema: VersionedSchema {
    private static let majorVersion = 1

    public static var versionIdentifier: Schema.Version { .init(majorVersion, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [Item.self, ItemMark.self, ItemPeriod.self, ItemPhoto.self, Tag.self]
    }
}

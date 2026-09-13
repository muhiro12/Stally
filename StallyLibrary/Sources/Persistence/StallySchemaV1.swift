import Foundation
import SwiftData

/// Frozen persisted definitions from the original rebuild. Never add fields here.
enum StallySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Item.self, ItemMark.self]
    }
}

extension StallySchemaV1 {
    @Model
    final class Item {
        var uuid = UUID()
        var name: String = ""
        var categoryRawValue: String = ItemCategory.other.rawValue
        var note: String = ""
        @Attribute(.externalStorage)
        var photoData: Data?
        var createdAt = Date()
        var archivedAt: Date?

        // CloudKit requires optional relationships, including in historical schemas.
        // swiftlint:disable discouraged_optional_collection
        @Relationship(deleteRule: .cascade, inverse: \ItemMark.item)
        var markRecords: [ItemMark]?
        // swiftlint:enable discouraged_optional_collection

        init() {
            // Historical defaults are intentionally unchanged.
        }
    }

    @Model
    final class ItemMark {
        private static let defaultDayKey = 19_700_101

        var uuid = UUID()
        var dayKey = defaultDayKey
        var createdAt = Date()
        var item: Item?

        init() {
            // Historical defaults are intentionally unchanged.
        }
    }
}

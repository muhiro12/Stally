import Foundation
import SwiftData

/// Frozen persisted definitions from the second development rebuild. Never add fields here.
enum StallySchemaV2: VersionedSchema {
    private static let majorVersion = 2

    static var versionIdentifier: Schema.Version {
        .init(majorVersion, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Item.self, ItemMark.self]
    }
}

extension StallySchemaV2 {
    @Model
    final class Item {
        var uuid = UUID()
        var name: String = ""
        // A historical schema must not follow changes to the current domain enum.
        var categoryRawValue: String = "Other"
        var note: String = ""
        @Attribute(.externalStorage)
        var photoData: Data?
        var createdAt = Date()
        var archivedAt: Date?
        var recordsMarks: Bool = true
        var startRawValue: String?

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

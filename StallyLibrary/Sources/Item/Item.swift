import Foundation
import SwiftData

/// A personally meaningful subject with independent state and owned records.
public typealias Item = StallySchemaV3.Item

// The Model macro needs explicit class visibility for its generated protocol witnesses.
// swiftlint:disable:next extension_access_modifier
extension StallySchemaV3 {
    /// A personally meaningful subject with independent state and owned records.
    @Model
    public final class Item {
        /// Application-owned identity, retained across corrections and identity-preserving imports.
        public internal(set) var uuid = UUID()
        /// The exact user-confirmed name; equality does not establish identity.
        public internal(set) var name: String = ""
        /// User-authored context.
        public internal(set) var note: String = ""
        /// Registration time, never an occurrence date or conflict ordering signal.
        public internal(set) var createdAt = Date()
        /// Library placement, independent of recording and period state.
        public internal(set) var isArchived: Bool = false
        /// User preference, independent of Archive and recording.
        public internal(set) var isFavorite: Bool = false
        /// Whether new occurrences can be recorded; existing history remains editable.
        public internal(set) var isMarkRecordingEnabled: Bool = true

        /// Owned occurrences; optional for native CloudKit relationship delivery.
        @Relationship(deleteRule: .cascade, inverse: \ItemMark.item)
        public internal(set) var marks: [ItemMark]? = []  // swiftlint:disable:this discouraged_optional_collection
        /// Owned relationship history; array order has no meaning.
        @Relationship(deleteRule: .cascade, inverse: \ItemPeriod.item)
        public internal(set) var periods: [ItemPeriod]? = []  // swiftlint:disable:this discouraged_optional_collection
        /// Owned attachments; display order uses sortOrder and UUID.
        @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.item)
        public internal(set) var photos: [ItemPhoto]? = []  // swiftlint:disable:this discouraged_optional_collection
        /// Shared identities whose deletion only removes assignments.
        @Relationship(deleteRule: .nullify, inverse: \Tag.items)
        public internal(set) var tags: [Tag]? = []  // swiftlint:disable:this discouraged_optional_collection

        init(name: String, note: String) {
            self.name = name
            self.note = note
        }
    }
}

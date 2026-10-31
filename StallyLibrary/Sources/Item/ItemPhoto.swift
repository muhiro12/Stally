import Foundation
import SwiftData

/// An independently owned attachment and optional rebuildable preview.
public typealias ItemPhoto = StallySchema.ItemPhoto

// The Model macro needs explicit class visibility for its generated protocol witnesses.
// swiftlint:disable:next extension_access_modifier
extension StallySchema {
    /// An independently owned attachment and optional rebuildable preview.
    @Model
    public final class ItemPhoto {
        /// Application-owned identity, retained across corrections and identity-preserving imports.
        public internal(set) var uuid = UUID()
        /// Authoritative attachment bytes, independently owned and externally stored by SwiftData.
        @Attribute(.externalStorage)
        public internal(set) var imageData: Data?
        /// Optional persisted derivative that can be rebuilt from imageData.
        public internal(set) var thumbnailData: Data?
        /// User-authored description of this attachment.
        public internal(set) var caption: String = ""
        /// Explicit photo position; UUID breaks ties after concurrent edits.
        public internal(set) var sortOrder: Int = 0
        /// Registration time, never an occurrence date or conflict ordering signal.
        public internal(set) var createdAt = Date()
        /// Owning Item, temporarily absent when a synchronized graph is incomplete.
        public internal(set) var item: Item?

        init(
            item: Item,
            imageData: Data?,
            thumbnailData: Data?,
            caption: String,
            sortOrder: Int
        ) {
            self.item = item
            self.imageData = imageData
            self.thumbnailData = thumbnailData
            self.caption = caption
            self.sortOrder = sortOrder
        }
    }
}

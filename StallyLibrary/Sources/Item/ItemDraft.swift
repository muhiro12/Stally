import Foundation

/// Unsaved editing values. Discarding a draft never changes the stored graph.
public struct ItemDraft: Sendable {
    /// A distinct new Tag, even when another Tag has the same name.
    public struct NewTag: Identifiable, Sendable {
        public let id = UUID()
        public var name: String

        public init(name: String) {
            self.name = name
        }
    }

    /// Existing attachment identity or a draft-local identity for new prepared bytes.
    public struct Photo: Identifiable, Sendable {
        public let id: UUID
        public var caption: String
        public let imageData: Data?
        public let thumbnailData: Data?
        let isNew: Bool

        public init(prepared: PreparedPhoto, caption: String = "") {
            id = UUID()
            self.caption = caption
            imageData = prepared.imageData
            thumbnailData = prepared.thumbnailData
            isNew = true
        }

        init(photo: ItemPhoto) {
            id = photo.uuid
            caption = photo.caption
            imageData = photo.imageData
            thumbnailData = photo.thumbnailData
            isNew = false
        }
    }

    struct Original: Sendable {
        let id: UUID
        let name: String
        let note: String
        let representativeURL: String
        let tagIDs: Set<UUID>
        let photos: [Photo]
    }

    public var name: String
    public var note: String
    public var representativeURL: String
    public var tagIDs: Set<UUID>
    public var newTags: [NewTag] = []
    public var photos: [Photo] = []

    let original: Original?

    public init(name: String = "", note: String = "") {
        self.name = name
        self.note = note
        representativeURL = ""
        tagIDs = []
        original = nil
    }

    init(item: Item) {
        name = item.name
        note = item.note
        representativeURL = item.representativeURL ?? ""
        tagIDs = Set((item.tags ?? []).map(\.uuid))
        photos = (item.photos ?? []).sorted { first, second in
            if first.sortOrder != second.sortOrder {
                return first.sortOrder < second.sortOrder
            }
            return first.uuid.uuidString < second.uuid.uuidString
        }
        .map(Photo.init)
        original = .init(
            id: item.uuid,
            name: name,
            note: note,
            representativeURL: representativeURL,
            tagIDs: tagIDs,
            photos: photos
        )
    }
}

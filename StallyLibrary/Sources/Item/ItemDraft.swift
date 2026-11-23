import Foundation

/// Unsaved editing values. Empty form text becomes nil only at the save boundary.
/// Discarding a draft never changes the stored graph.
public struct ItemDraft: Sendable {
    /// Editable period values with stable identity throughout the editing session.
    public struct Period: Identifiable, Equatable, Sendable {
        public let id: UUID
        let isNew: Bool
        let isReviewedSuggestion: Bool
        public var input: PeriodInput

        public init(input: PeriodInput, isReviewedSuggestion: Bool = false) {
            id = UUID()
            isNew = true
            self.isReviewedSuggestion = isReviewedSuggestion
            self.input = input
        }

        init(period: ItemPeriod) {
            id = period.uuid
            isNew = false
            isReviewedSuggestion = false
            input = .init(period)
        }
    }

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

        public init(prepared: PreparedPhoto, caption: String? = nil) {
            id = UUID()
            self.caption = caption ?? ""
            imageData = prepared.imageData
            thumbnailData = prepared.thumbnailData
            isNew = true
        }

        init(photo: ItemPhoto) {
            id = photo.uuid
            caption = photo.caption ?? ""
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
        let periods: [Period]
    }

    public var name: String
    public var note: String
    public var representativeURL: String
    public var tagIDs: Set<UUID>
    public var newTags: [NewTag] = []
    public var photos: [Photo] = []
    public var periods: [Period] = []

    /// Only the additions staged for the next save.
    public var newPeriods: [Period] {
        get {
            periods.filter(\.isNew)
        }
        set {
            periods.removeAll(where: \.isNew)
            periods.append(contentsOf: newValue)
        }
    }

    let original: Original?

    public init(name: String = "", note: String? = nil) {
        self.name = name
        self.note = note ?? ""
        representativeURL = ""
        tagIDs = []
        original = nil
    }

    init(item: Item) {
        name = item.name
        note = item.note ?? ""
        representativeURL = item.representativeURL ?? ""
        tagIDs = Set((item.tags ?? []).map(\.uuid))
        photos = ItemOperations.orderedPhotos(for: item).map(Photo.init)
        periods = PeriodOperations.orderedPeriods(for: item).map(Period.init)
        original = .init(
            id: item.uuid,
            name: name,
            note: note,
            representativeURL: representativeURL,
            tagIDs: tagIDs,
            photos: photos,
            periods: periods
        )
    }
}

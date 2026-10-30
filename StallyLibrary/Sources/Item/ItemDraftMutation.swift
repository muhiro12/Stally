import Foundation
import SwiftData

/// Validates the complete submitted edit before changing any model.
enum ItemDraftMutation {
    static func save(_ draft: ItemDraft, context: ModelContext) throws -> Item {
        try RecordMutation.validate(context, models: [])
        try RecordMutation.validateName(draft.name)
        let link = try representativeURL(draft.representativeURL)
        for tag in draft.newTags {
            try RecordMutation.validateName(tag.name)
        }
        let item: Item
        if let original = draft.original {
            item = try ItemOperations.item(context: context, uuid: original.id)
        } else {
            item = Item(name: draft.name, note: draft.note)
        }
        let addedIDs = draft.tagIDs.subtracting(draft.original?.tagIDs ?? [])
        let allTags = try context.fetch(FetchDescriptor<Tag>())
        let addedTags = try addedIDs.map { id in
            let matches = allTags.filter { $0.uuid == id }
            guard matches.count <= 1 else {
                throw RecordError.ambiguousIdentity
            }
            guard let tag = matches.first else {
                throw RecordError.missingRecord
            }
            return tag
        }
        try validatePhotos(draft, item: item)
        if draft.original == nil {
            context.insert(item)
        }
        if draft.original?.name != draft.name {
            item.name = draft.name
        }
        if draft.original?.note != draft.note {
            item.note = draft.note
        }
        if draft.original?.representativeURL != draft.representativeURL {
            item.representativeURL = link
        }
        applyTags(draft, addedTags: addedTags, item: item, context: context)
        applyPhotos(draft, item: item, context: context)
        try RecordMutation.save(context)
        return item
    }

    static func representativeURL(_ text: String) throws -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }
        guard let url = URL(string: value, encodingInvalidCharacters: false),
              let scheme = url.scheme?.lowercased(),
              !["file", "data", "javascript"].contains(scheme),
              !["http", "https"].contains(scheme) || url.host?.isEmpty == false
        else {
            throw RecordError.invalidURL
        }
        return value
    }

    private static func validatePhotos(_ draft: ItemDraft, item: Item) throws {
        guard Set(draft.photos.map(\.id)).count == draft.photos.count else {
            throw RecordError.ambiguousIdentity
        }
        let current = item.photos ?? []
        for photo in current where current.filter({ $0.uuid == photo.uuid }).count > 1 {
            throw RecordError.ambiguousIdentity
        }
        let originalIDs = Set(draft.original?.photos.map(\.id) ?? [])
        for photo in draft.photos {
            if photo.isNew {
                guard !originalIDs.contains(photo.id), !current.contains(where: { $0.uuid == photo.id }) else {
                    throw RecordError.ambiguousIdentity
                }
            } else {
                guard originalIDs.contains(photo.id), current.contains(where: { $0.uuid == photo.id }) else {
                    throw RecordError.missingRecord
                }
            }
        }
    }

    private static func applyTags(
        _ draft: ItemDraft, addedTags: [Tag], item: Item, context: ModelContext
    ) {
        let removedIDs = (draft.original?.tagIDs ?? []).subtracting(draft.tagIDs)
        guard !addedTags.isEmpty || !removedIDs.isEmpty || !draft.newTags.isEmpty else {
            return
        }
        var assigned = (item.tags ?? []).filter { !removedIDs.contains($0.uuid) }
        for tag in addedTags where !assigned.contains(where: { $0.uuid == tag.uuid }) {
            assigned.append(tag)
        }
        for input in draft.newTags {
            let tag = Tag(name: input.name)
            context.insert(tag)
            assigned.append(tag)
        }
        item.tags = assigned
    }

    private static func applyPhotos(_ draft: ItemDraft, item: Item, context: ModelContext) {
        let original = draft.original?.photos ?? []
        let removedIDs = Set(original.map(\.id)).subtracting(draft.photos.map(\.id))
        let current = item.photos ?? []
        for photo in current where removedIDs.contains(photo.uuid) {
            context.delete(photo)
        }
        let orderChanged = original.map(\.id) != draft.photos.map(\.id)
        for (index, input) in draft.photos.enumerated() {
            if input.isNew, let data = input.imageData {
                let photo = ItemPhoto(
                    item: item,
                    imageData: data,
                    thumbnailData: input.thumbnailData,
                    caption: input.caption,
                    sortOrder: index
                )
                context.insert(photo)
            } else if let photo = current.first(where: { $0.uuid == input.id }) {
                if original.first(where: { $0.id == input.id })?.caption != input.caption {
                    photo.caption = input.caption
                }
                if orderChanged {
                    photo.sortOrder = index
                }
            }
        }
    }
}

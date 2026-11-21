import Foundation
import SwiftData

/// Validates the complete submitted edit before changing any model.
enum ItemDraftMutation {
    static func save(_ draft: ItemDraft, today: String?, context: ModelContext) throws -> Item {
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
        let originalTagIDs = draft.original?.tagIDs ?? []
        let changedIDs = draft.tagIDs.symmetricDifference(originalTagIDs)
        let allTags = try context.fetch(FetchDescriptor<Tag>())
        let changedTags = try RecordMutation.index(allTags.filter { changedIDs.contains($0.uuid) }, identity: \.uuid)
        let addedTags = try draft.tagIDs.subtracting(originalTagIDs).map { id in
            guard let tag = changedTags[id] else {
                throw RecordError.missingRecord
            }
            return tag
        }
        try validatePhotos(draft, item: item)
        let periods = try preparedPeriods(draft, item: item, today: today)
        if draft.original == nil {
            context.insert(item)
        }
        if draft.original?.name != draft.name {
            item.name = draft.name
        }
        if draft.original?.note != draft.note {
            item.note = TextInput.optional(draft.note)
        }
        if draft.original?.representativeURL != draft.representativeURL {
            item.representativeURL = link
        }
        applyTags(draft, addedTags: addedTags, item: item, context: context)
        applyPhotos(draft, item: item, context: context)
        for period in periods {
            context.insert(ItemPeriod(
                item: item, startLocalDate: period.start, endLocalDate: period.end, isOngoing: period.isOngoing
            ))
        }
        try RecordMutation.save(context)
        return item
    }

    private static func preparedPeriods(_ draft: ItemDraft, item: Item, today: String?) throws -> [PeriodInput] {
        guard !draft.newPeriods.isEmpty else {
            return []
        }
        guard let today, Set(draft.newPeriods.map(\.id)).count == draft.newPeriods.count else {
            throw RecordError.invalidPeriod
        }
        var siblings = (item.periods ?? []).map { period in
            PeriodInput(start: period.startLocalDate, end: period.endLocalDate, isOngoing: period.isOngoing)
        }
        var result: [PeriodInput] = []
        for period in draft.newPeriods {
            let input = period.input
            guard !siblings.contains(input) else {
                throw RecordError.invalidPeriod
            }
            try PeriodOperations.validateInput(input, siblings: siblings, today: today)
            siblings.append(input)
            result.append(input)
        }
        return result
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
        try validatePhotoOrder(draft, item: item)
    }

    private static func validatePhotoOrder(_ draft: ItemDraft, item: Item) throws {
        guard let original = draft.original?.photos.map(\.id), original != draft.photos.map(\.id) else {
            return
        }
        let current = ItemOperations.orderedPhotos(for: item).map(\.uuid)
        let originalIDs = Set(original)
        let currentIDs = Set(current)
        // Adding or removing a photo also rewrites positions; it must not restore an older order.
        guard current.filter(originalIDs.contains) == original.filter(currentIDs.contains) else {
            throw RecordError.staleReview
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
                    photo.caption = TextInput.optional(input.caption)
                }
                if orderChanged {
                    photo.sortOrder = index
                }
            }
        }
    }
}

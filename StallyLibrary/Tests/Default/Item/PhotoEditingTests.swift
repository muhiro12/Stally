import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct PhotoEditingTests {
    @Test(arguments: ["append", "remove", "reorder"])
    func stalePhotoListCannotResetAnotherReorder(change: String) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Photos")
        for (index, caption) in ["First", "Second", "Third"].enumerated() {
            context.insert(ItemPhoto(
                item: item, imageData: nil, thumbnailData: nil, caption: caption, sortOrder: index
            ))
        }
        try context.save()
        var draft = ItemOperations.draft(for: item)
        let other = ModelContext(container)
        let saved = try ItemOperations.item(context: other, uuid: item.uuid)
        var newer = ItemOperations.draft(for: saved)
        newer.photos.swapAt(0, 1)
        try ItemOperations.save(newer, context: other)
        if change == "remove" {
            draft.photos.removeLast()
        } else if change == "append" {
            draft.photos.append(.init(prepared: .init(imageData: try PhotoTestImages.imageData(), thumbnailData: nil)))
        } else {
            draft.photos.swapAt(1, 2)
        }
        #expect(throws: RecordError.staleReview) {
            try ItemOperations.save(draft, context: context)
        }
        let reader = ModelContext(container)
        let final = try ItemOperations.item(context: reader, uuid: item.uuid)
        #expect(ItemOperations.orderedPhotos(for: final).map(\.caption) == ["Second", "First", "Third"])
        #expect(!context.hasChanges)
    }

    @Test
    func captionEditPreservesANewerOrder() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Photos")
        for (index, caption) in ["First", "Second"].enumerated() {
            context.insert(ItemPhoto(
                item: item, imageData: nil, thumbnailData: nil, caption: caption, sortOrder: index
            ))
        }
        try context.save()
        var draft = ItemOperations.draft(for: item)
        var reordered = draft
        reordered.photos.reverse()
        try ItemOperations.save(reordered, context: context)
        draft.photos[0].caption = "Revised"
        try ItemOperations.save(draft, context: context)
        let saved = try ItemOperations.item(context: ModelContext(context.container), uuid: item.uuid)
        #expect(ItemOperations.orderedPhotos(for: saved).map(\.caption) == ["Second", "Revised"])
    }

    @Test
    func deletionAndReorderPreserveUnrelatedArrivingPhotosAfterReopen() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "photo-edit.store")
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "Photos")
            for (index, caption) in ["First", "Second", "Third"].enumerated() {
                context.insert(ItemPhoto(
                    item: item, imageData: nil, thumbnailData: nil, caption: caption, sortOrder: index
                ))
            }
            try context.save()
            var draft = ItemOperations.draft(for: item)
            let other = ModelContext(container)
            let saved = try ItemOperations.item(context: other, uuid: item.uuid)
            other.insert(ItemPhoto(item: saved, imageData: nil, thumbnailData: nil, caption: "Later", sortOrder: 3))
            try other.save()
            draft.photos.removeLast()
            draft.photos.reverse()
            try ItemOperations.save(draft, context: context)
            return item.uuid
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: context, uuid: identity)
        #expect(ItemOperations.orderedPhotos(for: item).map(\.caption) == ["Second", "First", "Later"])
    }
}

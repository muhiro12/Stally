import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct ItemDraftTests {
    @Test
    func completeItemSaveSurvivesReopenWithoutImplicitHistory() async throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "item.store")
        let prepared = try await PhotoOperations.prepare(data: PhotoTestImages.imageData())
        var draft = ItemDraft(name: "Camera", note: "A gift")
        draft.representativeURL = "https://example.com/camera"
        draft.newTags = [.init(name: "Travel"), .init(name: "Travel")]
        draft.photos = [.init(prepared: prepared, caption: "Front"), .init(prepared: prepared, caption: "Back")]
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.save(draft, context: context)
            #expect(item.marks?.isEmpty == true && item.periods?.isEmpty == true)
            #expect(item.tags?.count == 2)
            #expect(Set((item.tags ?? []).map(\.uuid)).count == 2)
            return item.uuid
        }
        let container = try StallyModelContainerFactory.disk(at: url)
        let context = ModelContext(container)
        let item = try ItemOperations.item(context: context, uuid: identity)
        #expect(item.representativeURL == draft.representativeURL)
        #expect(item.note == "A gift")
        #expect(item.photos?.count == 2)
        #expect(item.photos?.allSatisfy { $0.imageData == prepared.imageData } == true)
        var edit = ItemOperations.draft(for: item)
        edit.photos.swapAt(0, 1)
        edit.photos[0].caption = "Rear"
        edit.representativeURL = ""
        try ItemOperations.save(edit, context: context)
        #expect(ItemOperations.draft(for: item).photos.map(\.caption) == ["Rear", "Front"])
        #expect(item.representativeURL == nil)
        edit = ItemOperations.draft(for: item)
        edit.photos.removeFirst()
        try ItemOperations.save(edit, context: context)
        #expect(try context.fetchCount(FetchDescriptor<ItemPhoto>()) == 1)
        #expect(item.tags?.count == 2)
    }

    @Test
    func repeatedCreationMakesDistinctItemsAndAttachments() async throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let prepared = try await PhotoOperations.prepare(data: PhotoTestImages.imageData())
        var draft = ItemDraft(name: "Same")
        draft.photos.append(.init(prepared: prepared))
        let first = try ItemOperations.save(draft, context: context)
        let second = try ItemOperations.save(draft, context: context)
        #expect(first.uuid != second.uuid)
        let firstPhoto = try #require(first.photos?.first)
        let secondPhoto = try #require(second.photos?.first)
        #expect(firstPhoto.uuid != secondPhoto.uuid)
        #expect(firstPhoto.imageData == secondPhoto.imageData)
    }

    @Test
    func draftsAreIsolatedAndUneditedValuesKeepInterveningChanges() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Before", note: "Original")
        var draft = ItemOperations.draft(for: item)
        draft.name = "After"
        draft.newTags.append(.init(name: "Unsaved"))
        #expect(item.name == "Before")
        #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
        #expect(!context.hasChanges)
        try ItemOperations.update(item, name: "Before", note: "Another edit", context: context)
        let tag = try TagOperations.create(name: "Added later", context: context)
        try TagOperations.assign([tag], to: item, context: context)
        try ItemOperations.setFavorite(item, to: true, context: context)
        try ItemOperations.save(draft, context: context)
        #expect(item.name == "After" && item.note == "Another edit")
        #expect(item.isFavorite)
        #expect(item.tags?.count == 2)
    }

    @Test
    func invalidSubmissionSavesNothingAndCanBeCorrected() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        var draft = ItemDraft(name: "Subject")
        draft.newTags.append(.init(name: "Tag"))
        draft.representativeURL = "example.com"
        #expect(throws: RecordError.invalidURL) {
            try ItemOperations.save(draft, context: context)
        }
        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
        #expect(!context.hasChanges)
        draft.representativeURL = "otherapp://subject/123"
        let item = try ItemOperations.save(draft, context: context)
        #expect(item.representativeURL == draft.representativeURL)
    }

    @Test
    func failedCompoundSaveRollsBackMetadataTagsAndPhotos() async throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "readonly.store")
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            return try ItemOperations.create(context: ModelContext(container), name: "Original").uuid
        }
        let schema = StallyModelContainerFactory.schema
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(
                "Stally", schema: schema, url: url, allowsSave: false, cloudKitDatabase: .none
            )
        )
        let context = ModelContext(container)
        let item = try ItemOperations.item(context: context, uuid: identity)
        var draft = ItemOperations.draft(for: item)
        draft.name = "Changed"
        draft.newTags.append(.init(name: "New"))
        let prepared = try await PhotoOperations.prepare(data: PhotoTestImages.imageData())
        draft.photos.append(.init(prepared: prepared))
        #expect(throws: (any Error).self) {
            try ItemOperations.save(draft, context: context)
        }
        #expect(item.name == "Original")
        let tags = try context.fetch(FetchDescriptor<StallyLibrary.Tag>())
        let tagCount = try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>())
        #expect(tags.isEmpty)
        #expect(tagCount == 0)
        #expect(item.tags?.isEmpty == true)
        let freshContext = ModelContext(container)
        #expect(try freshContext.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ItemPhoto>()) == 0)
        #expect(!context.hasChanges)
        #expect(draft.name == "Changed" && draft.photos.count == 1 && draft.newTags.count == 1)
    }
}

import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TagEditingTests {
    @Test(arguments: [false, true], ["Original", "Replacement"])
    func staleNameCannotReplaceAnotherRenameAfterReopen(separateContainer: Bool, submitted: String) throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "tag-name.store")
        try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let tag = try TagOperations.create(name: "Original", context: context)
            let original = tag.name
            let other = ModelContext(separateContainer ? try StallyModelContainerFactory.disk(at: url) : container)
            let saved = try #require(other.fetch(FetchDescriptor<StallyLibrary.Tag>()).first)
            try TagOperations.rename(saved, name: "Latest", context: other)
            #expect(throws: RecordError.staleReview) {
                try TagOperations.rename(tag, name: submitted, context: context, original: original)
            }
            #expect(!context.hasChanges)
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        #expect(try context.fetch(FetchDescriptor<StallyLibrary.Tag>()).first?.name == "Latest")
    }

    @Test
    func currentNameAllowsUnrelatedChangesAndRefreshesTheCaller() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let tag = try TagOperations.create(name: "Original", context: context)
        let other = ModelContext(container)
        let saved = try #require(other.fetch(FetchDescriptor<StallyLibrary.Tag>()).first)
        let item = try ItemOperations.create(context: other, name: "Added later")
        try TagOperations.assign([saved], to: item, context: other)
        try TagOperations.rename(tag, name: "Chosen", context: context, original: "Original")
        #expect(tag.name == "Chosen")
        let final = try #require(ModelContext(container).fetch(FetchDescriptor<StallyLibrary.Tag>()).first)
        #expect(final.items?.map(\.uuid) == [item.uuid])
    }

    @Test(arguments: [false, true])
    func removedOrAmbiguousTagCannotBeRenamed(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let tag = try TagOperations.create(name: "Original", context: context)
        let other = ModelContext(container)
        let saved = try #require(other.fetch(FetchDescriptor<StallyLibrary.Tag>()).first)
        if duplicate {
            let extra = StallyLibrary.Tag(name: "Duplicate")
            extra.uuid = tag.uuid
            other.insert(extra)
        } else {
            other.delete(saved)
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try TagOperations.rename(tag, name: "Chosen", context: context, original: "Original")
        }
        let remaining = try ModelContext(container).fetch(FetchDescriptor<StallyLibrary.Tag>())
        #expect(remaining.count == (duplicate ? 2 : 0))
        #expect(remaining.allSatisfy { $0.name != "Chosen" })
        #expect(!context.hasChanges)
    }
}

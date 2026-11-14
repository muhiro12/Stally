import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TagSelectionTests {
    @Test(arguments: [false, true], [false, true])
    func staleSelectionCannotRemoveAddedAssignmentsAfterReopen(separateContainer: Bool, changesSelection: Bool) throws {
        let url = try storeURL()
        let identities = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "Tagged")
            let first = try TagOperations.create(name: "Travel", context: context)
            let second = try TagOperations.create(name: "Travel", context: context)
            let third = try TagOperations.create(name: "Another", context: context)
            try TagOperations.assign([first], to: item, context: context)
            let original = Set((item.tags ?? []).map(\.uuid))
            let other = ModelContext(separateContainer ? try StallyModelContainerFactory.disk(at: url) : container)
            let parent = try ItemOperations.item(context: other, uuid: item.uuid)
            let tags = try other.fetch(FetchDescriptor<StallyLibrary.Tag>()).filter { $0.uuid != third.uuid }
            try TagOperations.assign(tags, to: parent, context: other)
            let submitted: Set<UUID> = changesSelection ? [third.uuid] : original
            #expect(throws: RecordError.staleReview) {
                try TagOperations.assign(uuids: submitted, to: item, context: context, original: original)
            }
            #expect(!context.hasChanges)
            return (item.uuid, Set([first.uuid, second.uuid]))
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: context, uuid: identities.0)
        #expect(Set((item.tags ?? []).map(\.uuid)) == identities.1)
        #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 3)
    }

    @Test(arguments: [false, true])
    func staleSelectionCannotRestoreRemovedOrReplacedAssignments(replace: Bool) throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Tagged")
        let first = try TagOperations.create(name: "Travel", context: context)
        let second = try TagOperations.create(name: "Travel", context: context)
        try TagOperations.assign([first], to: item, context: context)
        let original: Set<UUID> = [first.uuid]
        try TagOperations.assign(replace ? [second] : [], to: item, context: context)
        #expect(throws: RecordError.staleReview) {
            try TagOperations.assign(uuids: original, to: item, context: context, original: original)
        }
        #expect(Set((item.tags ?? []).map(\.uuid)) == (replace ? [second.uuid] : []))
        #expect(!context.hasChanges)
    }

    @Test
    func currentSelectionAllowsUnrelatedWritesAndSameNameReplacementAfterReopen() throws {
        let url = try storeURL()
        let identities = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            let item = try ItemOperations.create(context: context, name: "Tagged")
            let first = try TagOperations.create(name: "Travel", context: context)
            let second = try TagOperations.create(name: "Travel", context: context)
            try TagOperations.assign([first], to: item, context: context)
            let original = Set((item.tags ?? []).map(\.uuid))
            let other = ModelContext(context.container)
            let parent = try ItemOperations.item(context: other, uuid: item.uuid)
            try ItemOperations.update(parent, name: parent.name, note: "Latest note", context: other)
            try MarkOperations.add(to: parent, localDateTime: "2026-11-14", context: other)
            let savedTag = try #require(
                other.fetch(FetchDescriptor<StallyLibrary.Tag>()).first { $0.uuid == second.uuid }
            )
            try TagOperations.rename(savedTag, name: "Renamed elsewhere", context: other)
            try TagOperations.assign(uuids: [second.uuid], to: item, context: context, original: original)
            let savedItem = try ItemOperations.item(context: ModelContext(context.container), uuid: item.uuid)
            #expect(Set((savedItem.tags ?? []).map(\.uuid)) == [second.uuid])
            #expect(!context.hasChanges)
            return (item.uuid, second.uuid)
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: context, uuid: identities.0)
        #expect(Set((item.tags ?? []).map(\.uuid)) == [identities.1])
        #expect(item.tags?.first?.name == "Renamed elsewhere")
        #expect(item.note == "Latest note" && item.marks?.count == 1)
        try TagOperations.assign(uuids: [], to: item, context: context, original: [identities.1])
        let savedItem = try ItemOperations.item(context: ModelContext(context.container), uuid: item.uuid)
        #expect(savedItem.tags?.isEmpty == true)
        #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 2)
    }

    @Test(arguments: [false, true])
    func deletedOrAmbiguousNewSelectionIsNotSilentlyOmitted(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Tagged")
        let original = try TagOperations.create(name: "Original", context: context)
        let selected = try TagOperations.create(name: "Selected", context: context)
        try TagOperations.assign([original], to: item, context: context)
        let other = ModelContext(container)
        let saved = try #require(other.fetch(FetchDescriptor<StallyLibrary.Tag>()).first { $0.uuid == selected.uuid })
        if duplicate {
            let additional = StallyLibrary.Tag(name: "Duplicate")
            additional.uuid = selected.uuid
            other.insert(additional)
        } else {
            other.delete(saved)
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try TagOperations.assign(uuids: [selected.uuid], to: item, context: context, original: [original.uuid])
        }
        let savedItem = try ItemOperations.item(context: ModelContext(container), uuid: item.uuid)
        #expect(Set((savedItem.tags ?? []).map(\.uuid)) == [original.uuid])
        #expect(!context.hasChanges)
    }

    @Test(arguments: [false, true])
    func deletedOrAmbiguousItemRejectsSelection(duplicate: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Tagged")
        let tag = try TagOperations.create(name: "Selected", context: context)
        let identity = item.uuid
        let other = ModelContext(container)
        if duplicate {
            let additional = Item(name: "Duplicate", note: nil)
            additional.uuid = identity
            other.insert(additional)
        } else {
            other.delete(try ItemOperations.item(context: other, uuid: identity))
        }
        try other.save()
        #expect(throws: duplicate ? RecordError.ambiguousIdentity : RecordError.missingRecord) {
            try TagOperations.assign(uuids: [tag.uuid], to: item, context: context, original: [])
        }
        let savedItems = try ModelContext(container).fetch(FetchDescriptor<Item>())
        #expect(savedItems.count == (duplicate ? 2 : 0))
        #expect(savedItems.allSatisfy { ($0.tags ?? []).isEmpty })
        #expect(!context.hasChanges)
    }

    private func storeURL() throws -> URL {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "tag-selection.store")
    }
}

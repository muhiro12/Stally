#if DEBUG
import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct DevelopmentStoreTests {
    @Test
    func representativeGraphSurvivesDiskReopen() throws {
        let directory = newDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let identities = try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory)
            let context = container.mainContext
            #expect(!context.autosaveEnabled)
            #expect(container.configurations.allSatisfy { $0.cloudKitContainerIdentifier == nil })
            let items = try ItemOperations.items(context: context)
            #expect(items.count == 5)
            #expect(try context.fetchCount(FetchDescriptor<ItemMark>()) == 5)
            #expect(try context.fetchCount(FetchDescriptor<ItemPeriod>()) == 5)
            #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 3)
            #expect(try context.fetchCount(FetchDescriptor<ItemPhoto>()) == 0)
            return Set(items.map(\.uuid))
        }
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory)
            let context = ModelContext(container)
            let items = try ItemOperations.items(context: context)
            #expect(Set(items.map(\.uuid)) == identities)
            let bag = try #require(items.first { $0.name == "Everyday backpack" })
            #expect(Set((bag.marks ?? []).map(\.localDateTime)) == ["2026-10-27", "2026-10-27T09:30"])
            let ended = try #require(bag.periods?.first { !$0.isOngoing })
            #expect(ended.startLocalDate == "2024" && ended.endLocalDate == "2025-10")
            #expect(bag.periods?.first(where: \.isOngoing)?.startLocalDate == "2026-02-01")
            let archivedItem = items.first(where: \.isArchived)
            let studio = try #require(archivedItem)
            #expect(studio.isFavorite && !studio.isMarkRecordingEnabled && studio.marks?.count == 1)
            let tags = try context.fetch(FetchDescriptor<StallyLibrary.Tag>())
            let sameNames = tags.filter { $0.name == "Everyday" }
            #expect(sameNames.count == 2 && Set(sameNames.map(\.uuid)).count == 2)
        }
    }

    @Test
    func editsAndDeliberateDeletionNeverTriggerReseeding() throws {
        let directory = newDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let identity = try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory)
            let context = ModelContext(container)
            let item = try #require(ItemOperations.items(context: context).first)
            try ItemOperations.update(item, name: "My edited record", note: "Keep this", context: context)
            return item.uuid
        }
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            let context = ModelContext(container)
            let editedItem = try ItemOperations.item(context: context, uuid: identity)
            #expect(editedItem.name == "My edited record" && editedItem.note == "Keep this")
            for item in try ItemOperations.items(context: context) {
                try ItemOperations.delete(item, context: context)
            }
            for tag in try context.fetch(FetchDescriptor<StallyLibrary.Tag>()) {
                try TagOperations.delete(tag, context: context)
            }
        }
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory)
            let context = ModelContext(container)
            #expect(try ItemOperations.items(context: context).isEmpty)
            #expect(try context.fetchCount(FetchDescriptor<ItemMark>()) == 0)
            #expect(try context.fetchCount(FetchDescriptor<ItemPeriod>()) == 0)
            #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
        }
    }

    @Test
    func initialOptOutRemainsEmptyWhenReenabled() throws {
        let directory = newDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            let context = ModelContext(container)
            #expect(try ItemOperations.items(context: context).isEmpty)
        }
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory)
            let context = ModelContext(container)
            #expect(try ItemOperations.items(context: context).isEmpty)
        }
    }

    @Test
    func existingDirectoryIsNotAnInitialSetup() throws {
        let directory = newDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let container = try StallyDevelopmentStore.open(in: directory)
        let context = ModelContext(container)
        #expect(try ItemOperations.items(context: context).isEmpty)
    }

    @Test
    func unreadableStoreIsRetainedWithoutFallback() throws {
        let directory = newDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "Development.store")
        let bytes = Data("Not a SQLite store; preserve for diagnosis".utf8)
        try bytes.write(to: url)
        #expect(throws: (any Error).self) {
            try StallyDevelopmentStore.open(in: directory)
        }
        #expect(try Data(contentsOf: url) == bytes)
    }

    @Test
    func previewsOwnIndependentEditableGraphs() throws {
        let first = try StallyDevelopmentStore.preview()
        let second = try StallyDevelopmentStore.preview()
        let isInMemory = first.configurations.allSatisfy(\.isStoredInMemoryOnly)
        #expect(isInMemory)
        #expect(first.configurations.allSatisfy { $0.cloudKitContainerIdentifier == nil })
        for item in try ItemOperations.items(context: first.mainContext) {
            try ItemOperations.delete(item, context: first.mainContext)
        }
        #expect(try ItemOperations.items(context: second.mainContext).count == 5)
        let items = try ItemOperations.items(context: second.mainContext)
        let recordingItem = items.first(where: \.isMarkRecordingEnabled)
        let item = try #require(recordingItem)
        try MarkOperations.add(to: item, localDateTime: "2026-10-28", context: second.mainContext)
        #expect(try second.mainContext.fetchCount(FetchDescriptor<ItemMark>()) == 6)
    }

    private func newDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }
}
#endif

#if DEBUG
import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct DevelopmentStoreTests {
    @Test(arguments: ["en", "ja"])
    func localizedRecordsSurviveReopening(_ language: String) throws {
        let directory = newDirectory()
        let expected: [String: String] = language == "ja" ? [
            "いつものリュック": "散歩やちょっとした旅に持っていく、軽いリュック。",
            "川沿いのカフェ": "窓際の席で、本を読むひととき。",
            "以前のアトリエ": "離れてからも、覚えておきたい場所。",
            "読書用メガネ": "いつから使っているか、はっきりとは覚えていない。",
            "旅のノート": ""
        ] : [
            "Everyday backpack": "A light bag for walks and small journeys.",
            "Riverside café": "A window seat and time to read.",
            "Old studio": "A place worth remembering after moving on.",
            "Reading glasses": "No exact start date remembered.",
            "Travel journal": ""
        ]
        let expectedTags = language == "ja" ? ["日常", "日常", "場所"] : ["Everyday", "Everyday", "Places"]
        let identities = try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            try StallyDevelopmentSeed.insert(in: container.mainContext, locale: .init(identifier: language))
            let items = try ItemOperations.items(context: container.mainContext)
            #expect(Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.note) }) == expected)
            let tags = try container.mainContext.fetch(FetchDescriptor<StallyLibrary.Tag>())
            #expect(tags.map(\.name).sorted() == expectedTags.sorted())
            return Set(items.map(\.uuid))
        }
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory)
            let items = try ItemOperations.items(context: container.mainContext)
            #expect(Set(items.map(\.uuid)) == identities)
            #expect(Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.note) }) == expected)
        }
    }

    @Test
    func representativeGraphSurvivesDiskReopen() throws {
        let directory = newDirectory()
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
            let bag = try #require(items.first { $0.isFavorite && !$0.isArchived })
            #expect(Set((bag.marks ?? []).map(\.localDateTime)) == ["2026-10-27", "2026-10-27T09:30"])
            let ended = try #require(bag.periods?.first { !$0.isOngoing })
            #expect(ended.startLocalDate == "2024" && ended.endLocalDate == "2025-10")
            #expect(bag.periods?.first(where: \.isOngoing)?.startLocalDate == "2026-02-01")
            let archivedItem = items.first(where: \.isArchived)
            let studio = try #require(archivedItem)
            #expect(studio.isFavorite && !studio.isMarkRecordingEnabled && studio.marks?.count == 1)
            let tags = try context.fetch(FetchDescriptor<StallyLibrary.Tag>())
            let everydayName = try #require(bag.tags?.first?.name)
            let sameNames = tags.filter { $0.name == everydayName }
            #expect(sameNames.count == 2 && Set(sameNames.map(\.uuid)).count == 2)
        }
    }

    @Test
    func editsAndDeliberateDeletionNeverTriggerReseeding() throws {
        let directory = newDirectory()
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
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let container = try StallyDevelopmentStore.open(in: directory)
        let context = ModelContext(container)
        #expect(try ItemOperations.items(context: context).isEmpty)
    }

    @Test
    func unreadableStoreIsRetainedWithoutFallback() throws {
        let directory = newDirectory()
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
        PersistentTestDirectory.makeURL()
    }
}
#endif

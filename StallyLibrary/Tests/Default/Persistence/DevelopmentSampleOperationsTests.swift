#if DEBUG
import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct DevelopmentSampleOperationsTests {
    @Test
    func manualInsertionAfterInitialOptOutSurvivesReopenAndRejectsDuplicates() throws {
        let directory = newDirectory()
        let identities = try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            let context = container.mainContext
            try DevelopmentSampleOperations.insert(context: context, developmentDirectory: directory)
            let snapshot = try DiagnosticsOperations.snapshot(context: context)
            #expect(snapshot.items == 5 && snapshot.marks == 5 && snapshot.periods == 5)
            #expect(snapshot.tags == 3 && snapshot.photos == 0 && !context.hasChanges)
            #expect(throws: DevelopmentSampleOperations.InsertionError.containsRecords) {
                try DevelopmentSampleOperations.insert(context: context, developmentDirectory: directory)
            }
            return Set(try ItemOperations.items(context: context).map(\.uuid))
        }
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            #expect(Set(try ItemOperations.items(context: container.mainContext).map(\.uuid)) == identities)
        }
    }

    @Test
    func manualInsertionAfterDeliberateDeletionNeedsNoRestart() throws {
        let directory = newDirectory()
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory)
            let context = container.mainContext
            let oldIdentities = Set(try ItemOperations.items(context: context).map(\.uuid))
            for item in try ItemOperations.items(context: context) {
                try ItemOperations.delete(item, context: context)
            }
            for tag in try context.fetch(FetchDescriptor<StallyLibrary.Tag>()) {
                try TagOperations.delete(tag, context: context)
            }
            try DevelopmentSampleOperations.insert(context: context, developmentDirectory: directory)
            let newIdentities = Set(try ItemOperations.items(context: context).map(\.uuid))
            #expect(newIdentities.count == 5 && oldIdentities.isDisjoint(with: newIdentities))
        }
    }

    @Test
    func pendingEditsAndOtherContextsArePreserved() throws {
        let directory = newDirectory()
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            let context = container.mainContext
            let item = Item(name: "Unsaved", note: "")
            context.insert(item)
            #expect(throws: RecordError.pendingChanges) {
                try DevelopmentSampleOperations.insert(context: context, developmentDirectory: directory)
            }
            #expect(context.hasChanges && item.name == "Unsaved")
            let other = ModelContext(container)
            #expect(try other.fetchCount(FetchDescriptor<Item>()) == 0)
            #expect(throws: RecordError.wrongContext) {
                try DevelopmentSampleOperations.insert(context: other, developmentDirectory: directory)
            }
        }
    }

    @Test
    func publicEntryRejectsAnUnrelatedLocalStoreAndPreview() throws {
        let directory = newDirectory()
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            #expect(throws: DevelopmentSampleOperations.InsertionError.unsupportedStore) {
                try DevelopmentSampleOperations.insert(context: container.mainContext)
            }
            #expect(try container.mainContext.fetchCount(FetchDescriptor<Item>()) == 0)
        }
        let preview = try StallyModelContainerFactory.inMemory()
        #expect(throws: DevelopmentSampleOperations.InsertionError.unsupportedStore) {
            try DevelopmentSampleOperations.insert(context: preview.mainContext)
        }
    }

    @Test
    func cloudBackedSharedReadonlyAndMultipleConfigurationsAreRejectedBeforeOpening() throws {
        let directory = newDirectory()
        let schema = StallyModelContainerFactory.schema
        let local = ModelConfiguration(
            "Stally",
            schema: schema,
            url: directory.appending(path: "Development.store"),
            cloudKitDatabase: .none
        )
        let cloud = ModelConfiguration(
            "Stally",
            schema: schema,
            url: local.url,
            cloudKitDatabase: .private(StallyModelContainerFactory.cloudKitContainerIdentifier)
        )
        let shared = ModelConfiguration(
            "Stally",
            schema: schema,
            url: directory.appending(path: "Stally.store"),
            cloudKitDatabase: .none
        )
        let readonly = ModelConfiguration(
            "Stally",
            schema: schema,
            url: local.url,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let candidates: [Set<ModelConfiguration>] = [[cloud], [shared], [readonly], [local, shared], []]
        for configurations in candidates {
            #expect(throws: DevelopmentSampleOperations.InsertionError.unsupportedStore) {
                try DevelopmentSampleOperations.validateStore(configurations, developmentDirectory: directory)
            }
        }
    }

    @Test(arguments: ["item", "mark", "period", "photo", "tag"])
    func anyExistingRecordPreventsInsertion(_ kind: String) throws {
        let directory = newDirectory()
        try autoreleasepool {
            let container = try StallyDevelopmentStore.open(in: directory, automaticallySeed: false)
            let context = container.mainContext
            let item = Item(name: "Existing", note: "")
            switch kind {
            case "item":
                context.insert(item)
            case "mark":
                let mark = ItemMark(item: item, localDateTime: "2026-10-28")
                mark.item = nil
                context.insert(mark)
            case "period":
                let period = ItemPeriod(item: item, startLocalDate: nil, endLocalDate: nil, isOngoing: true)
                period.item = nil
                context.insert(period)
            case "photo":
                let photo = ItemPhoto(item: item, imageData: Data(), thumbnailData: nil, caption: "", sortOrder: 0)
                photo.item = nil
                context.insert(photo)
            default:
                context.insert(StallyLibrary.Tag(name: "Existing"))
            }
            try context.save()
            #expect(throws: DevelopmentSampleOperations.InsertionError.containsRecords) {
                try DevelopmentSampleOperations.insert(context: context, developmentDirectory: directory)
            }
            #expect(!context.hasChanges)
            let counts = try DiagnosticsOperations.snapshot(context: context)
            #expect(counts.items + counts.marks + counts.periods + counts.photos + counts.tags == 1)
        }
    }

    @Test
    func redirectedDevelopmentDirectoryIsRejected() throws {
        let parent = newDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }
        let realDirectory = parent.appending(path: "Real")
        let developmentDirectory = parent.appending(path: "Development")
        try FileManager.default.createDirectory(at: realDirectory, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: developmentDirectory, withDestinationURL: realDirectory)
        let configuration = ModelConfiguration(
            "Stally",
            schema: StallyModelContainerFactory.schema,
            url: developmentDirectory.appending(path: "Development.store"),
            cloudKitDatabase: .none
        )
        #expect(throws: DevelopmentSampleOperations.InsertionError.unsupportedStore) {
            try DevelopmentSampleOperations.validateStore([configuration], developmentDirectory: developmentDirectory)
        }
    }

    private func newDirectory() -> URL {
        PersistentTestDirectory.makeURL()
    }
}
#endif

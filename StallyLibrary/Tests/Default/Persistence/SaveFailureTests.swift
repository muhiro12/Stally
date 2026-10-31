import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct SaveFailureTests {
    @Test
    func failedSaveRollsBackOnlyTheAttemptedOperation() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "readonly.store")
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            return try ItemOperations.create(context: context, name: "Original").uuid
        }
        try autoreleasepool {
            let schema = StallyModelContainerFactory.schema
            let configuration = ModelConfiguration(
                "Stally",
                schema: schema,
                url: url,
                allowsSave: false,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            let context = ModelContext(container)
            context.autosaveEnabled = false
            let item = try ItemOperations.item(context: context, uuid: identity)
            #expect(throws: (any Error).self) {
                try ItemOperations.update(item, name: "Rejected", note: "Rejected", context: context)
            }
            #expect(item.name == "Original" && item.note.isEmpty)
            #expect(!context.hasChanges)
        }
        let reopened = try StallyModelContainerFactory.disk(at: url)
        let context = ModelContext(reopened)
        #expect(try ItemOperations.item(context: context, uuid: identity).name == "Original")
    }

    @Test
    func foreignContextAndDuplicateIdentityNeverChooseAnotherRecord() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let otherContext = ModelContext(container)
        let first = try ItemOperations.create(context: context, name: "Same")
        #expect(throws: RecordError.wrongContext) {
            try ItemOperations.setFavorite(first, to: true, context: otherContext)
        }
        #expect(!first.isFavorite)
        let second = try ItemOperations.create(context: context, name: "Same")
        second.uuid = first.uuid
        try context.save()
        #expect(throws: RecordError.ambiguousIdentity) {
            try ItemOperations.item(context: context, uuid: first.uuid)
        }
        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 2)
    }
}

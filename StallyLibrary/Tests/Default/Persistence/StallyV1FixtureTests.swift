import CoreData
import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct StallyV1FixtureTests {
        @Test
        func `frozen V1 matches original entity hashes and reads the actual store`() throws {
            try withStoreCopy { storeURL in
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: NSSQLiteStoreType,
                    at: storeURL,
                    options: [NSReadOnlyPersistentStoreOption: true]
                )
                let originalHashes = try #require(metadata[NSStoreModelVersionHashesKey] as? [String: Data])
                let model = try #require(NSManagedObjectModel.makeManagedObjectModel(for: StallySchemaV1.models))
                #expect(model.entityVersionHashesByName == originalHashes)
                let schema = Schema(versionedSchema: StallySchemaV1.self)
                let container = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
                )
                let context = ModelContext(container)
                let items = try context.fetch(FetchDescriptor<StallySchemaV1.Item>())
                try verifyFrozenItems(items)
            }
        }

        @Test
        func `original V1 disk preserves identities marks photos and saved links`() throws {
            let expected = try JSONDecoder().decode(BackupSnapshot.self, from: fixtureData("backup-v2.stallybackup"))
            let links = try JSONDecoder().decode([String].self, from: fixtureData("links.json"))
            try withStoreCopy { storeURL in
                for _ in 0..<2 {
                    try autoreleasepool {
                        let context = try makeContext(at: storeURL)
                        let items = try ItemOperations.items(context: context)
                        let snapshot = BackupOperations.snapshot(for: items, exportedAt: expected.exportedAt)
                        #expect(snapshot.items == expected.items)
                        #expect(items.flatMap(\.marks).count == 4)
                        for item in items {
                            #expect(item.recordsMarks)
                            #expect(item.startRawValue == nil)
                            #expect(item.marks.allSatisfy { mark in
                                mark.item?.uuid == item.uuid
                            })
                            let url = StallyLinkOperations.url(for: .item(item.uuid))
                            #expect(links.contains(url.absoluteString))
                            #expect(StallyLinkOperations.parse(url) == .supported(.item(item.uuid)))
                        }
                        #expect(try items.first { item in
                            item.photoData != nil
                        }?.photoData == fixtureData("photo.jpg"))
                    }
                }
            }
        }

        @Test
        func `original empty V1 disk reopens without creating records`() throws {
            try withStoreCopy(subdirectory: "Empty") { storeURL in
                let context = try makeContext(at: storeURL)
                #expect(try ItemOperations.items(context: context).isEmpty)
            }
        }

        @Test
        func `version two tracking fields persist after an actual V1 migration`() throws {
            try withStoreCopy { storeURL in
                let itemID = try autoreleasepool {
                    let context = try makeContext(at: storeURL)
                    let item = try #require(try ItemOperations.items(context: context).first(where: \.marks.isEmpty))
                    item.recordsMarks = false
                    item.startRawValue = "2020-09"
                    try context.save()
                    return item.uuid
                }
                for _ in 0..<2 {
                    try autoreleasepool {
                        let context = try makeContext(at: storeURL)
                        let item = try #require(try ItemOperations.item(context: context, uuid: itemID))
                        #expect(!item.recordsMarks)
                        #expect(item.startRawValue == "2020-09")
                        #expect(item.marks.isEmpty)
                    }
                }
            }
        }

        @Test
        func `a refused migration preserves the independent original fixture`() throws {
            let original = try fixtureData("Stally.store")
            try withStoreCopy { storeURL in
                let schema = StallyModelContainerFactory.schema
                #expect(throws: (any Error).self) {
                    _ = try ModelContainer(
                        for: schema,
                        migrationPlan: StallyMigrationPlan.self,
                        configurations: [ModelConfiguration(
                            schema: schema, url: storeURL, allowsSave: false, cloudKitDatabase: .none
                        )]
                    )
                }
            }
            #expect(try fixtureData("Stally.store") == original)
        }

        @Test
        func `original v2 backup restores and repeated merge preserves identity`() throws {
            let data = try fixtureData("backup-v2.stallybackup")
            let expected = try JSONDecoder().decode(BackupSnapshot.self, from: data)
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let result = try BackupOperations.replaceLibrary(data: data, context: context)
            #expect(result.insertedItemCount == 4)
            #expect(result.insertedMarkCount == 4)
            let repeated = try BackupOperations.mergeIntoLibrary(data: data, context: context)
            #expect(repeated.insertedItemCount == 0)
            #expect(repeated.insertedMarkCount == 0)
            let items = try ItemOperations.items(context: context)
            #expect(BackupOperations.snapshot(for: items, exportedAt: expected.exportedAt).items == expected.items)
        }

        private func verifyFrozenItems(_ items: [StallySchemaV1.Item]) throws {
            let expected = try JSONDecoder().decode(
                BackupSnapshot.self, from: fixtureData("backup-v2.stallybackup")
            )
            #expect(items.count == expected.items.count)
            for item in items {
                let original = try #require(expected.items.first { $0.id == item.uuid })
                #expect(item.name == original.name)
                #expect(item.categoryRawValue == original.categoryRawValue)
                #expect(item.note == original.note)
                #expect(item.photoData == original.photoData)
                #expect(item.createdAt == original.createdAt)
                #expect(item.archivedAt == original.archivedAt)
                let marks = item.markRecords ?? []
                #expect(marks.count == original.marks.count)
                for mark in marks {
                    let originalMark = try #require(original.marks.first { $0.id == mark.uuid })
                    #expect(mark.dayKey == originalMark.day.dayKey)
                    #expect(mark.createdAt == originalMark.createdAt)
                    #expect(mark.item?.uuid == item.uuid)
                }
            }
        }

        private func fixtureData(_ name: String) throws -> Data {
            try Data(contentsOf: fixtureDirectory().appendingPathComponent(name))
        }

        private func fixtureDirectory() throws -> URL {
            try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
                .appendingPathComponent("V1")
        }

        private func withStoreCopy(
            subdirectory: String? = nil,
            _ body: (URL) throws -> Void
        ) throws {
            let directory = try persistentTestDirectory(fileManager: .default)
            let storeCopy = directory.appendingPathComponent("V1", isDirectory: true)
            let source = try fixtureDirectory()
            try FileManager.default.copyItem(
                at: subdirectory.map { source.appendingPathComponent($0) } ?? source,
                to: storeCopy
            )
            try body(storeCopy.appendingPathComponent("Stally.store"))
        }

        private func makeContext(at storeURL: URL) throws -> ModelContext {
            let schema = StallyModelContainerFactory.schema
            let container = try ModelContainer(
                for: schema,
                migrationPlan: StallyMigrationPlan.self,
                configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
            )
            return .init(container)
        }
    }
}

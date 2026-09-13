import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct StallyV1FixtureTests {
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
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let source = try fixtureDirectory()
            try FileManager.default.copyItem(
                at: subdirectory.map { source.appendingPathComponent($0) } ?? source,
                to: directory
            )
            defer {
                try? FileManager.default.removeItem(at: directory)
            }
            try body(directory.appendingPathComponent("Stally.store"))
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

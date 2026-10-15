import Foundation
import StallyLibrary
import Testing

@Suite
struct ItemSearchIndexTests {
    @Test
    func `namespace identifiers cannot open another namespace or malformed item`() {
        let identifier = UUID()
        let activity = ItemSearchIndexOperations.activityIdentifier(itemID: identifier, namespace: "production")
        #expect(ItemSearchIndexOperations.itemID(activityIdentifier: activity, namespace: "production") == identifier)
        #expect(ItemSearchIndexOperations.itemID(activityIdentifier: activity, namespace: "test") == nil)
        let malformed = ItemSearchIndexOperations.itemID(
            activityIdentifier: "production/not-a-uuid",
            namespace: "production"
        )
        #expect(malformed == nil)
        let extraPath = ItemSearchIndexOperations.itemID(
            activityIdentifier: activity + "/extra",
            namespace: "production"
        )
        #expect(extraPath == nil)
    }

    @Test
    func `search projection encodes only approved fields and preserves equal names`() throws {
        let first = entry(name: "Same Name")
        let second = entry(name: "Same Name")
        let data = try JSONEncoder().encode(first)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["uuid", "name", "categoryRawValue", "isArchived"])
        #expect(ItemSearchIndexOperations.identifiers(for: [first, second]).count == 2)
    }

    @Test
    func `reconciliation keeps archive and more than the suggestion limit`() {
        let entries = (0..<45).map { _ in
            entry(name: "Item")
        }
        let removed = UUID()
        let previous = ItemSearchIndexOperations.identifiers(for: entries).union([removed])
        #expect(ItemSearchIndexOperations.removedIdentifiers(previous: previous, current: entries) == [removed])
        #expect(ItemSearchIndexOperations.identifiers(for: entries).count == 45)
    }

    @Test
    func `interrupted addition is tracked and removed after source deletion`() async throws {
        let sink = SearchIndexTestSink()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let synchronizer = ItemSearchIndexSynchronizer(
            sink: sink,
            ledgerURL: directory.appendingPathComponent("ledger.json")
        )
        let added = entry(name: "Interrupted")
        try await synchronizer.synchronize([], revision: 1, force: false)
        await sink.failNextUpsert()
        await #expect(throws: SearchIndexTestSink.Failure.self) {
            try await synchronizer.synchronize([added], revision: 2, force: false)
        }
        try await synchronizer.synchronize([], revision: 3, force: false)
        #expect(await sink.rows().isEmpty)
    }

    @Test
    func `edit archive restore and late revisions preserve current identity`() async throws {
        let sink = SearchIndexTestSink()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let synchronizer = ItemSearchIndexSynchronizer(
            sink: sink,
            ledgerURL: directory.appendingPathComponent("ledger.json")
        )
        let original = entry(name: "Original")
        let edited = ItemSearchIndexEntry(
            uuid: original.uuid,
            name: "Edited",
            categoryRawValue: "Bags",
            isArchived: true
        )
        try await synchronizer.synchronize([original], revision: 1, force: false)
        try await synchronizer.synchronize([edited], revision: 3, force: false)
        try await synchronizer.synchronize([original], revision: 2, force: false)
        #expect(await sink.rows() == [original.uuid: edited])
        let restored = entry(name: "Restored")
        try await synchronizer.synchronize([restored], revision: 4, force: true)
        #expect(await sink.rows() == [restored.uuid: restored])
    }

    @Test
    func `corrupt tracking state rebuilds only the owned namespace`() async throws {
        let sink = SearchIndexTestSink()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let ledger = directory.appendingPathComponent("ledger.json")
        try Data("invalid".utf8).write(to: ledger)
        let synchronizer = ItemSearchIndexSynchronizer(sink: sink, ledgerURL: ledger)
        try await synchronizer.synchronize([], revision: 1, force: true)
        #expect(await sink.resetCount() == 1)
    }

    @Test
    func `unchanged snapshots avoid writes until reindex is requested`() async throws {
        let sink = SearchIndexTestSink()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let synchronizer = ItemSearchIndexSynchronizer(
            sink: sink,
            ledgerURL: directory.appendingPathComponent("ledger.json")
        )
        let entries = [entry(name: "Stable")]
        try await synchronizer.synchronize(entries, revision: 1, force: false)
        let initialWrites = await sink.writeCount()
        try await synchronizer.synchronize(entries, revision: 2, force: false)
        #expect(await sink.writeCount() == initialWrites)
        try await synchronizer.synchronize(entries, revision: 3, force: true)
        #expect(await sink.writeCount() > initialWrites)
    }

    @Test
    func `failed removal is retried from the retained ledger after restart`() async throws {
        let sink = SearchIndexTestSink()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let ledger = directory.appendingPathComponent("ledger.json")
        let synchronizer = ItemSearchIndexSynchronizer(sink: sink, ledgerURL: ledger)
        let original = entry(name: "Removed")
        try await synchronizer.synchronize([original], revision: 1, force: false)
        await sink.failNextRemoval()
        await #expect(throws: SearchIndexTestSink.Failure.self) {
            try await synchronizer.synchronize([], revision: 2, force: false)
        }
        #expect(await sink.rows()[original.uuid] == original)
        let resumed = ItemSearchIndexSynchronizer(sink: sink, ledgerURL: ledger)
        try await resumed.synchronize([], revision: 1, force: false)
        #expect(await sink.rows().isEmpty)
        #expect(await sink.resetCount() == 1)
    }

    private func entry(name: String) -> ItemSearchIndexEntry {
        .init(uuid: UUID(), name: name, categoryRawValue: "Other", isArchived: false)
    }
}

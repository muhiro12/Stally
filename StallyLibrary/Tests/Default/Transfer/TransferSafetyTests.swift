import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferSafetyTests {
    @Test
    func failedDiskSaveLeavesEverySelectedRecordUnchanged() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("records.store")
        let archive = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            try ItemOperations.create(context: context, name: "Existing")
            var archive = try TransferOperations.export(context: context, includingImages: false)
            var manifest = archive.manifest
            manifest.items[0].name = "Rejected"
            manifest.tags.append(.init(uuid: UUID(), name: "Never Saved"))
            archive = .init(manifest: manifest, media: [:])
            return archive
        }
        try autoreleasepool {
            let schema = StallyModelContainerFactory.schema
            let configuration = ModelConfiguration(
                "Read Only",
                schema: schema,
                url: url,
                allowsSave: false,
                cloudKitDatabase: .none
            )
            let context = ModelContext(try ModelContainer(for: schema, configurations: [configuration]))
            let review = try TransferOperations.review(archive, context: context)
            #expect(throws: (any Error).self) {
                try TransferOperations.apply(
                    review,
                    selection: Set(review.rows.map(\.id)),
                    today: "2026-10-31",
                    context: context
                )
            }
            #expect(try context.fetch(FetchDescriptor<Item>()).first?.name == "Existing")
            #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
        }
        let reopened = ModelContext(try StallyModelContainerFactory.disk(at: url))
        #expect(try reopened.fetch(FetchDescriptor<Item>()).first?.name == "Existing")
        #expect(try reopened.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
    }

    @Test
    func crossTypeCollisionsAndChildReparentingNeverBecomeUpdates() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let first = try ItemOperations.create(context: context, name: "Same")
        let second = try ItemOperations.create(context: context, name: "Same")
        try MarkOperations.add(to: first, localDateTime: "2026-10-31", context: context)
        let archive = try TransferOperations.export(context: context, includingImages: false)
        var reparented = archive.manifest
        reparented.itemMarks[0].itemUUID = second.uuid
        #expect(throws: TransferError.self) {
            try TransferOperations.review(.init(manifest: reparented, media: [:]), context: context)
        }
        var collision = archive.manifest
        collision.tags.append(.init(uuid: first.uuid, name: "Collision"))
        #expect(throws: TransferError.self) { try TransferCodec.decode(TransferCodec.encode(collision)) }
    }

    @Test
    func duplicatesObservedByTheWriterThrowInsteadOfChoosingOrTrapping() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Import")
        let tag = try TagOperations.create(name: "First", context: context)
        let archive = try TransferOperations.export(context: context, includingImages: false)
        let duplicate = StallyLibrary.Tag(name: "Incoming Duplicate")
        duplicate.uuid = tag.uuid
        context.insert(duplicate)
        try context.save()
        let writer = ModelContext(context.container)
        #expect(throws: RecordError.ambiguousIdentity) {
            try TransferImportMutation.apply(archive, selection: [item.uuid], today: "2026-10-31", context: writer)
        }
        #expect(!writer.hasChanges)
    }

    @Test
    func selectedPeriodGraphMustBeValidWithoutChangingStoredFacts() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "History")
        try PeriodOperations.add(to: item, input: .init(start: "2024"), today: "2026-10-31", context: context)
        let archive = try TransferOperations.export(context: context, includingImages: false)
        var manifest = archive.manifest
        let extra = TransferPeriod(
            uuid: UUID(),
            itemUUID: item.uuid,
            startLocalDate: "2025",
            endLocalDate: nil,
            isOngoing: true,
            createdAt: .now
        )
        manifest.itemPeriods.append(extra)
        let review = try TransferOperations.review(.init(manifest: manifest, media: [:]), context: context)
        #expect(throws: RecordError.ongoingPeriodExists) {
            try TransferOperations.apply(
                review,
                selection: review.defaultSelection,
                today: "2026-10-31",
                context: context
            )
        }
        #expect(try ModelContext(context.container).fetchCount(FetchDescriptor<ItemPeriod>()) == 1)
        #expect(!context.hasChanges)
    }
}

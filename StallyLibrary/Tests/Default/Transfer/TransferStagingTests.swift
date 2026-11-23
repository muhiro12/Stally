import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferStagingTests {
    @Test
    func mappedBytesOwnTheirFilesUntilReleased() throws {
        var staging: TransferStaging? = try .init()
        let directory = try #require(staging?.directory)
        let original = Data(repeating: 42, count: 65_536)
        try staging?.write(original, path: "payload")
        try autoreleasepool {
            let mapped = try staging?.data(path: "payload")
            let data = try #require(mapped)
            staging = nil
            #expect(FileManager.default.fileExists(atPath: directory.path))
            #expect(data == original)
        }
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test
    func editingReturnedDataDoesNotModifyTheReviewedFile() throws {
        let staging = try TransferStaging()
        let original = Data(repeating: 42, count: 65_536)
        try staging.write(original, path: "payload")
        var returned = try staging.data(path: "payload")
        returned[0] = 1
        #expect(returned[0] == 1)
        #expect(try staging.data(path: "payload") == original)
    }

    @Test
    func failedExportPreservesExistingDestination() async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Photo")
        draft.photos = [.init(prepared: try await PhotoOperations.prepare(data: PhotoTestImages.imageData()))]
        try ItemOperations.save(draft, context: context)
        let valid = try TransferOperations.export(context: context, includingImages: true)
        let missingMedia = TransferArchive(manifest: valid.manifest, media: [:])
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appending(path: "Existing.stally")
        let original = Data("Existing destination".utf8)
        try original.write(to: destination)
        await #expect(throws: TransferError.invalidFile) {
            try await TransferFileOperations.write(missingMedia, to: destination)
        }
        #expect(try Data(contentsOf: destination) == original)
    }

    @Test
    func failedSaveWithMappedPhotosLeavesTheReopenedStoreUnchanged() async throws {
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Photo")
        draft.photos = [.init(prepared: try await PhotoOperations.prepare(data: PhotoTestImages.imageData()))]
        try ItemOperations.save(draft, context: source)
        let exported = try await TransferOperations.prepareExport(context: source, includingImages: true)
        let file = try await TransferFileOperations.writeTemporary(exported)
        defer { try? FileManager.default.removeItem(at: file) }
        let incoming = try await TransferFileOperations.read(file)
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "records.store")
        try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            try ItemOperations.create(context: context, name: "Keep")
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
            let review = try TransferOperations.review(incoming, context: context)
            #expect(review.defaultSelection.count == 2)
            #expect(throws: (any Error).self) {
                try TransferOperations.apply(
                    review,
                    selection: review.defaultSelection,
                    today: "2026-11-14",
                    context: context
                )
            }
            #expect(!context.hasChanges)
        }
        let reopened = ModelContext(try StallyModelContainerFactory.disk(at: url))
        #expect(try reopened.fetch(FetchDescriptor<Item>()).map(\.name) == ["Keep"])
        #expect(try reopened.fetchCount(FetchDescriptor<ItemPhoto>()) == 0)
    }

    @Test
    func cancelledPreparationNeverChangesRecords() async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Keep")
        let task = Task { try await TransferOperations.prepareExport(context: context, includingImages: true) }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(try ItemOperations.item(context: context, uuid: item.uuid).name == "Keep")
        #expect(!context.hasChanges)
    }

    @Test
    func typedCodecRetainsNullableKeysAndLowercaseIdentitiesPastOldCountLimit() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var manifest = try TransferOperations.export(context: context, includingImages: false).manifest
        manifest.tags = (0..<50_001).map { .init(uuid: UUID(), name: "Tag \($0)") }
        let budget = TransferBudget(memoryBytes: 1_073_741_824)
        let data = try TransferCodec.encode(manifest, budget: budget)
        let decoded = try TransferCodec.decode(data, budget: budget)
        #expect(decoded.tags == manifest.tags)
        #expect(
            try #require(String(data: data, encoding: .utf8)).contains(manifest.tags[0].uuid.uuidString.lowercased())
        )
    }

    @Test
    func typedCodecAcceptsLargeTextWhenResourcesAllow() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        try ItemOperations.create(context: context, name: "Large text")
        var manifest = try TransferOperations.export(context: context, includingImages: false).manifest
        let note = String(repeating: "x", count: 34 * 1_048_576)
        manifest.items[0].note = note
        let budget = TransferBudget(memoryBytes: 1_073_741_824)
        let encoded = try TransferCodec.encode(manifest, budget: budget)
        #expect(encoded.count > 33_554_432)
        #expect(try TransferCodec.decode(encoded, budget: budget).items[0].note == note)
    }
}

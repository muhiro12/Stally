import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferCompatibilityTests {
    @Test(arguments: [Date(timeIntervalSince1970: 946_684_800), Date.now])
    func supportedFilesCanBeImportedRegardlessOfExportDate(exportedAt: Date) async throws {
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: source, name: "Portable record")
        var manifest = try TransferOperations.export(context: source, includingImages: false).manifest
        manifest.exportedAt = exportedAt
        let data = try TransferCodec.encode(manifest)
        let archive = try await TransferFileOperations.readRecords(data)
        let target = ModelContext(try StallyModelContainerFactory.inMemory())
        let review = try TransferOperations.review(archive, context: target)
        try TransferOperations.apply(
            review,
            selection: review.defaultSelection,
            today: "2026-11-10",
            context: target
        )
        let saved = try ItemOperations.item(context: ModelContext(target.container), uuid: item.uuid)
        #expect(saved.name == "Portable record")
        #expect(saved.uuid == item.uuid)
    }

    @Test(arguments: [(2, "1.0.0"), (1, "2.0.0"), (0, "1.0.0"), (1, "0.0.0")])
    func unsupportedPairsRejectBeforeImport(formatVersion: Int, schemaVersion: String) async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Current record")
        var manifest = try TransferOperations.export(context: context, includingImages: false).manifest
        manifest.formatVersion = formatVersion
        manifest.schemaVersion = schemaVersion
        manifest.items[0].name = "Incoming change"
        let data = try TransferCodec.encode(manifest)
        await #expect(throws: TransferError.unsupportedVersion) {
            let archive = try await TransferFileOperations.readRecords(data)
            let review = try TransferOperations.review(archive, context: context)
            try TransferOperations.apply(
                review,
                selection: Set(review.rows.map(\.id)),
                today: "2026-11-10",
                context: context
            )
        }
        let saved = try ItemOperations.item(context: ModelContext(context.container), uuid: item.uuid)
        #expect(saved.name == "Current record")
        #expect(!context.hasChanges)
    }
}

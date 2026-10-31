import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferLimitTests {
    @Test
    func byteAndCountBudgetsRejectWithoutPartialImport() throws {
        let oversized = Data(repeating: 0, count: TransferCodec.maximumJSONBytes + 1)
        #expect(throws: TransferError.self) { try TransferCodec.decode(oversized) }
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let archive = try TransferOperations.export(context: context, includingImages: false)
        var manifest = archive.manifest
        manifest.tags = (0...TransferCodec.maximumRecordCount).map { index in
            .init(uuid: UUID(), name: "Tag \(index)")
        }
        #expect(throws: TransferError.self) { try TransferCodec.decode(TransferCodec.encode(manifest)) }
        #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
    }

    @Test
    func boundedRepresentativeMetadataWorkloadIsReplayable() throws {
        let count = 500
        let source = ModelContext(try StallyModelContainerFactory.inMemory())
        for index in 0..<count {
            source.insert(Item(name: "Item \(index)", note: "Synthetic context"))
        }
        try source.save()
        let archive = try TransferOperations.export(context: source, includingImages: false)
        let target = ModelContext(try StallyModelContainerFactory.inMemory())
        let review = try TransferOperations.review(archive, context: target)
        #expect(
            try TransferOperations.apply(
                review,
                selection: review.defaultSelection,
                today: "2026-10-31",
                context: target
            ) == count
        )
        let replay = try TransferOperations.review(archive, context: target)
        let matches = replay.rows.allSatisfy(\.isUnchanged)
        #expect(matches)
    }
}

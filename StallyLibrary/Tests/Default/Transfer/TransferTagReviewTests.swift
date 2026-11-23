import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferTagReviewTests {
    @Test(arguments: [false, true])
    func sameNameAssignmentsRemainDistinguishableAcrossBothSnapshots(includeLocalTag: Bool) async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Journey")
        let localTag = try TagOperations.create(name: "Travel", context: context)
        try TagOperations.assign([localTag], to: item, context: context)
        var manifest = try TransferOperations.export(context: context, includingImages: false).manifest
        let incomingTag = TransferTag(uuid: UUID(), name: "Travel")
        manifest.tags = includeLocalTag ? manifest.tags + [incomingTag] : [incomingTag]
        manifest.items[0].tagUUIDs = [incomingTag.uuid]
        let archive = try await TransferFileOperations.readRecords(TransferCodec.encode(manifest))
        let review = try TransferOperations.review(archive, context: context)
        let row = try #require(review.rows.first { $0.id == item.uuid })
        let current = try #require(row.current)
        #expect(!row.isUnchanged)
        #expect(!review.defaultSelection.contains(item.uuid))
        #expect(current != row.proposed)
        #expect(current.contains(localTag.uuid.uuidString))
        #expect(row.proposed.contains(incomingTag.uuid.uuidString))
        #expect(!current.contains(incomingTag.uuid.uuidString))
        #expect(!row.proposed.contains(localTag.uuid.uuidString))
        try TransferOperations.apply(
            review,
            selection: review.defaultSelection.union([item.uuid]),
            today: "2026-11-13",
            context: context
        )
        let fresh = ModelContext(context.container)
        let saved = try ItemOperations.item(context: fresh, uuid: item.uuid)
        #expect(saved.tags?.map(\.uuid) == [incomingTag.uuid])
        #expect(try fresh.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 2)
    }

    @Test
    func matchingTagIdentityDoesNotNeedDisambiguationOrCreateConflict() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Journey")
        let tag = try TagOperations.create(name: "Travel", context: context)
        try TagOperations.assign([tag], to: item, context: context)
        let archive = try TransferOperations.export(context: context, includingImages: false)
        let review = try TransferOperations.review(archive, context: context)
        let row = try #require(review.rows.first { $0.id == item.uuid })
        #expect(row.isUnchanged)
        #expect(row.current == row.proposed)
        #expect(row.proposed.contains("Travel"))
        #expect(!row.proposed.contains(tag.uuid.uuidString))
        #expect(review.defaultSelection.isEmpty)
    }
}

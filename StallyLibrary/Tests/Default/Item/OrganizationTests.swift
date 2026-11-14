import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct OrganizationTests {
    @Test(arguments: ["source", "survivor", "unassigned"])
    func consolidationRejectsDuplicateMembershipArrivingAfterReview(assignment: String) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Tagged")
        let source = try TagOperations.create(name: "Source", context: context)
        let survivor = try TagOperations.create(name: "Survivor", context: context)
        try TagOperations.assign([source, survivor], to: item, context: context)
        let review = try TagOperations.reviewConsolidation(source: source, survivor: survivor, context: context)
        let other = ModelContext(container)
        let tags = try other.fetch(FetchDescriptor<StallyLibrary.Tag>())
        let targetID = assignment == "survivor" ? survivor.uuid : source.uuid
        let target = try #require(tags.first { $0.uuid == targetID })
        let duplicate = Item(name: "Unreviewed duplicate", note: nil)
        duplicate.uuid = item.uuid
        duplicate.tags = assignment == "unassigned" ? [] : [target]
        other.insert(duplicate)
        try other.save()
        #expect(throws: RecordError.ambiguousIdentity) {
            try TagOperations.consolidate(review, context: context)
        }
        let reader = ModelContext(container)
        #expect(try reader.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 2)
        #expect(try reader.fetchCount(FetchDescriptor<Item>()) == 2)
        #expect(!context.hasChanges)
    }

    @Test
    func explicitConsolidationPreservesItemsAndStaleMembershipRejects() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Tagged")
        let source = try TagOperations.create(name: "Same", context: context)
        let survivor = try TagOperations.create(name: "Same", context: context)
        try TagOperations.assign([source], to: item, context: context)
        let review = try TagOperations.reviewConsolidation(source: source, survivor: survivor, context: context)
        let second = try ItemOperations.create(context: context, name: "Later")
        try TagOperations.assign([source], to: second, context: context)
        #expect(throws: RecordError.staleReview) { try TagOperations.consolidate(review, context: context) }
        let fresh = try TagOperations.reviewConsolidation(source: source, survivor: survivor, context: context)
        let survivorID = survivor.uuid
        try TagOperations.consolidate(fresh, context: context)
        let reader = ModelContext(context.container)
        #expect(try reader.fetchCount(FetchDescriptor<Item>()) == 2)
        #expect(try reader.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 1)
        let saved = try ItemOperations.item(context: reader, uuid: item.uuid)
        #expect(saved.tags?.map(\.uuid) == [survivorID])
    }

    @Test
    func undoTargetsAcknowledgedAdditionAndQueryRespectsArchiveScope() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Searchable")
        let first = try MarkOperations.add(to: item, localDateTime: "2026-10-31", context: context)
        let second = try MarkOperations.add(to: item, localDateTime: "2026-10-31", context: context)
        let secondID = second.uuid
        try MarkOperations.undoAddition(uuid: first.uuid, context: context)
        #expect(item.marks?.map(\.uuid) == [secondID])
        try ItemOperations.setArchived(item, to: true, context: context)
        var query = ItemQuery()
        query.text = "Search"
        #expect(query.matching([item]).isEmpty)
        query.archiveScope = .all
        #expect(query.matching([item]).count == 1)
    }
}

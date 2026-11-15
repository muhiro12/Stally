import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct RecordDeletionTests {
    @Test(arguments: ["mark", "period", "tag"])
    func ambiguousAffectedItemRejectsDeletionBeforeSaving(kind: String) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Original")
        let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-14", context: context)
        let period = try PeriodOperations.add(
            to: item, input: .init(start: "2020"), today: "2026-11-14", context: context
        )
        let tag = try TagOperations.create(name: "Shared", context: context)
        try TagOperations.assign([tag], to: item, context: context)
        let other = ModelContext(container)
        let duplicate = Item(name: "Conflicting identity", note: nil)
        duplicate.uuid = item.uuid
        other.insert(duplicate)
        try other.save()
        #expect(throws: RecordError.ambiguousIdentity) {
            switch kind {
            case "mark":
                try MarkOperations.delete(mark, context: context)
            case "period":
                try PeriodOperations.delete(period, context: context)
            default:
                try TagOperations.delete(tag, context: context)
            }
        }
        let reader = ModelContext(container)
        #expect(try reader.fetchCount(FetchDescriptor<ItemMark>()) == 1)
        #expect(try reader.fetchCount(FetchDescriptor<ItemPeriod>()) == 1)
        #expect(try reader.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 1)
        #expect(try reader.fetch(FetchDescriptor<StallyLibrary.Tag>()).first?.items?.count == 1)
        #expect(!context.hasChanges)
    }
}

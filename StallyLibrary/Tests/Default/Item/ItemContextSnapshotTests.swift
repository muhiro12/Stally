import Foundation
// Internal writes model deliberately malformed stored values, not valid edits.
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemContextSnapshotTests {
        @Test(arguments: ItemMarkPolicy.allCases, [false, true])
        func `context follows policy placement and retained history`(
            policy: ItemMarkPolicy, archived: Bool
        ) throws {
            for marked in [false, true] {
                let context = ModelContext(try StallyModelContainerFactory.inMemory())
                let today = try #require(LocalDay(containing: .now, in: .gmt))
                let item = try ItemOperations.create(
                    context: context,
                    input: .init(name: "Same Name", category: .other)
                )
                if marked {
                    try ItemOperations.mark(item, on: today, today: today, context: context)
                }
                if archived {
                    try ItemOperations.archive(item, on: .now, context: context)
                }
                // An inconsistent disabled/history combination is an isolated edge case.
                item.recordsMarks = policy.recordsMarks
                try context.save()
                let snapshot = ItemOperations.contextSnapshot(for: item, today: today)
                #expect(snapshot.itemID == item.uuid && snapshot.name == item.name)
                #expect(snapshot.capabilities.canChangeHistory == (policy == .enabled && !archived))
                #expect(snapshot.capabilities.canArchive == !archived)
                #expect(snapshot.capabilities.canMoveBackToLibrary == archived)
                #expect(snapshot.isMarkedToday == marked)
                #expect(snapshot.timeReport == nil)
            }
        }

        @Test
        func `context shares only valid time knowledge and survives later state changes`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(containing: .now, in: .gmt))
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Home", category: .other),
                tracking: .init(recordsMarks: false, start: .init(rawValue: "2000-02")),
                today: today
            )
            let snapshot = ItemOperations.contextSnapshot(for: item, today: today, locale: .init(identifier: "en"))
            let expectedReport = ItemTimeOperations.report(for: item, today: today, locale: .init(identifier: "en"))
            #expect(snapshot.timeReport == expectedReport)
            #expect(snapshot.capabilities.canArchive)
            try ItemOperations.archive(item, on: .now, context: context)
            #expect(snapshot.capabilities.canArchive)
            #expect(!ItemOperations.contextSnapshot(for: item, today: today).capabilities.canArchive)
            item.startRawValue = "2000-2"
            #expect(ItemOperations.contextSnapshot(for: item, today: today).timeReport == nil)
            context.delete(item)
            try context.save()
            #expect(snapshot.timeReport != nil)
            #expect(try ItemOperations.item(context: context, uuid: snapshot.itemID) == nil)
        }
    }
}

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemTrackingCollectionTests {
        @Test
        func `non Mark items are discoverable without entering Mark prompts`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 14))
            let plant = try ItemOperations.create(
                context: context,
                input: .init(name: "Plant", category: .other),
                tracking: .init(recordsMarks: false, start: try #require(ItemStart(rawValue: "2020-09"))),
                today: today
            )
            let bag = try ItemOperations.create(context: context, input: .init(name: "Bag", category: .bags))
            let items = [plant, bag]
            for filter in [ItemCollectionFilter.openToday, .openOnDay, .neverMarked] {
                #expect(ItemCollectionOperations.items(
                    from: items, options: .init(filter: filter), today: today, selectedDay: today
                )
                .map(\.uuid) == [bag.uuid])
            }
            for filter in [ItemCollectionFilter.withoutMarks, .withStart] {
                #expect(ItemCollectionOperations.items(
                    from: items, options: .init(filter: filter), today: nil
                )
                .map(\.uuid) == [plant.uuid])
            }
            #expect(ItemCollectionOperations.items(
                from: items, options: .init(filter: .withoutHistory), today: nil
            ).count == 2)
            #expect(!context.hasChanges)
        }

        @Test
        func `start sorts preserve precision stable ties and unknowns without changing records`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 14))
            var items: [Item] = []
            for (name, rawValue) in [
                ("Unknown", nil), ("Year", "2020"), ("Month", "2020-01"),
                ("Day", "2020-01-01"), ("Day tie", "2020-01-01"), ("New", "2025-06")
            ] as [(String, String?)] {
                items.append(try ItemOperations.create(
                    context: context,
                    input: .init(name: name, category: .other),
                    tracking: .init(recordsMarks: false, start: rawValue.flatMap(ItemStart.init(rawValue:))),
                    today: today
                ))
            }
            let invalid = try ItemOperations.create(context: context, input: .init(name: "Invalid", category: .other))
            invalid.startRawValue = "malformed"
            try context.save()
            items.append(invalid)
            let starts = items.map(\.startRawValue)
            let oldest = ItemCollectionOperations.items(from: items, options: .init(sort: .earliestStart), today: nil)
            let newest = ItemCollectionOperations.items(from: items, options: .init(sort: .latestStart), today: nil)
            #expect(oldest.map(\.name) == ["Day", "Day tie", "Month", "Year", "New", "Unknown", "Invalid"])
            #expect(newest.map(\.name) == ["New", "Year", "Month", "Day", "Day tie", "Unknown", "Invalid"])
            try ItemOperations.archive(items[1], on: .now, context: context)
            #expect(ItemCollectionOperations.items(
                from: items, options: .init(searchText: "Year", filter: .withStart, sort: .earliestStart), today: nil
            )
            .map(\.uuid) == [items[1].uuid])
            #expect(items.map(\.startRawValue) == starts)
            #expect(!context.hasChanges)
        }
    }
}

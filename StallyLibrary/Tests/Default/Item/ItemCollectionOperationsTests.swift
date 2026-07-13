//
//  ItemCollectionOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/13.
//

import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemCollectionOperationsTests {
        @Test
        func `search matches names and notes without changing default order`() throws {
            let context = try makeContext()
            let coat = try makeItem(
                named: "Black Wool Coat",
                context: context,
                note: "Cold mornings"
            )
            let tote = try makeItem(
                named: "Canvas Tote",
                context: context,
                note: "Everyday errands"
            )

            let nameMatch = ItemCollectionOperations.items(
                from: [tote, coat],
                options: .init(searchText: "wool"),
                today: nil
            )
            let noteMatch = ItemCollectionOperations.items(
                from: [tote, coat],
                options: .init(searchText: "EVERYDAY"),
                today: nil
            )

            #expect(nameMatch.map(\.uuid) == [coat.uuid])
            #expect(noteMatch.map(\.uuid) == [tote.uuid])
        }

        @Test
        func `category and history filters combine`() throws {
            let context = try makeContext()
            let markedBag = try makeItem(named: "Marked Bag", context: context, category: .bags)
            let openBag = try makeItem(named: "Open Bag", context: context, category: .bags)
            let markedShoes = try makeItem(
                named: "Marked Shoes",
                context: context,
                category: .shoes
            )
            let today = try #require(LocalDay(year: 2_026, month: 7, day: 13))
            try mark(markedBag, on: today, context: context)
            try mark(markedShoes, on: today, context: context)

            let markedBags = ItemCollectionOperations.items(
                from: [markedBag, openBag, markedShoes],
                options: .init(category: .bags, filter: .markedToday),
                today: today
            )
            let openBags = ItemCollectionOperations.items(
                from: [markedBag, openBag, markedShoes],
                options: .init(category: .bags, filter: .openToday),
                today: today
            )

            #expect(markedBags.map(\.uuid) == [markedBag.uuid])
            #expect(openBags.map(\.uuid) == [openBag.uuid])
        }

        @Test
        func `history filters use unique marked days`() throws {
            let context = try makeContext()
            let markedItem = try makeItem(named: "Marked", context: context)
            let unmarkedItem = try makeItem(named: "Unmarked", context: context)
            let day = try #require(LocalDay(year: 2_026, month: 7, day: 12))
            try mark(markedItem, on: day, context: context)

            let withHistory = ItemCollectionOperations.items(
                from: [markedItem, unmarkedItem],
                options: .init(filter: .withHistory),
                today: nil
            )
            let withoutHistory = ItemCollectionOperations.items(
                from: [markedItem, unmarkedItem],
                options: .init(filter: .withoutHistory),
                today: nil
            )

            #expect(withHistory.map(\.uuid) == [markedItem.uuid])
            #expect(withoutHistory.map(\.uuid) == [unmarkedItem.uuid])
        }

        @Test
        func `selected day filters are independent from today`() throws {
            let context = try makeContext()
            let item = try makeItem(named: "Canvas Tote", context: context)
            let selectedDay = try #require(LocalDay(year: 2_026, month: 7, day: 12))
            let today = try #require(LocalDay(year: 2_026, month: 7, day: 13))
            try mark(item, on: selectedDay, context: context)

            let markedOnDay = ItemCollectionOperations.items(
                from: [item],
                options: .init(filter: .markedOnDay),
                today: today,
                selectedDay: selectedDay
            )
            let markedToday = ItemCollectionOperations.items(
                from: [item],
                options: .init(filter: .markedToday),
                today: today,
                selectedDay: selectedDay
            )

            #expect(markedOnDay.map(\.uuid) == [item.uuid])
            #expect(markedToday.isEmpty)
        }

        @Test
        func `sort orders use marks names and categories with stable ties`() throws {
            let context = try makeContext()
            let coat = try makeItem(named: "Coat", context: context, category: .clothing)
            let tote = try makeItem(named: "Tote", context: context, category: .bags)
            let shoes = try makeItem(named: "Shoes", context: context, category: .shoes)
            let olderDay = try #require(LocalDay(year: 2_026, month: 7, day: 10))
            let newerDay = try #require(LocalDay(year: 2_026, month: 7, day: 12))
            try mark(coat, on: olderDay, context: context)
            try mark(coat, on: newerDay, context: context)
            try mark(tote, on: newerDay, context: context)

            let input = [shoes, tote, coat]
            let recentlyMarked = refined(input, sort: .recentlyMarked)
            let mostMarked = refined(input, sort: .mostMarked)
            let byName = refined(input, sort: .name)
            let byCategory = refined(input, sort: .category)

            #expect(recentlyMarked.map(\.uuid) == [tote.uuid, coat.uuid, shoes.uuid])
            #expect(mostMarked.map(\.uuid) == [coat.uuid, tote.uuid, shoes.uuid])
            #expect(byName.map(\.uuid) == [coat.uuid, shoes.uuid, tote.uuid])
            #expect(byCategory.map(\.uuid) == [coat.uuid, shoes.uuid, tote.uuid])
        }

        private func refined(
            _ items: [Item],
            sort: ItemCollectionSort
        ) -> [Item] {
            ItemCollectionOperations.items(
                from: items,
                options: .init(sort: sort),
                today: nil
            )
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func makeItem(
            named name: String,
            context: ModelContext,
            category: ItemCategory = .other,
            note: String = ""
        ) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: name, category: category, note: note)
            )
        }

        private func mark(
            _ item: Item,
            on day: LocalDay,
            context: ModelContext
        ) throws {
            _ = try ItemOperations.mark(
                item,
                on: day,
                today: day,
                context: context
            )
        }
    }
}

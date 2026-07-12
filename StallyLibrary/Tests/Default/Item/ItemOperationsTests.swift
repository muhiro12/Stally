//
//  ItemOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Hiromu Nakano on 2026/06/26.
//

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemOperationsTests {
        // swiftlint:disable:next nesting
        private enum Fixtures {
            static var calendar: Calendar {
                var configuredCalendar = Calendar(identifier: .gregorian)
                configuredCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? configuredCalendar.timeZone
                return configuredCalendar
            }

            static var today: Date {
                day(offset: 0)
            }

            static var todayLocalDay: LocalDay {
                localDay(offset: 0)
            }

            private static var baseDay: Date {
                let components = DateComponents(
                    calendar: calendar,
                    timeZone: calendar.timeZone,
                    year: 2_026,
                    month: 6,
                    day: 26
                )

                guard let date = components.date else {
                    preconditionFailure("Invalid fixture base day")
                }

                return date
            }

            static func day(offset: Int) -> Date {
                guard let date = calendar.date(byAdding: .day, value: offset, to: baseDay) else {
                    preconditionFailure("Invalid fixture day offset: \(offset)")
                }

                return date
            }

            static func localDay(offset: Int) -> LocalDay {
                guard let localDay = LocalDay(
                    containing: day(offset: offset),
                    in: calendar.timeZone
                ) else {
                    preconditionFailure("Invalid fixture local day offset: \(offset)")
                }

                return localDay
            }
        }

        @Test
        func `create stores normalized item input`() throws {
            let context = try makeContext()
            let photoData = Data([0x01, 0x02, 0x03])

            let item = try ItemOperations.create(
                context: context,
                input: .init(
                    name: "  Black Wool Coat  ",
                    category: .clothing,
                    note: "  The one I reach for on cold mornings.  ",
                    photoData: photoData
                ),
                createdAt: Fixtures.today
            )

            let fetchedItem = try #require(try fetchItems(context).first)
            #expect(fetchedItem.name == "Black Wool Coat")
            #expect(fetchedItem.category == .clothing)
            #expect(fetchedItem.note == "The one I reach for on cold mornings.")
            #expect(fetchedItem.photoData == photoData)
            #expect(fetchedItem.createdAt == Fixtures.today)
            #expect(!fetchedItem.isArchived)
            #expect(fetchedItem.persistentModelID == item.persistentModelID)
        }

        @Test
        func `create rejects empty item names`() throws {
            let context = try makeContext()

            #expect(throws: ItemValidationError.nameRequired) {
                try ItemOperations.create(
                    context: context,
                    input: .init(name: "   ", category: .other)
                )
            }

            #expect(try fetchItems(context).isEmpty)
        }

        @Test
        func `items fetches newest first and by stable identifier`() throws {
            let context = try makeContext()
            let olderItem = try createItem(
                context: context,
                name: "Canvas Tote",
                createdAt: Fixtures.day(offset: -2)
            )
            let newerItem = try createItem(
                context: context,
                name: "Daily Field Notes",
                category: .notebooks,
                createdAt: Fixtures.today
            )

            let fetchedItems = try ItemOperations.items(context: context)
            let fetchedItem = try ItemOperations.item(context: context, uuid: olderItem.uuid)

            #expect(fetchedItems.map(\.uuid) == [newerItem.uuid, olderItem.uuid])
            #expect(fetchedItem?.persistentModelID == olderItem.persistentModelID)
        }

        @Test
        func `items matching name supports system surface search`() throws {
            let context = try makeContext()
            let coat = try createItem(
                context: context,
                name: "Black Wool Coat",
                category: .clothing
            )
            _ = try createItem(
                context: context,
                name: "Canvas Tote",
                category: .bags
            )

            let matches = try ItemOperations.items(
                context: context,
                matchingName: " wool "
            )

            #expect(matches.map(\.uuid) == [coat.uuid])
        }

        @Test
        func `mark adds only one mark per item per day`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)

            let didMark = try ItemOperations.mark(
                item,
                on: Fixtures.todayLocalDay,
                today: Fixtures.todayLocalDay,
                context: context
            )
            let didMarkAgain = try ItemOperations.mark(
                item,
                on: Fixtures.todayLocalDay,
                today: Fixtures.todayLocalDay,
                context: context
            )

            let history = ItemOperations.historySnapshot(
                for: item,
                today: Fixtures.todayLocalDay
            )
            #expect(didMark)
            #expect(!didMarkAgain)
            #expect(history.totalMarks == 1)
            #expect(ItemOperations.isMarked(item, on: Fixtures.todayLocalDay))
        }

        @Test
        func `mark rejects a future day without changing history`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            let futureDay = Fixtures.localDay(offset: 1)

            #expect(throws: ItemValidationError.futureMarksNotAllowed) {
                try ItemOperations.mark(
                    item,
                    on: futureDay,
                    today: Fixtures.todayLocalDay,
                    context: context
                )
            }

            #expect(item.marks.isEmpty)
            #expect(!ItemOperations.isMarked(item, on: futureDay))
        }

        @Test
        func `undo removes today's mark once`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            try ItemOperations.mark(
                item,
                on: Fixtures.todayLocalDay,
                today: Fixtures.todayLocalDay,
                context: context
            )

            let didUndo = try ItemOperations.undoMark(
                item,
                on: Fixtures.todayLocalDay,
                context: context
            )
            let didUndoAgain = try ItemOperations.undoMark(
                item,
                on: Fixtures.todayLocalDay,
                context: context
            )

            let history = ItemOperations.historySnapshot(
                for: item,
                today: Fixtures.todayLocalDay
            )
            #expect(didUndo)
            #expect(!didUndoAgain)
            #expect(history.totalMarks == 0)
            #expect(!ItemOperations.isMarked(item, on: Fixtures.todayLocalDay))
        }

        @Test
        func `undo removes every duplicate mark record for the day`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            try ItemOperations.mark(
                item,
                on: Fixtures.todayLocalDay,
                today: Fixtures.todayLocalDay,
                context: context
            )
            let duplicateMark = ItemMark(
                day: Fixtures.todayLocalDay,
                createdAt: Fixtures.today,
                item: item,
                uuid: .init()
            )
            item.marks.append(duplicateMark)
            context.insert(duplicateMark)
            try context.save()

            #expect(try fetchMarks(context).count == 2)

            let didUndo = try ItemOperations.undoMark(
                item,
                on: Fixtures.todayLocalDay,
                context: context
            )

            #expect(didUndo)
            #expect(item.marks.isEmpty)
            #expect(try fetchMarks(context).isEmpty)
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func fetchItems(_ context: ModelContext) throws -> [Item] {
            try context.fetch(.init())
        }

        private func fetchMarks(_ context: ModelContext) throws -> [ItemMark] {
            try context.fetch(.init())
        }

        private func createItem(
            context: ModelContext,
            name: String = "Canvas Tote",
            category: ItemCategory = .bags,
            note: String = "Usually comes with me when I need one extra layer.",
            createdAt: Date = Fixtures.today,
            photoData: Data? = nil
        ) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(
                    name: name,
                    category: category,
                    note: note,
                    photoData: photoData
                ),
                createdAt: createdAt
            )
        }
    }
}

//
//  ItemArchiveOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemArchiveOperationsTests {
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
        }

        @Test
        func `archive separates item from active Library`() throws {
            let context = try makeContext()
            let activeItem = try createItem(
                context: context,
                name: "Canvas Tote",
                createdAt: Fixtures.day(offset: -1)
            )
            let archivedItem = try createItem(
                context: context,
                name: "Travel Weekender",
                createdAt: Fixtures.day(offset: -2)
            )

            let didArchive = try ItemOperations.archive(
                archivedItem,
                on: Fixtures.today,
                context: context
            )
            let didArchiveAgain = try ItemOperations.archive(
                archivedItem,
                on: Fixtures.today,
                context: context
            )

            let items = try fetchItems(context)
            let activeItems = ItemOperations.activeItems(from: items)
            let archivedItems = ItemOperations.archivedItems(from: items)
            #expect(didArchive)
            #expect(!didArchiveAgain)
            #expect(activeItems.map(\.uuid) == [activeItem.uuid])
            #expect(archivedItems.map(\.uuid) == [archivedItem.uuid])
            #expect(archivedItem.archivedAt == Fixtures.today)
        }

        @Test
        func `move back restores archived item to active Library`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            try ItemOperations.archive(item, on: Fixtures.today, context: context)

            let didMoveBack = try ItemOperations.moveBackToLibrary(item, context: context)
            let didMoveBackAgain = try ItemOperations.moveBackToLibrary(item, context: context)

            let items = try fetchItems(context)
            #expect(didMoveBack)
            #expect(!didMoveBackAgain)
            #expect(ItemOperations.activeItems(from: items).map(\.uuid) == [item.uuid])
            #expect(ItemOperations.archivedItems(from: items).isEmpty)
            #expect(item.archivedAt == nil)
        }

        @Test
        func `archive preserves note photo and mark history`() throws {
            let context = try makeContext()
            let photoData = Data([0x04, 0x05, 0x06])
            let item = try createItem(
                context: context,
                name: "Daily Field Notes",
                category: .notebooks,
                note: "Still waiting for its first stretch of regular use.",
                photoData: photoData
            )
            try ItemOperations.mark(
                item,
                on: Fixtures.day(offset: -3),
                context: context,
                calendar: Fixtures.calendar
            )

            try ItemOperations.archive(item, on: Fixtures.today, context: context)

            let history = ItemOperations.historySnapshot(
                for: item,
                calendar: Fixtures.calendar,
                now: Fixtures.today
            )
            #expect(item.note == "Still waiting for its first stretch of regular use.")
            #expect(item.photoData == photoData)
            #expect(history.totalMarks == 1)
            #expect(history.lastMarkedDay == Fixtures.day(offset: -3))
        }

        @Test
        func `archived items must move back before history changes`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            try ItemOperations.archive(item, on: Fixtures.today, context: context)

            #expect(throws: ItemValidationError.archivedItemsCannotChangeHistory) {
                try ItemOperations.mark(
                    item,
                    on: Fixtures.today,
                    context: context,
                    calendar: Fixtures.calendar
                )
            }

            #expect(throws: ItemValidationError.archivedItemsCannotChangeHistory) {
                try ItemOperations.undoMark(
                    item,
                    on: Fixtures.today,
                    context: context,
                    calendar: Fixtures.calendar
                )
            }
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func fetchItems(_ context: ModelContext) throws -> [Item] {
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

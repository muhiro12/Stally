//
//  ItemOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Hiromu Nakano on 2026/06/26.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

@Suite(.serialized)
struct ItemOperationsTests {
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
    func `mark adds only one mark per item per day`() throws {
        let context = try makeContext()
        let item = try createItem(context: context)

        let didMark = try ItemOperations.mark(
            item,
            on: Fixtures.today,
            context: context,
            calendar: Fixtures.calendar
        )
        let didMarkAgain = try ItemOperations.mark(
            item,
            on: Fixtures.today,
            context: context,
            calendar: Fixtures.calendar
        )

        let history = ItemOperations.historySnapshot(
            for: item,
            calendar: Fixtures.calendar,
            now: Fixtures.today
        )
        #expect(didMark)
        #expect(!didMarkAgain)
        #expect(history.totalMarks == 1)
        #expect(ItemOperations.isMarked(item, on: Fixtures.today, calendar: Fixtures.calendar))
    }

    @Test
    func `undo removes today's mark once`() throws {
        let context = try makeContext()
        let item = try createItem(context: context)
        try ItemOperations.mark(
            item,
            on: Fixtures.today,
            context: context,
            calendar: Fixtures.calendar
        )

        let didUndo = try ItemOperations.undoMark(
            item,
            on: Fixtures.today,
            context: context,
            calendar: Fixtures.calendar
        )
        let didUndoAgain = try ItemOperations.undoMark(
            item,
            on: Fixtures.today,
            context: context,
            calendar: Fixtures.calendar
        )

        let history = ItemOperations.historySnapshot(
            for: item,
            calendar: Fixtures.calendar,
            now: Fixtures.today
        )
        #expect(didUndo)
        #expect(!didUndoAgain)
        #expect(history.totalMarks == 0)
        #expect(!ItemOperations.isMarked(item, on: Fixtures.today, calendar: Fixtures.calendar))
    }

    @Test
    func `history snapshot counts calendar windows`() throws {
        let context = try makeContext()
        let item = try createItem(context: context)
        let offsets = [0, -1, -29, -30, -89, -90]

        for offset in offsets {
            try ItemOperations.mark(
                item,
                on: Fixtures.day(offset: offset),
                context: context,
                calendar: Fixtures.calendar
            )
        }

        let history = ItemOperations.historySnapshot(
            for: item,
            calendar: Fixtures.calendar,
            now: Fixtures.today
        )
        #expect(history.totalMarks == 6)
        #expect(history.marksInLast30Days == 3)
        #expect(history.marksInLast90Days == 5)
        #expect(history.monthsUsed == 3)
        #expect(history.daysSinceLastMark == 0)
        #expect(history.lastMarkedDay == Fixtures.today)
        #expect(history.markedDays.first == Fixtures.today)
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

//
//  ItemMutationOperationsTests.swift
//  StallyLibrary
//
//  Created by Hiromu Tsuruta on 2026/07/12.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

private enum ItemMutationFixtures {
    private static let baseYear = 2_026
    private static let baseMonth = 6
    private static let baseDayOfMonth = 26

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
            year: baseYear,
            month: baseMonth,
            day: baseDayOfMonth
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

extension SwiftDataOperationsTests {
    @Suite
    struct ItemMutationOperationsTests {
        @Test
        func `update normalizes editable context and preserves identity and history`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            try ItemOperations.mark(
                item,
                on: ItemMutationFixtures.localDay(offset: -1),
                today: ItemMutationFixtures.todayLocalDay,
                context: context
            )
            try ItemOperations.archive(
                item,
                on: ItemMutationFixtures.today,
                context: context
            )
            let originalID = item.uuid
            let originalCreatedAt = item.createdAt
            let originalArchivedAt = item.archivedAt
            let originalMarkIDs = item.marks.map(\.uuid)
            let replacementPhoto = Data([0x09, 0x08])

            try ItemOperations.update(
                item,
                input: .init(
                    name: "  Daily Field Notes  ",
                    category: .notebooks,
                    note: "  Ready for the next trip.  ",
                    photoData: replacementPhoto
                ),
                context: context
            )

            #expect(item.name == "Daily Field Notes")
            #expect(item.category == .notebooks)
            #expect(item.note == "Ready for the next trip.")
            #expect(item.photoData == replacementPhoto)
            #expect(item.uuid == originalID)
            #expect(item.createdAt == originalCreatedAt)
            #expect(item.archivedAt == originalArchivedAt)
            #expect(item.marks.map(\.uuid) == originalMarkIDs)
        }

        @Test
        func `update rejects an empty name without changing the item`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)

            #expect(throws: ItemValidationError.nameRequired) {
                try ItemOperations.update(
                    item,
                    input: .init(
                        name: "   ",
                        category: .clothing,
                        note: "Changed",
                        photoData: Data([0x01])
                    ),
                    context: context
                )
            }

            #expect(item.name == "Canvas Tote")
            #expect(item.category == .bags)
            #expect(item.note == "Usually comes with me when I need one extra layer.")
            #expect(item.photoData == nil)
        }

        @Test
        func `delete removes an archived item and all of its marks`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            let survivor = try createItem(context: context, name: "Black Wool Coat")
            try ItemOperations.mark(
                item,
                on: ItemMutationFixtures.localDay(offset: -2),
                today: ItemMutationFixtures.todayLocalDay,
                context: context
            )
            try ItemOperations.mark(
                item,
                on: ItemMutationFixtures.localDay(offset: -1),
                today: ItemMutationFixtures.todayLocalDay,
                context: context
            )
            try ItemOperations.archive(
                item,
                on: ItemMutationFixtures.today,
                context: context
            )

            try ItemOperations.delete(item, context: context)

            #expect(try fetchItems(context).map(\.uuid) == [survivor.uuid])
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
            name: String = "Canvas Tote"
        ) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(
                    name: name,
                    category: .bags,
                    note: "Usually comes with me when I need one extra layer."
                ),
                createdAt: ItemMutationFixtures.day(offset: -10)
            )
        }
    }
}

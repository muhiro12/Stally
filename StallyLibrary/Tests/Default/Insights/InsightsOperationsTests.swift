//
//  InsightsOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

@Suite(.serialized)
struct InsightsOperationsTests {
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
    func `snapshot calculates range activity and category share`() throws {
        let context = try makeContext()
        let coat = try createItem(context: context, name: "Black Wool Coat", category: .clothing)
        let sneakers = try createItem(context: context, name: "White Everyday Sneakers", category: .shoes)
        let tote = try createItem(context: context, name: "Canvas Tote", category: .bags)
        try mark(coat, offsets: [0, -1, -29], context: context)
        try mark(sneakers, offsets: [-1], context: context)
        try mark(tote, offsets: [-40], context: context)

        let snapshot = try insightsSnapshot(context)

        #expect(snapshot.totalMarks == 4)
        #expect(snapshot.activeDays == 3)
        #expect(snapshot.uniqueMarkedItems == 2)
        #expect(snapshot.uniqueMarkedCategories == 2)
        #expect(snapshot.topItems.map(\.item.uuid) == [coat.uuid, sneakers.uuid])
        #expect(snapshot.categoryShares.map(\.category) == [.clothing, .shoes])
        #expect(snapshot.categoryShares.map(\.markCount) == [3, 1])
    }

    @Test
    func `snapshot respects archived item scope`() throws {
        let context = try makeContext()
        let activeItem = try createItem(context: context, name: "Daily Field Notes")
        let archivedItem = try createItem(context: context, name: "Travel Weekender")
        try mark(activeItem, offsets: [0], context: context)
        try mark(archivedItem, offsets: [-40], context: context)
        try ItemOperations.archive(archivedItem, on: Fixtures.day(offset: -2), context: context)

        let activeOnlySnapshot = try insightsSnapshot(
            context,
            options: .init(range: .allTime)
        )
        let allItemsSnapshot = try insightsSnapshot(
            context,
            options: .init(range: .allTime, includesArchivedItems: true)
        )

        #expect(activeOnlySnapshot.totalMarks == 1)
        #expect(allItemsSnapshot.totalMarks == 2)
        #expect(allItemsSnapshot.topItems.map(\.item.uuid).contains(archivedItem.uuid))
    }

    @Test
    func `snapshot calculates quiet items and context coverage`() throws {
        let context = try makeContext()
        let quietItem = try createItem(
            context: context,
            name: "Travel Weekender",
            category: .bags
        )
        _ = try createItem(
            context: context,
            name: "Daily Field Notes",
            category: .notebooks,
            note: "Usually comes with me when I need one extra layer.",
            photoData: Data([0x01])
        )
        try mark(quietItem, offsets: [-40], context: context)

        let snapshot = try insightsSnapshot(context)

        #expect(snapshot.quietItems.map(\.item.uuid) == [quietItem.uuid])
        #expect(snapshot.noteCoverage == .init(coveredCount: 1, totalCount: 2))
        #expect(snapshot.photoCoverage == .init(coveredCount: 1, totalCount: 2))
    }

    @Test
    func `snapshot calculates current and best streaks`() throws {
        let context = try makeContext()
        let item = try createItem(context: context, name: "Canvas Tote")
        try mark(item, offsets: [0, -1, -2, -4, -5], context: context)

        let snapshot = try insightsSnapshot(context)

        #expect(snapshot.currentStreak == 3)
        #expect(snapshot.bestStreak == 3)
    }

    @Test
    func `snapshot recommends quiet next moves`() throws {
        let context = try makeContext()
        let item = try createItem(context: context, name: "Canvas Tote")

        let emptyRangeSnapshot = try insightsSnapshot(context)
        try mark(item, offsets: [0], context: context)
        let activeRangeSnapshot = try insightsSnapshot(context)

        #expect(emptyRangeSnapshot.recommendations.map(\.kind) == [.startThisRangeWithOneMark])
        #expect(
            activeRangeSnapshot.recommendations.map(\.kind) == [
                .addContextToFrequentItems,
                .protectCurrentStreak
            ]
        )
    }

    private func insightsSnapshot(
        _ context: ModelContext,
        options: InsightsOptions = .default
    ) throws -> InsightsSnapshot {
        InsightsOperations.snapshot(
            for: try fetchItems(context),
            options: options,
            calendar: Fixtures.calendar,
            now: Fixtures.today
        )
    }

    private func makeContext() throws -> ModelContext {
        .init(try StallyModelContainerFactory.inMemory())
    }

    private func fetchItems(_ context: ModelContext) throws -> [Item] {
        try context.fetch(.init())
    }

    private func createItem(
        context: ModelContext,
        name: String,
        category: ItemCategory = .other,
        note: String = "",
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
            createdAt: Fixtures.today
        )
    }

    private func mark(
        _ item: Item,
        offsets: [Int],
        context: ModelContext
    ) throws {
        for offset in offsets {
            try ItemOperations.mark(
                item,
                on: Fixtures.day(offset: offset),
                context: context,
                calendar: Fixtures.calendar
            )
        }
    }
}

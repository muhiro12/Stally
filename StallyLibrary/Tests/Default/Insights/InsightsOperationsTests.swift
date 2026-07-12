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

extension SwiftDataOperationsTests {
    @Suite
    struct InsightsOperationsTests {
        // swiftlint:disable:next nesting
        private enum Fixtures {
            static var utc: TimeZone {
                guard let timeZone = TimeZone(secondsFromGMT: 0) else {
                    preconditionFailure("UTC must be available")
                }

                return timeZone
            }

            static var today: LocalDay {
                day(offset: 0)
            }

            static var now: Date {
                date(offset: 0, timeZone: utc)
            }

            private static var baseDay: LocalDay {
                guard let day = LocalDay(year: 2_026, month: 6, day: 26) else {
                    preconditionFailure("Invalid fixture base day")
                }

                return day
            }

            static func day(offset: Int) -> LocalDay {
                guard let day = baseDay.adding(days: offset) else {
                    preconditionFailure("Invalid fixture day offset: \(offset)")
                }

                return day
            }

            static func date(offset: Int, timeZone: TimeZone) -> Date {
                guard let date = day(offset: offset).date(in: timeZone) else {
                    preconditionFailure("Invalid fixture date offset: \(offset)")
                }

                return date
            }

            static func timeZone(identifier: String) -> TimeZone {
                guard let timeZone = TimeZone(identifier: identifier) else {
                    preconditionFailure("Missing fixture timezone: \(identifier)")
                }

                return timeZone
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
            #expect(snapshot.topItems.first?.lastMarkedDay == Fixtures.today)
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
            try ItemOperations.archive(
                archivedItem,
                on: Fixtures.date(offset: -2, timeZone: Fixtures.utc),
                context: context
            )

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
                photoData: try TestPhotoFixtures.preparedData()
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

        @Test
        func `snapshot preserves a Tokyo marked day when read in Los Angeles`() throws {
            let context = try makeContext()
            let item = try createItem(context: context, name: "Travel Weekender")
            let tokyo = Fixtures.timeZone(identifier: "Asia/Tokyo")
            let losAngeles = Fixtures.timeZone(identifier: "America/Los_Angeles")
            let tokyoInstant = Fixtures.date(offset: 0, timeZone: tokyo)
            let markedDay = try #require(LocalDay(containing: tokyoInstant, in: tokyo))
            let losAngelesDayAtSameInstant = try #require(
                LocalDay(containing: tokyoInstant, in: losAngeles)
            )

            try ItemOperations.mark(
                item,
                on: markedDay,
                today: Fixtures.today,
                context: context
            )

            let snapshot = InsightsOperations.snapshot(
                for: try fetchItems(context),
                options: .init(range: .allTime),
                timeZone: losAngeles,
                now: tokyoInstant
            )

            #expect(markedDay == Fixtures.today)
            #expect(losAngelesDayAtSameInstant == Fixtures.day(offset: -1))
            #expect(snapshot.totalMarks == 1)
            #expect(snapshot.topItems.first?.lastMarkedDay == markedDay)
        }

        @Test
        func `snapshot calculates streak across daylight saving boundary`() throws {
            let context = try makeContext()
            let item = try createItem(context: context, name: "Canvas Tote")
            let losAngeles = Fixtures.timeZone(identifier: "America/Los_Angeles")
            let today = try #require(LocalDay(year: 2_026, month: 3, day: 9))
            let firstDay = try #require(today.adding(days: -2))
            let secondDay = try #require(today.adding(days: -1))
            let now = try #require(today.date(in: losAngeles))

            for day in [firstDay, secondDay, today] {
                try ItemOperations.mark(
                    item,
                    on: day,
                    today: today,
                    context: context
                )
            }

            let snapshot = InsightsOperations.snapshot(
                for: try fetchItems(context),
                options: .init(range: .allTime),
                timeZone: losAngeles,
                now: now
            )

            #expect(snapshot.currentStreak == 3)
            #expect(snapshot.bestStreak == 3)
        }

        @Test
        func `snapshot fails safely when now is outside LocalDay range`() throws {
            let context = try makeContext()
            _ = try createItem(context: context, name: "Canvas Tote")

            let snapshot = InsightsOperations.snapshot(
                for: try fetchItems(context),
                timeZone: Fixtures.utc,
                now: .init(timeIntervalSince1970: 253_402_300_800)
            )

            #expect(snapshot.totalMarks == 0)
            #expect(snapshot.topItems.isEmpty)
            #expect(snapshot.recommendations.isEmpty)
        }

        private func insightsSnapshot(
            _ context: ModelContext,
            options: InsightsOptions = .default
        ) throws -> InsightsSnapshot {
            InsightsOperations.snapshot(
                for: try fetchItems(context),
                options: options,
                timeZone: Fixtures.utc,
                now: Fixtures.now
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
                createdAt: Fixtures.now
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
                    today: Fixtures.today,
                    context: context
                )
            }
        }
    }
}

//
//  ReviewOperationsTests.swift
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
    struct ReviewOperationsTests {
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
                date(offset: 0)
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

            static func date(offset: Int) -> Date {
                guard let date = day(offset: offset).date(in: utc) else {
                    preconditionFailure("Invalid fixture date offset: \(offset)")
                }

                return date
            }
        }

        @Test
        func `snapshot includes old unmarked active items in Needs First Mark`() throws {
            let context = try makeContext()
            let waitingItem = try createItem(
                context: context,
                name: "Daily Field Notes",
                createdAt: Fixtures.date(offset: -14)
            )
            _ = try createItem(
                context: context,
                name: "White Everyday Sneakers",
                createdAt: Fixtures.date(offset: -13)
            )

            let snapshot = try reviewSnapshot(context)

            #expect(snapshot.needsFirstMark.map(\.uuid) == [waitingItem.uuid])
            #expect(snapshot.dormant.isEmpty)
            #expect(snapshot.recoveryCandidates.isEmpty)
        }

        @Test
        func `snapshot includes quiet previously marked active items in Dormant`() throws {
            let context = try makeContext()
            let dormantItem = try createItem(context: context, name: "Black Wool Coat")
            let recentItem = try createItem(context: context, name: "Canvas Tote")
            try ItemOperations.mark(
                dormantItem,
                on: Fixtures.day(offset: -30),
                today: Fixtures.today,
                context: context
            )
            try ItemOperations.mark(
                recentItem,
                on: Fixtures.day(offset: -29),
                today: Fixtures.today,
                context: context
            )

            let snapshot = try reviewSnapshot(context)

            #expect(snapshot.needsFirstMark.isEmpty)
            #expect(snapshot.dormant.map(\.uuid) == [dormantItem.uuid])
            #expect(snapshot.recoveryCandidates.isEmpty)
        }

        @Test
        func `snapshot includes archived historical items in Recovery Candidates`() throws {
            let context = try makeContext()
            let recoveryItem = try createItem(context: context, name: "Travel Weekender")
            let emptyArchivedItem = try createItem(context: context, name: "Notebook Sleeve")
            try ItemOperations.mark(
                recoveryItem,
                on: Fixtures.day(offset: -40),
                today: Fixtures.today,
                context: context
            )
            try ItemOperations.archive(recoveryItem, on: Fixtures.date(offset: -2), context: context)
            try ItemOperations.archive(emptyArchivedItem, on: Fixtures.date(offset: -1), context: context)

            let snapshot = try reviewSnapshot(context)

            #expect(snapshot.needsFirstMark.isEmpty)
            #expect(snapshot.dormant.isEmpty)
            #expect(snapshot.recoveryCandidates.map(\.uuid) == [recoveryItem.uuid])
        }

        @Test
        func `custom settings change lane thresholds`() throws {
            let context = try makeContext()
            let waitingItem = try createItem(
                context: context,
                name: "Canvas Tote",
                createdAt: Fixtures.date(offset: -3)
            )

            let defaultSnapshot = try reviewSnapshot(context)
            let customSnapshot = try reviewSnapshot(
                context,
                settings: .init(needsFirstMarkAfterDays: 3)
            )

            #expect(defaultSnapshot.isEmpty)
            #expect(customSnapshot.needsFirstMark.map(\.uuid) == [waitingItem.uuid])
        }

        @Test
        func `snapshot clamps a future creation day to zero days old`() throws {
            let context = try makeContext()
            let futureItem = try createItem(
                context: context,
                name: "Travel Weekender",
                createdAt: Fixtures.date(offset: 1)
            )

            let snapshot = try reviewSnapshot(
                context,
                settings: .init(needsFirstMarkAfterDays: 0)
            )

            #expect(snapshot.needsFirstMark.map(\.uuid) == [futureItem.uuid])
        }

        @Test
        func `snapshot fails safely when now is outside LocalDay range`() throws {
            let context = try makeContext()
            _ = try createItem(context: context, name: "Canvas Tote")

            let snapshot = ReviewOperations.snapshot(
                for: try fetchItems(context),
                timeZone: Fixtures.utc,
                now: .init(timeIntervalSince1970: 253_402_300_800)
            )

            #expect(snapshot.isEmpty)
        }

        private func reviewSnapshot(
            _ context: ModelContext,
            settings: ReviewSettings = .default
        ) throws -> ReviewSnapshot {
            ReviewOperations.snapshot(
                for: try fetchItems(context),
                settings: settings,
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
            createdAt: Date = Fixtures.now
        ) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: name, category: category),
                createdAt: createdAt
            )
        }
    }
}

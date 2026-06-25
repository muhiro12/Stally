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

@Suite(.serialized)
struct ReviewOperationsTests {
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
    func `snapshot includes old unmarked active items in Needs First Mark`() throws {
        let context = try makeContext()
        let waitingItem = try createItem(
            context: context,
            name: "Daily Field Notes",
            createdAt: Fixtures.day(offset: -14)
        )
        _ = try createItem(
            context: context,
            name: "White Everyday Sneakers",
            createdAt: Fixtures.day(offset: -13)
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
            context: context,
            calendar: Fixtures.calendar
        )
        try ItemOperations.mark(
            recentItem,
            on: Fixtures.day(offset: -29),
            context: context,
            calendar: Fixtures.calendar
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
            context: context,
            calendar: Fixtures.calendar
        )
        try ItemOperations.archive(recoveryItem, on: Fixtures.day(offset: -2), context: context)
        try ItemOperations.archive(emptyArchivedItem, on: Fixtures.day(offset: -1), context: context)

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
            createdAt: Fixtures.day(offset: -3)
        )

        let defaultSnapshot = try reviewSnapshot(context)
        let customSnapshot = try reviewSnapshot(
            context,
            settings: .init(needsFirstMarkAfterDays: 3)
        )

        #expect(defaultSnapshot.isEmpty)
        #expect(customSnapshot.needsFirstMark.map(\.uuid) == [waitingItem.uuid])
    }

    private func reviewSnapshot(
        _ context: ModelContext,
        settings: ReviewSettings = .default
    ) throws -> ReviewSnapshot {
        ReviewOperations.snapshot(
            for: try fetchItems(context),
            settings: settings,
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
        createdAt: Date = Fixtures.today
    ) throws -> Item {
        try ItemOperations.create(
            context: context,
            input: .init(name: name, category: category),
            createdAt: createdAt
        )
    }
}

//
//  ItemHistoryOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Hiromu Tsuruta on 2026/07/12.
//

@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemHistoryOperationsTests {
        @Test
        func `history snapshot counts calendar windows`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 6, day: 26))
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Canvas Tote", category: .bags)
            )
            let offsets = [0, -1, -29, -30, -89, -90]

            for offset in offsets {
                let markedDay = try #require(today.adding(days: offset))
                try ItemOperations.mark(
                    item,
                    on: markedDay,
                    today: today,
                    context: context
                )
            }

            let history = ItemOperations.historySnapshot(
                for: item,
                today: today
            )
            #expect(history.totalMarks == 6)
            #expect(history.marksInLast30Days == 3)
            #expect(history.marksInLast90Days == 5)
            #expect(history.monthsUsed == 3)
            #expect(history.daysSinceLastMark == 0)
            #expect(history.lastMarkedDay == today)
            #expect(history.markedDays.first == today)
        }

        @Test
        func `history keeps a stored mark when the current timezone is one day behind`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 6, day: 25))
            let storedDay = try #require(today.adding(days: 1))
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Travel Weekender", category: .bags)
            )
            try ItemOperations.mark(
                item,
                on: storedDay,
                today: storedDay,
                context: context
            )

            let history = ItemOperations.historySnapshot(for: item, today: today)

            #expect(history.totalMarks == 1)
            #expect(history.marksInLast30Days == 1)
            #expect(history.marksInLast90Days == 1)
            #expect(history.daysSinceLastMark == 0)
        }
    }
}

//
//  ItemOperationsRollbackTests.swift
//  StallyLibrary
//
//  Created by Hiromu Tsuruta on 2026/07/12.
//

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

private enum ExpectedSaveError: Error {
    case rejected
}

extension SwiftDataOperationsTests {
    @Suite
    struct ItemOperationsRollbackTests {
        private var testCalendar: Calendar {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
            return calendar
        }

        private var testDate: Date {
            Date(timeIntervalSince1970: 1_750_000_000)
        }

        @Test
        func `rollback removes a pending item insertion`() throws {
            let context = try makeContext()
            let item = Item(
                name: "Canvas Tote",
                category: .bags,
                note: "",
                createdAt: testDate,
                uuid: .init(),
                photoData: nil,
                archivedAt: nil
            )
            context.insert(item)

            rejectSave(in: context)

            let verificationContext = ModelContext(context.container)
            #expect(try fetchItems(verificationContext).isEmpty)
        }

        @Test
        func `rollback removes a pending mark relationship`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            let mark = ItemMark(day: testDate, item: item)
            item.marks.append(mark)
            context.insert(mark)

            rejectSave(in: context)

            let verificationContext = ModelContext(context.container)
            #expect(try fetchMarks(verificationContext).isEmpty)
        }

        @Test
        func `rollback restores a deleted mark relationship`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            try ItemOperations.mark(
                item,
                on: testDate,
                context: context,
                calendar: testCalendar
            )
            let marks = item.removeMarks(on: testDate, calendar: testCalendar)

            for mark in marks {
                context.delete(mark)
            }

            rejectSave(in: context)

            let verificationContext = ModelContext(context.container)
            #expect(try fetchMarks(verificationContext).count == 1)
        }

        @Test
        func `rollback restores a pending scalar change`() throws {
            let context = try makeContext()
            let item = try createItem(context: context)
            item.archivedAt = testDate

            rejectSave(in: context)

            let verificationContext = ModelContext(context.container)
            let restoredItem = try #require(
                try ItemOperations.item(context: verificationContext, uuid: item.uuid)
            )
            #expect(restoredItem.archivedAt == nil)
        }

        private func rejectSave(in context: ModelContext) {
            #expect(throws: ExpectedSaveError.self) {
                try ItemOperations.saveOrRollback(context) { _ in
                    throw ExpectedSaveError.rejected
                }
            }
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

        private func createItem(context: ModelContext) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: "Canvas Tote", category: .bags),
                createdAt: testDate
            )
        }
    }
}

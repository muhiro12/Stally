//
//  StallyPersistenceTests.swift
//  StallyLibrary
//
//  Created by Hiromu Tsuruta on 2026/07/12.
//

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct StallyPersistenceTests {
        @Test
        func `versioned schema reopens timezone independent mark days from disk`() throws {
            let fileManager = FileManager.default
            let directoryURL = fileManager.temporaryDirectory.appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
            let storeURL = directoryURL.appendingPathComponent("Stally.store")
            let markedDay = try #require(LocalDay(year: 2_026, month: 6, day: 26))

            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            defer {
                try? fileManager.removeItem(at: directoryURL)
            }

            let itemID = try writeItem(to: storeURL)
            try writeMark(for: itemID, on: markedDay, to: storeURL)

            let reopenedContext = try makeContextAndStore(at: storeURL)
            let reopenedItem = try #require(
                try ItemOperations.item(context: reopenedContext, uuid: itemID)
            )
            let reopenedMark = try #require(reopenedItem.marks.first)

            #expect(reopenedMark.day == markedDay)
            #expect(reopenedMark.dayKey == markedDay.dayKey)
        }

        private func writeItem(to storeURL: URL) throws -> UUID {
            let context = try makeContextAndStore(at: storeURL)
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Canvas Tote", category: .bags)
            )

            return item.uuid
        }

        private func writeMark(
            for itemID: UUID,
            on markedDay: LocalDay,
            to storeURL: URL
        ) throws {
            let context = try makeContextAndStore(at: storeURL)
            let item = try #require(
                try ItemOperations.item(context: context, uuid: itemID)
            )
            try ItemOperations.mark(
                item,
                on: markedDay,
                today: markedDay,
                context: context
            )
        }

        private func makeContextAndStore(at storeURL: URL) throws -> ModelContext {
            let schema = StallyModelContainerFactory.schema
            let configuration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: StallyMigrationPlan.self,
                configurations: [configuration]
            )

            return .init(container)
        }
    }
}

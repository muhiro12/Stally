//
//  BackupOperationsImportIntegrityTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct BackupOperationsImportIntegrityTests {
        // swiftlint:disable:next nesting
        private enum Fixtures {
            static var calendar: Calendar {
                var configuredCalendar = Calendar(identifier: .gregorian)
                configuredCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? configuredCalendar.timeZone
                return configuredCalendar
            }

            static var today: Date {
                let components = DateComponents(
                    calendar: calendar,
                    timeZone: calendar.timeZone,
                    year: 2_026,
                    month: 6,
                    day: 26
                )

                guard let date = components.date else {
                    preconditionFailure("Invalid fixture day")
                }

                return date
            }
        }

        @Test
        func `duplicate calendar days fail closed for preview merge and replace`() throws {
            let context = try makeContext()
            _ = try createItem(context: context, name: "Local Item")
            let backupItemID = UUID()
            let firstMark = BackupMark(
                id: UUID(),
                day: Fixtures.today,
                createdAt: Fixtures.today
            )
            let secondMark = BackupMark(
                id: UUID(),
                day: try #require(
                    Fixtures.calendar.date(byAdding: .hour, value: 12, to: Fixtures.today)
                ),
                createdAt: Fixtures.today
            )
            let snapshot = BackupSnapshot(
                exportedAt: Fixtures.today,
                items: [
                    backupItem(
                        id: backupItemID,
                        marks: [firstMark, secondMark]
                    )
                ]
            )
            let expectedPreview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: try fetchItems(context),
                calendar: Fixtures.calendar
            )

            #expect(!expectedPreview.canImport)
            #expect(expectedPreview.marksAddedCount == 0)
            #expect(expectedPreview.validationIssues.map(\.kind) == [.duplicateMarkDay])
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.mergeIntoLibrary(
                    snapshot: snapshot,
                    context: context,
                    calendar: Fixtures.calendar
                )
            }
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(
                    snapshot: snapshot,
                    context: context,
                    calendar: Fixtures.calendar
                )
            }

            let items = try fetchItems(context)
            #expect(items.map(\.name) == ["Local Item"])
            #expect(!items.map(\.uuid).contains(backupItemID))
        }

        @Test
        func `duplicate current item identifiers fail closed without trapping`() throws {
            let context = try makeContext()
            let firstItem = try createItem(context: context, name: "First Local Item")
            let secondItem = try createItem(context: context, name: "Second Local Item")
            secondItem.uuid = firstItem.uuid
            try context.save()
            let backupItemID = UUID()
            let snapshot = BackupSnapshot(
                exportedAt: Fixtures.today,
                items: [backupItem(id: backupItemID, marks: [])]
            )
            let expectedPreview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: try fetchItems(context),
                calendar: Fixtures.calendar
            )

            #expect(!expectedPreview.canImport)
            #expect(expectedPreview.marksAddedCount == 0)
            #expect(expectedPreview.validationIssues.map(\.kind) == [.duplicateCurrentItemID])
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.mergeIntoLibrary(
                    snapshot: snapshot,
                    context: context,
                    calendar: Fixtures.calendar
                )
            }
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(
                    snapshot: snapshot,
                    context: context,
                    calendar: Fixtures.calendar
                )
            }

            let items = try fetchItems(context)
            #expect(items.count == 2)
            #expect(!items.map(\.uuid).contains(backupItemID))
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func fetchItems(_ context: ModelContext) throws -> [Item] {
            try context.fetch(.init())
        }

        private func createItem(context: ModelContext, name: String) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: name, category: .other),
                createdAt: Fixtures.today
            )
        }

        private func backupItem(id: UUID, marks: [BackupMark]) -> BackupItem {
            .init(
                id: id,
                name: "Canvas Tote",
                categoryRawValue: ItemCategory.bags.rawValue,
                note: "",
                photoData: nil,
                createdAt: Fixtures.today,
                archivedAt: nil,
                marks: marks
            )
        }
    }
}

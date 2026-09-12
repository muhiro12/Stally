//
//  BackupOperationsExportSafetyTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/09/13.
//

import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct BackupOperationsExportSafetyTests {
        @Test
        func `export rejects duplicate item identifiers without changing the library`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let firstItem = makeItem()
            let secondItem = makeItem()
            secondItem.uuid = firstItem.uuid
            context.insert(firstItem)
            context.insert(secondItem)
            try context.save()

            try expectExportFailure(
                for: [firstItem, secondItem],
                issue: .init(kind: .duplicateItemID, value: firstItem.uuid.uuidString)
            )

            #expect(try context.fetchCount(FetchDescriptor<Item>()) == 2)
            #expect(firstItem.uuid == secondItem.uuid)
            #expect(!context.hasChanges)
        }

        @Test
        func `export rejects duplicate marked days without deleting either record`() throws {
            let item = makeItem()
            let day = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            item.marks = [
                .init(day: day, createdAt: .now, item: item, uuid: .init()),
                .init(day: day, createdAt: .now, item: item, uuid: .init())
            ]

            try expectExportFailure(
                for: [item],
                issue: .init(
                    kind: .duplicateMarkDay,
                    value: "\(item.uuid.uuidString):\(day.iso8601Date)"
                )
            )

            #expect(item.marks.count == 2)
        }

        @Test
        func `export preserves unknown category evidence and refuses silent conversion`() throws {
            let item = makeItem()
            item.categoryRawValue = "Unrecognized Category"

            #expect(BackupOperations.snapshot(for: [item]).items.first?.categoryRawValue == item.categoryRawValue)
            try expectExportFailure(
                for: [item],
                issue: .init(kind: .unknownCategory, value: item.categoryRawValue)
            )

            #expect(item.categoryRawValue == "Unrecognized Category")
        }

        @Test
        func `export rejects duplicate mark identifiers across items`() throws {
            let items = [makeItem(), makeItem()]
            let day = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            let markID = UUID()

            for item in items {
                item.marks = [.init(day: day, createdAt: .now, item: item, uuid: markID)]
            }

            try expectExportFailure(
                for: items,
                issue: .init(kind: .duplicateMarkID, value: markID.uuidString)
            )
            #expect(items.allSatisfy { item in
                item.marks.first?.uuid == markID
            })
        }

        @Test
        func `export rejects unreadable photos without removing them`() throws {
            let item = makeItem()
            let photoData = Data("not an image".utf8)
            item.photoData = photoData

            try expectExportFailure(
                for: [item],
                issue: .init(kind: .invalidItemPhoto, value: item.uuid.uuidString)
            )
            #expect(item.photoData == photoData)
        }

        @Test
        func `export rejects aggregate photo storage before encoding`() throws {
            let photoData = Data(repeating: 0, count: ItemPhotoOperations.maximumDataByteCount)
            let itemCount = BackupOperations.maximumImportPhotoDataByteCount / photoData.count + 1
            let items = (0..<itemCount).map { _ in
                let item = makeItem()
                item.photoData = photoData
                return item
            }

            try expectExportFailure(
                for: items,
                issue: .init(kind: .photoStorageLimitExceeded, value: "\(itemCount * photoData.count)")
            )
            #expect(items.allSatisfy { item in
                item.photoData == photoData
            })
        }

        @Test
        func `export rejects encoded files larger than the import limit`() throws {
            let item = makeItem()
            let noteByteCount = BackupOperations.maximumImportDataByteCount + 1
            item.note = String(repeating: "a", count: noteByteCount)

            do {
                _ = try BackupOperations.exportData(for: [item])
                Issue.record("An oversized export cannot be restored.")
            } catch BackupError.validationFailed(let preview) {
                let issue = try #require(preview.validationIssues.first)
                let byteCount = try #require(issue.value.flatMap(Int.init))
                #expect(issue.kind == .backupFileTooLarge)
                #expect(byteCount > BackupOperations.maximumImportDataByteCount)
            }
            #expect(item.note.utf8.count == noteByteCount)
        }

        @Test
        func `exported collection restores identifiers photos archive and marked days`() throws {
            let item = makeItem()
            let day = try #require(LocalDay(year: 2_026, month: 9, day: 12))
            item.photoData = try TestPhotoFixtures.preparedData()
            item.archivedAt = .init(timeIntervalSinceReferenceDate: 100)
            item.marks = [.init(day: day, createdAt: .now, item: item, uuid: .init())]
            let exportedAt = Date(timeIntervalSinceReferenceDate: 200)
            let expectedSnapshot = BackupOperations.snapshot(for: [item], exportedAt: exportedAt)
            let data = try BackupOperations.exportData(for: [item], exportedAt: exportedAt)
            let context = ModelContext(try StallyModelContainerFactory.inMemory())

            let result = try BackupOperations.replaceLibrary(data: data, context: context)
            let restoredItems = try context.fetch(FetchDescriptor<Item>())

            #expect(result.insertedItemCount == 1)
            #expect(result.insertedMarkCount == 1)
            #expect(BackupOperations.snapshot(for: restoredItems, exportedAt: exportedAt) == expectedSnapshot)
        }

        @Test
        func `empty library export remains restorable`() throws {
            let data = try BackupOperations.exportData(for: [])
            let preview = BackupOperations.preview(data: data, currentItems: [])

            #expect(preview.canImport)
            #expect(preview.itemCount == 0)
        }

        private func makeItem() -> Item {
            .init(
                name: "Canvas Tote",
                category: .bags,
                note: "A familiar everyday bag.",
                createdAt: .init(timeIntervalSinceReferenceDate: 0),
                uuid: .init(),
                photoData: nil,
                archivedAt: nil
            )
        }

        private func expectExportFailure(
            for items: [Item],
            issue: BackupValidationIssue
        ) throws {
            do {
                _ = try BackupOperations.exportData(for: items)
                Issue.record("Export must reject a backup that cannot be restored.")
            } catch BackupError.validationFailed(let preview) {
                #expect(!preview.canImport)
                #expect(preview.validationIssues == [issue])
            }
        }
    }
}

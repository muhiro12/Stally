//
//  BackupOperationsPhotoImportSafetyTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import StallyLibrary
import SwiftData
import Testing

private struct BackupPhotoLocalState {
    let itemID: UUID
    let photoData: Data
    let markIDs: Set<UUID>
}

extension SwiftDataOperationsTests {
    @Suite
    struct BackupOperationsPhotoImportSafetyTests {
        // swiftlint:disable:next nesting
        private enum Fixtures {
            static let imageWidth = 80
            static let imageHeight = 60
            static let translucentAlpha = 0.5

            static var today: LocalDay {
                day(dayOfMonth: 26)
            }

            static var previousDay: LocalDay {
                day(dayOfMonth: 25)
            }

            static func timestamp(offset: Int = 0) -> Date {
                .init(timeIntervalSinceReferenceDate: TimeInterval(offset))
            }

            private static func day(dayOfMonth: Int) -> LocalDay {
                guard let day = LocalDay(year: 2_026, month: 6, day: dayOfMonth) else {
                    preconditionFailure("Invalid fixture day")
                }

                return day
            }
        }

        @Test
        func `invalid backup photo leaves merge and replace state unchanged`() throws {
            let context = try makeContext()
            let localState = try makeLocalState(context: context)
            let snapshot = invalidPhotoSnapshot(itemID: localState.itemID)
            let expectedPreview = BackupOperations.preview(
                snapshot: snapshot,
                currentItems: try fetchItems(context)
            )

            #expect(
                expectedPreview.validationIssues == [
                    .init(
                        kind: .invalidItemPhoto,
                        value: localState.itemID.uuidString
                    )
                ]
            )
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.mergeIntoLibrary(snapshot: snapshot, context: context)
            }
            try expectLocalState(localState, context: context)

            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(snapshot: snapshot, context: context)
            }
            try expectLocalState(localState, context: context)
        }

        @Test
        func `merge preserves local photo when backup contains a different valid photo`() throws {
            let context = try makeContext()
            let localPhotoData = try TestPhotoFixtures.preparedData()
            let backupPhotoData = try ItemPhotoOperations.prepare(
                TestPhotoFixtures.pngData(
                    width: Fixtures.imageWidth,
                    height: Fixtures.imageHeight,
                    alpha: Fixtures.translucentAlpha
                )
            )
            let localItem = try createItem(context: context, photoData: localPhotoData)
            let snapshot = BackupSnapshot(
                exportedAt: Fixtures.timestamp(),
                items: [
                    backupItem(
                        id: localItem.uuid,
                        photoData: backupPhotoData,
                        marks: [backupMark()]
                    )
                ]
            )

            let result = try BackupOperations.mergeIntoLibrary(
                snapshot: snapshot,
                context: context
            )
            let mergedItem = try #require(fetchItems(context).first)

            #expect(backupPhotoData != localPhotoData)
            #expect(result.insertedMarkCount == 1)
            #expect(mergedItem.photoData == localPhotoData)
            #expect(mergedItem.marks.map(\.day) == [Fixtures.previousDay])
        }

        @Test
        func `oversized backup data fails before decoding or replacing local state`() throws {
            let context = try makeContext()
            _ = try createItem(context: context, photoData: nil)
            let data = Data(count: BackupOperations.maximumImportDataByteCount + 1)
            let expectedPreview = BackupOperations.preview(
                data: data,
                currentItems: try fetchItems(context)
            )

            #expect(
                expectedPreview.validationIssues == [
                    .init(
                        kind: .backupFileTooLarge,
                        value: "\(data.count)"
                    )
                ]
            )
            #expect(throws: BackupError.validationFailed(expectedPreview)) {
                try BackupOperations.replaceLibrary(data: data, context: context)
            }
            #expect(try fetchItems(context).map(\.name) == ["Local Item"])
        }

        private func makeContext() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }

        private func fetchItems(_ context: ModelContext) throws -> [Item] {
            try context.fetch(.init())
        }

        private func makeLocalState(context: ModelContext) throws -> BackupPhotoLocalState {
            let photoData = try TestPhotoFixtures.preparedData()
            let item = try createItem(context: context, photoData: photoData)
            try ItemOperations.mark(
                item,
                on: Fixtures.today,
                today: Fixtures.today,
                context: context
            )

            return .init(
                itemID: item.uuid,
                photoData: photoData,
                markIDs: Set(item.marks.map(\.uuid))
            )
        }

        private func createItem(context: ModelContext, photoData: Data?) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(
                    name: "Local Item",
                    category: .other,
                    photoData: photoData
                ),
                createdAt: Fixtures.timestamp()
            )
        }

        private func invalidPhotoSnapshot(itemID: UUID) -> BackupSnapshot {
            .init(
                exportedAt: Fixtures.timestamp(),
                items: [
                    backupItem(
                        id: itemID,
                        photoData: Data("not an image".utf8),
                        marks: [backupMark()]
                    )
                ]
            )
        }

        private func backupItem(
            id: UUID,
            photoData: Data,
            marks: [BackupMark]
        ) -> BackupItem {
            .init(
                id: id,
                name: "Remote Item",
                categoryRawValue: ItemCategory.bags.rawValue,
                note: "Remote note",
                photoData: photoData,
                createdAt: Fixtures.timestamp(offset: -2),
                archivedAt: nil,
                marks: marks
            )
        }

        private func backupMark() -> BackupMark {
            .init(
                id: UUID(),
                day: Fixtures.previousDay,
                createdAt: Fixtures.timestamp(offset: -1)
            )
        }

        private func expectLocalState(
            _ expectedState: BackupPhotoLocalState,
            context: ModelContext
        ) throws {
            let items = try fetchItems(context)
            let item = try #require(items.first)

            #expect(items.count == 1)
            #expect(item.uuid == expectedState.itemID)
            #expect(item.name == "Local Item")
            #expect(item.photoData == expectedState.photoData)
            #expect(Set(item.marks.map(\.uuid)) == expectedState.markIDs)
        }
    }
}

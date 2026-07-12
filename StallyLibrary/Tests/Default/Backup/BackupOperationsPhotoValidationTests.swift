//
//  BackupOperationsPhotoValidationTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import ImageIO
import StallyLibrary
import Testing

@Suite
struct BackupOperationsPhotoValidationTests {
    private enum Fixtures {
        static let imageWidth = 64
        static let imageHeight = 48
        static let opaqueAlpha = 1.0

        static func timestamp() -> Date {
            .init(timeIntervalSinceReferenceDate: 0)
        }
    }

    @Test
    func `preview rejects corrupt oversized metadata bearing and noncanonical photos`() throws {
        let photoPayloads = try invalidPhotoPayloads()
        let snapshot = BackupSnapshot(
            exportedAt: Fixtures.timestamp(),
            items: photoPayloads.map { payload in
                backupItem(id: payload.id, photoData: payload.data)
            }
        )

        let preview = BackupOperations.preview(
            snapshot: snapshot,
            currentItems: []
        )

        #expect(!preview.canImport)
        #expect(preview.skippedItemCount == photoPayloads.count)
        #expect(
            preview.validationIssues == photoPayloads.map { payload in
                .init(
                    kind: .invalidItemPhoto,
                    value: payload.id.uuidString
                )
            }
        )
    }

    @Test
    func `preview rejects aggregate photo storage before decoding photos`() {
        let maximumPhotoByteCount = ItemPhotoOperations.maximumDataByteCount
        let repeatedPhotoData = Data(repeating: 0, count: maximumPhotoByteCount)
        let itemCount = BackupOperations.maximumImportPhotoDataByteCount
            / maximumPhotoByteCount + 1
        let totalPhotoDataByteCount = itemCount * maximumPhotoByteCount
        let snapshot = BackupSnapshot(
            exportedAt: Fixtures.timestamp(),
            items: (0..<itemCount).map { _ in
                backupItem(id: UUID(), photoData: repeatedPhotoData)
            }
        )

        let preview = BackupOperations.preview(
            snapshot: snapshot,
            currentItems: []
        )

        #expect(!preview.canImport)
        #expect(
            preview.validationIssues == [
                .init(
                    kind: .photoStorageLimitExceeded,
                    value: "\(totalPhotoDataByteCount)"
                )
            ]
        )
    }

    private func invalidPhotoPayloads() throws -> [(id: UUID, data: Data)] {
        [
            (UUID(), Data("not an image".utf8)),
            (
                UUID(),
                Data(
                    repeating: 0,
                    count: ItemPhotoOperations.maximumDataByteCount + 1
                )
            ),
            (
                UUID(),
                try TestPhotoFixtures.jpegData(
                    width: Fixtures.imageWidth,
                    height: Fixtures.imageHeight,
                    orientation: .up,
                    includesSourceMetadata: true
                )
            ),
            (
                UUID(),
                try TestPhotoFixtures.pngData(
                    width: Fixtures.imageWidth,
                    height: Fixtures.imageHeight,
                    alpha: Fixtures.opaqueAlpha
                )
            )
        ]
    }

    private func backupItem(id: UUID, photoData: Data) -> BackupItem {
        .init(
            id: id,
            name: "Canvas Tote",
            categoryRawValue: ItemCategory.bags.rawValue,
            note: "",
            photoData: photoData,
            createdAt: Fixtures.timestamp(),
            archivedAt: nil,
            marks: []
        )
    }
}

import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TransferTextTests {
    private static let nullableFields = [
        "items": ["note", "representativeURL"],
        "itemPhotos": ["caption"],
        "itemPeriods": ["startLocalDate", "endLocalDate"]
    ]

    @Test(arguments: [false, true])
    func emptyAndNullInputsClearReviewedValuesAndRoundTripAsNull(useEmptyString: Bool) async throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "transfer-text.store")
        let prepared = try await PhotoOperations.prepare(data: PhotoTestImages.imageData())
        let container = try StallyModelContainerFactory.disk(at: url)
        let context = ModelContext(container)
        var draft = ItemDraft(name: "Camera", note: "Original note")
        draft.representativeURL = "https://example.com"
        draft.photos = [.init(prepared: prepared, caption: "Original caption")]
        let item = try ItemOperations.save(draft, context: context)
        let period = try PeriodOperations.add(
            to: item,
            input: .init(start: "2024", end: "2025", isOngoing: false),
            today: "2026-11-10",
            context: context
        )
        let photoID = try #require(item.photos?.first?.uuid)
        let original = try TransferOperations.exportRecords(context: context)
        var object = try #require(JSONSerialization.jsonObject(with: original) as? [String: Any])
        for (key, fields) in Self.nullableFields {
            var rows = try #require(object[key] as? [[String: Any]])
            for field in fields {
                rows[0][field] = useEmptyString ? "" : NSNull()
            }
            object[key] = rows
        }
        let incoming = try await TransferFileOperations.readRecords(JSONSerialization.data(withJSONObject: object))
        let review = try TransferOperations.review(incoming, context: context)
        #expect(review.defaultSelection.isEmpty)
        #expect(review.rows.allSatisfy { !$0.isUnchanged })
        #expect(item.note == "Original note" && period.startLocalDate == "2024")
        #expect(try TransferOperations.apply(
            review, selection: Set(review.rows.map(\.id)), today: "2026-11-10", context: context
        ) == 3)

        let reopened = try StallyModelContainerFactory.disk(at: url)
        let reader = ModelContext(reopened)
        let saved = try ItemOperations.item(context: reader, uuid: item.uuid)
        #expect(saved.note == nil && saved.representativeURL == nil)
        let savedPhoto = try #require(saved.photos?.first)
        #expect(savedPhoto.uuid == photoID && savedPhoto.caption == nil && savedPhoto.imageData == prepared.imageData)
        let savedPeriod = try #require(saved.periods?.first)
        #expect(savedPeriod.uuid == period.uuid && savedPeriod.startLocalDate == nil
                    && savedPeriod.endLocalDate == nil && !savedPeriod.isOngoing)

        try assertNullableFieldsAreNull(TransferOperations.exportRecords(context: reader))
        try await assertReplayAndPackageRoundTrip(incoming, context: reader, directory: directory)
    }

    @Test
    func missingNullableKeysAndInvalidRequiredTextAreRejectedBeforeReview() async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Keep", note: "Keep note")
        draft.photos = [.init(prepared: try await PhotoOperations.prepare(data: PhotoTestImages.imageData()))]
        let item = try ItemOperations.save(draft, context: context)
        try PeriodOperations.add(to: item, input: .init(), today: "2026-11-10", context: context)
        try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
        try TagOperations.create(name: "Keep tag", context: context)
        let data = try TransferOperations.exportRecords(context: context)
        let original = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for (key, fields) in Self.nullableFields {
            for field in fields {
                var object = original
                var rows = try #require(object[key] as? [[String: Any]])
                rows[0].removeValue(forKey: field)
                object[key] = rows
                await #expect(throws: TransferError.invalidFile) {
                    try await TransferFileOperations.readRecords(JSONSerialization.data(withJSONObject: object))
                }
            }
        }
        for (key, field) in ["items": "name", "tags": "name", "itemMarks": "localDateTime"] {
            for invalid: Any in ["", NSNull()] {
                var object = original
                var rows = try #require(object[key] as? [[String: Any]])
                rows[0][field] = invalid
                object[key] = rows
                await #expect(throws: (any Error).self) {
                    try await TransferFileOperations.readRecords(JSONSerialization.data(withJSONObject: object))
                }
            }
        }
        #expect(!context.hasChanges && item.note == "Keep note")
    }

    private func assertReplayAndPackageRoundTrip(
        _ incoming: TransferArchive, context: ModelContext, directory: URL
    ) async throws {
        let replay = try TransferOperations.review(incoming, context: context)
        let replayMatches = replay.rows.allSatisfy(\.isUnchanged)
        #expect(replayMatches)
        #expect(try TransferOperations.apply(
            replay, selection: Set(replay.rows.map(\.id)), today: "2026-11-10", context: context
        ) == 0)

        let package = try TransferOperations.export(context: context, includingImages: true)
        let packageURL = directory.appending(path: "roundtrip.stally")
        try package.fileWrapper().write(to: packageURL, options: .atomic, originalContentsURL: nil)
        let loaded = try await TransferFileOperations.read(packageURL)
        let packageReview = try TransferOperations.review(loaded, context: context)
        let packageMatches = packageReview.rows.allSatisfy(\.isUnchanged)
        #expect(packageMatches)
    }

    private func assertNullableFieldsAreNull(_ data: Data) throws {
        let canonical = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for (key, fields) in Self.nullableFields {
            let rows = try #require(canonical[key] as? [[String: Any]])
            for field in fields {
                #expect(rows[0][field] is NSNull)
            }
        }
    }
}

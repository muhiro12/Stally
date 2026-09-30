import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct BackupImportReviewTests {
        @Test
        func `version three golden file restores through the fixed codec`() throws {
            let directory = try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
            let data = try Data(contentsOf: directory.appending(path: "Interchange/v3.stallybackup"))
            let expected = try JSONDecoder().decode(BackupSnapshot.self, from: data)
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let review = BackupOperations.review(data: data, currentItems: [])
            #expect(review.preview.itemCount == 2)
            #expect(review.preview.archivedItemCount == 1)
            #expect(review.preview.markCount == 1)
            try BackupOperations.importReviewed(review, context: context)
            let items = try ItemOperations.items(context: context)
            let exported = try BackupOperations.exportData(for: items, exportedAt: expected.exportedAt)
            let actual = try JSONDecoder().decode(BackupSnapshot.self, from: exported)
            #expect(actual == expected)
            #expect(StallyDataContract.persistenceVersion(forInterchangeVersion: actual.schemaVersion) == 2)
        }

        @Test(arguments: [false, true])
        func `review rejects metadata changes even when preview counts stay equal`(_ replacing: Bool) throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let item = try ItemOperations.create(context: context, input: .init(name: "Local", category: .other))
            let data = try BackupOperations.exportData(for: [])
            let review = BackupOperations.review(data: data, currentItems: [item], replacingExistingItems: replacing)
            item.note = "Changed after review"
            try context.save()
            let refreshed = BackupOperations.review(data: data, currentItems: [item], replacingExistingItems: replacing)
            #expect(refreshed.preview == review.preview)
            #expect(refreshed != review)
            #expect(throws: BackupError.reviewChanged(refreshed)) {
                try BackupOperations.importReviewed(review, context: context)
            }
            #expect(try ItemOperations.items(context: context).count == 1)
            #expect(item.note == "Changed after review")
            try BackupOperations.importReviewed(refreshed, context: context)
            #expect(try ItemOperations.items(context: context).count == (replacing ? 0 : 1))
        }

        @Test(arguments: [false, true])
        func `review detects pending insertions and keeps them intact`(_ replacing: Bool) throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let data = try BackupOperations.exportData(for: [])
            let review = BackupOperations.review(data: data, currentItems: [], replacingExistingItems: replacing)
            let item = Item(
                name: "Pending",
                category: .other,
                note: "",
                createdAt: .now,
                uuid: .init(),
                photoData: nil,
                archivedAt: nil
            )
            context.insert(item)
            #expect(throws: BackupError.self) {
                try BackupOperations.importReviewed(review, context: context)
            }
            #expect(context.hasChanges)
            #expect(try ItemOperations.item(context: context, uuid: item.uuid) === item)
        }

        @Test
        func `review owns its original bytes rather than an externally changed file`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let source = try ItemOperations.create(context: context, input: .init(name: "Original", category: .other))
            var data = try BackupOperations.exportData(for: [source])
            let destination = ModelContext(try StallyModelContainerFactory.inMemory())
            let review = BackupOperations.review(data: data, currentItems: [])
            data.removeAll()
            let result = try BackupOperations.importReviewed(review, context: destination)
            #expect(result.insertedItemCount == 1)
            #expect(try ItemOperations.items(context: destination).first?.name == "Original")
        }

        @Test
        func `valid combined collection restores every portable field exactly`() throws {
            let photo = try TestPhotoFixtures.preparedData()
            let timestamp = Date(timeIntervalSinceReferenceDate: 812_345_678.1234567)
            let day = try #require(LocalDay(year: 2_026, month: 9, day: 30))
            let starts: [String?] = [nil, "2000", "2000-02", "2000-02-29"]
            let payloads = starts.enumerated().map { index, start in
                BackupItem(
                    id: .init(),
                    name: "  Item \(index) 🪴  ",
                    categoryRawValue: ItemCategory.other.rawValue,
                    note: "  First line\n第二行  ",
                    photoData: photo,
                    createdAt: timestamp,
                    archivedAt: index.isMultiple(of: 2) ? timestamp.addingTimeInterval(0.75) : nil,
                    marks: index.isMultiple(of: 2) ? [] : [.init(id: .init(), day: day, createdAt: timestamp)],
                    recordsMarks: !index.isMultiple(of: 2),
                    startRawValue: start
                )
            }
            let snapshot = BackupSnapshot(exportedAt: timestamp, items: payloads)
            let data = try JSONEncoder().encode(snapshot)
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let review = BackupOperations.review(data: data, currentItems: [], replacingExistingItems: true)
            #expect(review.preview.canImport)
            try BackupOperations.importReviewed(review, context: context)
            let restored = try ItemOperations.items(context: context)
            let exported = try BackupOperations.exportData(for: restored, exportedAt: timestamp)
            let decoded = try JSONDecoder().decode(BackupSnapshot.self, from: exported)
            #expect(decoded.exportedAt == timestamp)
            #expect(decoded.schemaVersion == StallyDataContract.interchangeVersion)
            #expect(decoded.items.count == payloads.count)
            for payload in payloads {
                #expect(decoded.items.first { $0.id == payload.id } == payload)
            }
            let object = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
            #expect(Set(object.keys) == ["schemaVersion", "exportedAt", "items"])
            #expect((object["exportedAt"] as? Double) == timestamp.timeIntervalSinceReferenceDate)
            let firstItem = try #require((object["items"] as? [[String: Any]])?.first)
            #expect(firstItem["photoData"] as? String == photo.base64EncodedString())
            #expect(firstItem["recordsMarks"] is Bool)
            #expect(firstItem.keys.contains("start"))
        }
    }
}

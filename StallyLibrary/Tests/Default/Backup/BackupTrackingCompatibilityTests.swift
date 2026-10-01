import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct BackupTrackingCompatibilityTests {
        @Test
        func `v3 restores every start precision and both Mark policies without loss`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let inputs = [nil, "2020", "2020-09", "2020-09-13", "9999-12-31"]
            let items = inputs.enumerated().map { index, start in
                payload(recordsMarks: index.isMultiple(of: 2), start: start)
            }
            let snapshot = BackupSnapshot(exportedAt: .now, items: items)
            let encoded = try JSONEncoder().encode(snapshot)
            #expect(snapshot.schemaVersion == 3)
            let preview = BackupOperations.preview(data: encoded, currentItems: [])
            #expect(preview.canImport)
            try BackupOperations.replaceLibrary(data: encoded, context: context)
            let restored = try ItemOperations.items(context: context)
            let exported = try BackupOperations.exportData(for: restored, exportedAt: snapshot.exportedAt)
            let decoded = try JSONDecoder().decode(BackupSnapshot.self, from: exported)
            #expect(Set(decoded.items.map(\.id)) == Set(items.map(\.id)))
            for item in decoded.items {
                #expect(item == items.first { $0.id == item.id })
            }
        }

        @Test(arguments: ["start", "recordsMarks"])
        func `v3 requires its new keys instead of silently applying legacy defaults`(_ key: String) throws {
            let snapshot = BackupSnapshot(exportedAt: .now, items: [payload()])
            let data = try JSONEncoder().encode(snapshot)
            var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
            var items = try #require(object["items"] as? [[String: Any]])
            items[0].removeValue(forKey: key)
            object["items"] = items
            let incomplete = try JSONSerialization.data(withJSONObject: object)
            #expect(BackupOperations.preview(data: incomplete, currentItems: []).validationIssues == [
                .init(kind: .unreadableBackup)
            ])
        }

        @Test
        func `v2 encoding refuses a lossy downgrade of tracking fields`() {
            let snapshot = BackupSnapshot(
                exportedAt: .now,
                items: [payload(recordsMarks: false, start: "2020")],
                schemaVersion: 2
            )
            #expect(throws: EncodingError.self) {
                try JSONEncoder().encode(snapshot)
            }
            #expect(!BackupOperations.preview(snapshot: snapshot, currentItems: []).canImport)
        }

        @Test(arguments: [2, 3])
        func `mark conflicts block the whole merge but permit a valid replacement`(_ version: Int) throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            let start = try #require(ItemStart(rawValue: "2020"))
            let local = try ItemOperations.create(
                context: context,
                input: .init(name: "Local Plant", category: .other),
                tracking: .init(recordsMarks: false, start: start),
                today: today
            )
            let mark = BackupMark(id: .init(), day: today, createdAt: .now)
            let incoming = payload(id: local.uuid, marks: [mark])
            let snapshot = BackupSnapshot(exportedAt: .now, items: [payload(), incoming], schemaVersion: version)
            let data = try JSONEncoder().encode(snapshot)
            let preview = BackupOperations.preview(data: data, currentItems: [local])
            #expect(preview.validationIssues == [.init(kind: .markPolicyMergeConflict, value: local.uuid.uuidString)])
            #expect(throws: BackupError.self) {
                try BackupOperations.mergeIntoLibrary(data: data, context: context)
            }
            #expect(try ItemOperations.items(context: context).count == 1)
            #expect(local.startRawValue == "2020")
            #expect(local.marks.isEmpty)
            let replacement = BackupOperations.preview(data: data, currentItems: [local], replacingExistingItems: true)
            #expect(replacement.canImport)
            #expect(replacement.newItemCount == 2)
            try BackupOperations.replaceLibrary(data: data, context: context)
            let restored = try #require(try ItemOperations.item(context: context, uuid: incoming.id))
            #expect(restored.recordsMarks)
            #expect(restored.marks.first?.uuid == mark.id)
        }

        @Test
        func `merge preserves local unknown starts and mode and remains idempotent`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            let local = try ItemOperations.create(
                context: context,
                input: .init(name: "Local", category: .other),
                tracking: .init(recordsMarks: false, start: nil),
                today: today
            )
            let incoming = payload(id: local.uuid, recordsMarks: true, start: "2000")
            let snapshot = BackupSnapshot(exportedAt: .now, items: [incoming])
            for _ in 0..<2 {
                let result = try BackupOperations.mergeIntoLibrary(snapshot: snapshot, context: context)
                #expect(result.insertedItemCount == 0)
                #expect(result.insertedMarkCount == 0)
                #expect(local.name == "Local")
                #expect(!local.recordsMarks)
                #expect(local.startRawValue == nil)
            }
        }

        @Test
        func `invalid starts and non Mark history cannot escape export validation`() throws {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            let item = try ItemOperations.create(context: context, input: .init(name: "Bag", category: .bags))
            item.startRawValue = "2020-02-30"
            try context.save()
            #expect(throws: BackupError.self) {
                try BackupOperations.exportData(for: [item])
            }
            #expect(item.startRawValue == "2020-02-30")
            item.startRawValue = nil
            let day = try #require(LocalDay(year: 2_026, month: 9, day: 13))
            try ItemOperations.mark(item, on: day, today: day, context: context)
            let markID = item.marks.first?.uuid
            item.recordsMarks = false
            try context.save()
            #expect(throws: BackupError.self) {
                try BackupOperations.exportData(for: [item])
            }
            let snapshot = BackupOperations.snapshot(for: [item])
            #expect(!BackupOperations.preview(snapshot: snapshot, currentItems: []).canImport)
            #expect(item.marks.first?.uuid == markID)
            #expect(!item.recordsMarks)
        }

        private func payload(
            id: UUID = .init(),
            recordsMarks: Bool = true,
            start: String? = nil,
            marks: [BackupMark] = []
        ) -> BackupItem {
            .init(
                id: id,
                name: "Imported",
                categoryRawValue: ItemCategory.other.rawValue,
                note: "",
                photoData: nil,
                createdAt: .now,
                archivedAt: nil,
                marks: marks,
                recordsMarks: recordsMarks,
                startRawValue: start
            )
        }
    }
}

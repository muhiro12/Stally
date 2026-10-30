import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct CorePersistenceTests {
    @Test
    func occurrencesAndIndependentStateSurviveReopen() throws {
        let url = try storeURL()
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            context.autosaveEnabled = false
            let item = try ItemOperations.create(
                context: context,
                name: "  Same subject  ",
                note: "Original note"
            )
            #expect(item.marks?.isEmpty == true)
            #expect(item.periods?.isEmpty == true)
            let first = try MarkOperations.add(to: item, localDateTime: "2024-02-29", context: context)
            let second = try MarkOperations.add(to: item, localDateTime: "2024-02-29", context: context)
            #expect(first.uuid != second.uuid)
            let firstID = first.uuid
            let created = first.createdAt
            try MarkOperations.correct(first, localDateTime: "2024-02-29T23:59", context: context)
            #expect(first.uuid == firstID)
            #expect(first.createdAt == created)
            try ItemOperations.setArchived(item, to: true, context: context)
            try ItemOperations.setFavorite(item, to: true, context: context)
            try ItemOperations.setMarkRecordingEnabled(item, to: false, context: context)
            #expect(throws: RecordError.recordingPaused) {
                try MarkOperations.add(to: item, localDateTime: "2024-03-01", context: context)
            }
            try MarkOperations.correct(second, localDateTime: "2024-02-29T00:00", context: context)
            return item.uuid
        }
        try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.item(context: context, uuid: identity)
            #expect(item.name == "  Same subject  ")
            #expect(item.note == "Original note")
            #expect(item.isArchived && item.isFavorite && !item.isMarkRecordingEnabled)
            #expect(Set((item.marks ?? []).map(\.localDateTime)) == ["2024-02-29T23:59", "2024-02-29T00:00"])
            try ItemOperations.setMarkRecordingEnabled(item, to: true, context: context)
            try MarkOperations.add(to: item, localDateTime: "2024-02-29", context: context)
            #expect(item.marks?.count == 3)
        }
    }

    @Test
    func periodEndResumeCorrectionAndPrecisionSurviveReopen() throws {
        let url = try storeURL()
        let identifiers = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "Relationship")
            let first = try PeriodOperations.add(
                to: item,
                input: .init(start: "2020"),
                today: "2026-10-27",
                context: context
            )
            let original = first.createdAt
            try PeriodOperations.end(first, on: "2021-05", today: "2026-10-27", context: context)
            let second = try PeriodOperations.resume(
                first,
                on: "2022-06-01",
                today: "2026-10-27",
                context: context
            )
            #expect(first.uuid != second.uuid)
            #expect(first.createdAt == original)
            try PeriodOperations.end(second, on: nil, today: "2026-10-27", context: context)
            try PeriodOperations.correct(
                second,
                input: .init(start: second.startLocalDate, end: nil, isOngoing: true),
                today: "2026-10-27",
                context: context
            )
            #expect(throws: RecordError.ongoingPeriodExists) {
                try PeriodOperations.add(to: item, input: .init(), today: "2026-10-27", context: context)
            }
            return (item.uuid, first.uuid, second.uuid)
        }
        try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.item(context: context, uuid: identifiers.0)
            let first = try #require(item.periods?.first { $0.uuid == identifiers.1 })
            let second = try #require(item.periods?.first { $0.uuid == identifiers.2 })
            #expect(first.startLocalDate == "2020" && first.endLocalDate == "2021-05" && !first.isOngoing)
            #expect(second.startLocalDate == "2022-06-01" && second.endLocalDate == nil && second.isOngoing)
            #expect(item.periods?.count == 2)
        }
    }

    @Test
    func cascadeAndSharedTagDeletionAreScoped() throws {
        let url = try storeURL()
        let retainedID = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let removed = try ItemOperations.create(context: context, name: "Same")
            let retained = try ItemOperations.create(context: context, name: "Same")
            for item in [removed, retained] {
                try MarkOperations.add(to: item, localDateTime: "2026-10-27", context: context)
                try PeriodOperations.add(to: item, input: .init(), today: "2026-10-27", context: context)
                context.insert(
                    ItemPhoto(
                        item: item,
                        imageData: Data(repeating: 71, count: 2_000_000),
                        thumbnailData: Data([1, 2, 3]),
                        caption: "",
                        sortOrder: 0
                    )
                )
                try context.save()
            }
            let shared = try TagOperations.create(name: "  Travel  ", context: context)
            let separate = try TagOperations.create(name: "  Travel  ", context: context)
            #expect(shared.uuid != separate.uuid)
            try TagOperations.assign([shared, separate], to: removed, context: context)
            try TagOperations.assign([shared], to: retained, context: context)
            try TagOperations.delete(shared, context: context)
            #expect(try context.fetchCount(FetchDescriptor<Item>()) == 2)
            try ItemOperations.delete(removed, context: context)
            return retained.uuid
        }
        try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let retained = try ItemOperations.item(context: context, uuid: retainedID)
            #expect(try context.fetchCount(FetchDescriptor<Item>()) == 1)
            #expect(try context.fetchCount(FetchDescriptor<ItemMark>()) == 1)
            #expect(try context.fetchCount(FetchDescriptor<ItemPeriod>()) == 1)
            #expect(try context.fetchCount(FetchDescriptor<ItemPhoto>()) == 1)
            #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 1)
            #expect(retained.tags?.isEmpty == true)
            let photo = try #require(retained.photos?.first)
            #expect(photo.imageData == Data(repeating: 71, count: 2_000_000))
            #expect(photo.thumbnailData == Data([1, 2, 3]))
            context.delete(photo)
            try context.save()
            #expect(retained.marks?.count == 1 && retained.periods?.count == 1)
        }
    }

    @Test
    func unrelatedPendingChangesArePreserved() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "Saved")
        item.note = "Unrelated pending edit"
        #expect(throws: RecordError.pendingChanges) {
            try MarkOperations.add(to: item, localDateTime: "2026-10-27", context: context)
        }
        #expect(item.note == "Unrelated pending edit" && context.hasChanges)
    }

    private func storeURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "test.store")
    }
}

import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct RecordMutationIsolationTests {
    @Test(arguments: [
        "favorite", "archive", "recording", "markCorrection", "markDeletion", "periodCorrection",
        "periodEnding", "periodDeletion", "tagAssignment", "tagDeletion", "tagRename"
    ])
    func mutationPreservesOtherSavedItemFactsAfterReopen(kind: String) throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "mutation-isolation.store")
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "Original", note: "Original note")
            let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
            let period = try PeriodOperations.add(
                to: item, input: .init(start: "2020"), today: "2026-11-14", context: context
            )
            let tag = try TagOperations.create(name: "Original Tag", context: context)
            try TagOperations.assign([tag], to: item, context: context)
            _ = item.marks
            _ = item.periods
            _ = item.tags
            let other = ModelContext(container)
            let saved = try ItemOperations.item(context: other, uuid: item.uuid)
            var draft = ItemOperations.draft(for: saved)
            draft.name = "Latest"
            draft.note = "Latest note"
            draft.representativeURL = "https://example.com/latest"
            try ItemOperations.save(draft, context: other)
            try mutate(kind, item: item, mark: mark, period: period, tag: tag)
            #expect(!context.hasChanges)
            return item.uuid
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let item = try ItemOperations.item(context: context, uuid: identity)
        #expect(item.name == "Latest")
        #expect(item.note == "Latest note")
        #expect(item.representativeURL == "https://example.com/latest")
        #expect(item.isFavorite == (kind == "favorite"))
        #expect(item.isArchived == (kind == "archive"))
        #expect(item.isMarkRecordingEnabled == (kind != "recording"))
        #expect(item.marks?.count == (kind == "markDeletion" ? 0 : 1))
        #expect(item.periods?.count == (kind == "periodDeletion" ? 0 : 1))
        #expect(item.tags?.count == (["tagAssignment", "tagDeletion"].contains(kind) ? 0 : 1))
    }

    @Test(arguments: [false, true])
    func correctionPreservesRegistrationMetadataSavedByImport(periodCorrection: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "History")
        let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
        let period = try PeriodOperations.add(
            to: item, input: .init(start: "2020"), today: "2026-11-14", context: context
        )
        _ = mark.createdAt
        _ = period.createdAt
        let other = ModelContext(container)
        let savedMark = try #require(other.fetch(FetchDescriptor<ItemMark>()).first)
        let savedPeriod = try #require(other.fetch(FetchDescriptor<ItemPeriod>()).first)
        let importedRegistration = Date(timeIntervalSince1970: 1_000)
        savedMark.createdAt = importedRegistration
        savedPeriod.createdAt = importedRegistration
        try other.save()
        if periodCorrection {
            try PeriodOperations.correct(
                period,
                input: .init(start: "2021"),
                today: "2026-11-14",
                context: context,
                original: .init(start: "2020")
            )
        } else {
            try MarkOperations.correct(mark, localDateTime: "2026-11-11", context: context, original: "2026-11-10")
        }
        let reader = ModelContext(container)
        #expect(try reader.fetch(FetchDescriptor<ItemMark>()).first?.createdAt == importedRegistration)
        #expect(try reader.fetch(FetchDescriptor<ItemPeriod>()).first?.createdAt == importedRegistration)
    }

    @Test(arguments: [false, true])
    func deletionAndRenamePreserveOtherSavedTagFacts(deletingItem: Bool) throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = ModelContext(container)
        let item = try ItemOperations.create(context: context, name: "History")
        let tag = try TagOperations.create(name: "Original", context: context)
        try TagOperations.assign([tag], to: item, context: context)
        let other = ModelContext(container)
        let savedTag = try #require(other.fetch(FetchDescriptor<StallyLibrary.Tag>()).first)
        let second = try ItemOperations.create(context: other, name: "Second")
        try TagOperations.assign([savedTag], to: second, context: other)
        try TagOperations.rename(savedTag, name: "Latest", context: other)
        if deletingItem {
            try ItemOperations.delete(item, context: context)
        } else {
            try TagOperations.rename(tag, name: "Chosen", context: context)
        }
        let reader = ModelContext(container)
        let saved = try #require(reader.fetch(FetchDescriptor<StallyLibrary.Tag>()).first)
        #expect(saved.name == (deletingItem ? "Latest" : "Chosen"))
        #expect(Set((saved.items ?? []).map(\.uuid)) == (deletingItem ? [second.uuid] : [item.uuid, second.uuid]))
    }

    private func mutate(
        _ kind: String, item: Item, mark: ItemMark, period: ItemPeriod, tag: StallyLibrary.Tag
    ) throws {
        let context = try #require(item.modelContext)
        switch kind {
        case "favorite", "archive", "recording":
            try changeState(kind, item: item, context: context)
        case "markCorrection":
            try MarkOperations.correct(mark, localDateTime: "2026-11-11", context: context, original: "2026-11-10")
            #expect(mark.localDateTime == "2026-11-11")
        case "markDeletion":
            try MarkOperations.delete(mark, context: context)
        case "periodCorrection":
            try PeriodOperations.correct(period, input: .init(start: "2021"), today: "2026-11-14", context: context)
            #expect(period.startLocalDate == "2021")
        case "periodEnding":
            try PeriodOperations.end(period, on: "2022", today: "2026-11-14", context: context)
            #expect(period.endLocalDate == "2022" && !period.isOngoing)
        case "periodDeletion":
            try PeriodOperations.delete(period, context: context)
        case "tagAssignment":
            try TagOperations.assign([], to: item, context: context)
        case "tagDeletion":
            try TagOperations.delete(tag, context: context)
        default:
            try TagOperations.rename(tag, name: "Renamed", context: context)
            #expect(tag.name == "Renamed")
        }
    }

    private func changeState(_ kind: String, item: Item, context: ModelContext) throws {
        switch kind {
        case "favorite":
            try ItemOperations.setFavorite(item, to: true, context: context)
        case "archive":
            try ItemOperations.setArchived(item, to: true, context: context)
        default:
            try ItemOperations.setMarkRecordingEnabled(item, to: false, context: context)
        }
    }
}

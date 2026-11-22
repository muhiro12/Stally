import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct ItemDraftPeriodTests {
    private let today = "2026-01-01"

    @Test
    func correctionsRemovalsAndResumptionPersistWithMetadata() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "period-edits.store")
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        var draft = ItemDraft(name: "Camera")
        draft.periods = [.init(input: .init(start: "2020")), .init(input: .init(isOngoing: false))]
        let item = try ItemOperations.save(draft, context: context, today: today)
        try MarkOperations.add(to: item, localDateTime: today, context: context)
        let ongoing = item.periods?.first(where: \.isOngoing)
        let first = try #require(ongoing)
        let identity = first.uuid
        let createdAt = first.createdAt
        var edit = ItemOperations.draft(for: item)
        edit.name = "Film camera"
        edit.periods.removeAll { $0.id != identity }
        edit.periods[0].input = .init(start: "2020", end: "2022-06", isOngoing: false)
        edit.periods.append(.init(input: .init(start: "2023-07")))
        #expect(first.isOngoing && item.periods?.count == 2 && !context.hasChanges)
        let updated = try ItemOperations.save(edit, context: context, today: today)
        #expect(updated.periods?.contains { $0.uuid == identity && $0.endLocalDate == "2022-06" } == true)

        let reader = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let reopened = try ItemOperations.item(context: reader, uuid: item.uuid)
        let saved = try #require(reopened.periods)
        #expect(reopened.name == edit.name && saved.count == 2 && reopened.marks?.count == 1)
        let ended = try #require(saved.first { $0.uuid == identity })
        #expect(ended.createdAt == createdAt && PeriodInput(ended) == edit.periods[0].input)
        #expect(saved.contains { $0.uuid != identity && PeriodInput($0) == edit.periods[1].input })
    }

    @Test(arguments: [true, false])
    func staleCorrectionOrRemovalRejectsWholeSave(removing: Bool) throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Camera")
        let period = try PeriodOperations.add(to: item, input: .init(start: "2020"), today: today, context: context)
        var draft = ItemOperations.draft(for: item)
        draft.note = "Draft note"
        if removing {
            draft.periods.removeAll()
        } else {
            draft.periods[0].input = .init(start: "2021")
        }
        try PeriodOperations.correct(period, input: .init(start: "2022"), today: today, context: context)
        #expect(throws: RecordError.staleReview) {
            try ItemOperations.save(draft, context: context, today: today)
        }
        #expect(item.note == nil && period.startLocalDate == "2022" && !context.hasChanges)
    }

    @Test
    func untouchedHistoryUsesLatestSavedFacts() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Book")
        let first = try PeriodOperations.add(to: item, input: .init(start: "2020"), today: today, context: context)
        var draft = ItemOperations.draft(for: item)
        try PeriodOperations.end(first, on: "2021", today: today, context: context)
        let later = try PeriodOperations.add(to: item, input: .init(start: "2024"), today: today, context: context)
        draft.periods.append(.init(input: .init(start: "2022", end: "2023", isOngoing: false)))
        try ItemOperations.save(draft, context: context, today: today)
        let saved = try #require(ModelContext(context.container).fetch(FetchDescriptor<Item>()).first?.periods)
        #expect(saved.count == 3)
        #expect(saved.contains { $0.uuid == first.uuid && $0.endLocalDate == "2021" })
        #expect(saved.contains { $0.uuid == later.uuid && $0.isOngoing })
    }

    @Test
    func reviewedSuggestionCanFillMetadataWithoutDuplicatingAnEditedPeriod() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Book")
        let first = try PeriodOperations.add(to: item, input: .init(start: "2020"), today: today, context: context)
        var draft = ItemOperations.draft(for: item)
        let revised = PeriodInput(start: "2020-03")
        draft.periods[0].input = revised
        let applied = ItemInputOperations.applying(
            .init(name: "Book", note: "First edition"), to: draft, reviewedPeriods: [revised]
        )
        #expect(applied.newPeriods.isEmpty && applied.periods.map(\.id) == [first.uuid])
        let saved = try ItemOperations.save(applied, context: context, today: today)
        #expect(saved.note == "First edition" && saved.periods?.first?.startLocalDate == revised.start)
    }

    @Test
    func improvesConflictingSavedHistoryWithoutIntroducingNewConflicts() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Book")
        for start in ["2020", "2021", "2022"] {
            context.insert(ItemPeriod(item: item, startLocalDate: start, endLocalDate: nil, isOngoing: true))
        }
        try context.save()
        var edit = ItemOperations.draft(for: item)
        let index = try #require(edit.periods.firstIndex { $0.input.start == "2020" })
        edit.periods[index].input = .init(start: "2019", isOngoing: true)
        #expect(throws: RecordError.self) {
            try ItemOperations.save(edit, context: context, today: today)
        }
        edit.periods[index].input = .init(start: "2020", end: "2020", isOngoing: false)
        try ItemOperations.save(edit, context: context, today: today)
        let saved = try ModelContext(context.container).fetch(FetchDescriptor<ItemPeriod>())
        #expect(saved.count == 3 && saved.filter(\.isOngoing).count == 2)
    }

    @Test
    func validatesTheFinalHistoryWhenMovingTwoBoundariesTogether() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Notebook")
        draft.periods = [
            .init(input: .init(start: "2020", end: "2022", isOngoing: false)),
            .init(input: .init(start: "2022"))
        ]
        let item = try ItemOperations.save(draft, context: context, today: today)
        var edit = ItemOperations.draft(for: item)
        let retained = try #require(item.periods?.first)
        for index in edit.periods.indices {
            edit.periods[index].input = edit.periods[index].input.isOngoing
                ? .init(start: "2024-01-01") : .init(start: "2020", end: "2024-01-01", isOngoing: false)
        }
        try ItemOperations.save(edit, context: context, today: today)
        let current = ItemOperations.draft(for: item)
        #expect(current.periods == edit.periods)
        #expect(retained.isOngoing ? retained.startLocalDate == "2024-01-01" : retained.endLocalDate == "2024-01-01")
        let saved = try ModelContext(context.container).fetch(FetchDescriptor<ItemPeriod>())
        #expect(saved.contains { $0.endLocalDate == "2024-01-01" })
        #expect(saved.contains { $0.startLocalDate == "2024-01-01" })
    }
}

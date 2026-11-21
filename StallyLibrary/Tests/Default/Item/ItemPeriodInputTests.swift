import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

struct ItemPeriodInputTests {
    @Test(arguments: [
        ("2023年", "2023"), ("2023年6月", "2023-06"), ("2024年2月29日", "2024-02-29"),
        ("2023-06", "2023-06"), ("2023/6/12", "2023-06-12"), ("June 2023", "2023-06"),
        ("June 12, 2023", "2023-06-12"), ("2023-6-2", "2023-06-02"),
        ("2023/06/2", "2023-06-02"), ("2023年6月02日", "2023-06-02")
    ])
    func purchaseDatesPreserveOnlyStatedPrecision(_ sourceDate: String, _ expected: String) throws {
        let source = "Purchased: \(sourceDate)."
        let dates = try ItemInputDate.occurrences(in: source)
        let candidates = try ItemInputPeriodGeneration.suggestions(dates: dates, roles: [.purchase], source: source)
        let candidate = try #require(candidates.first)
        #expect(candidate.start == expected)
        #expect(candidate.end == nil && candidate.continuation == .unspecified)
        #expect(candidate.evidence == source && candidate.basis == .purchase)
    }

    @Test(arguments: [
        "2023年2月29日", "6月12日", "去年", "2023年ごろ", "2023-13", "2023-2-29",
        "2023年2月30", "2023/13/1", "2023-06-12-15"
    ])
    func invalidRelativeAndApproximateDatesAreNotMadeExact(_ date: String) throws {
        #expect(try ItemInputDate.occurrences(in: date).isEmpty)
    }

    @Test
    func datesCannotBeInventedOrHaveTheirPrecisionChangedByTheModel() throws {
        let source = "2023年6月12日に購入。2024年には使用していた。"
        let dates = try ItemInputDate.occurrences(in: source)
        #expect(dates.map(\.value) == ["2023-06-12", "2024"])
        #expect(throws: ItemInputError.invalidResult) {
            try ItemInputPeriodGeneration.suggestions(dates: dates, roles: [.purchase], source: source)
        }
        let candidates = try ItemInputPeriodGeneration.suggestions(
            dates: dates, roles: [.purchase, .irrelevant], source: source
        )
        #expect(candidates.map(\.start) == ["2023-06-12"])
    }

    @Test
    func productNumbersAndDatesWithoutAnEventDoNotCreatePeriods() throws {
        let source = "Radio ABC2023 and model 1820B. No purchase date."
        let dates = try ItemInputDate.occurrences(in: source)
        #expect(dates.isEmpty)
        #expect(try ItemInputPeriodGeneration.suggestions(dates: dates, roles: [], source: source).isEmpty)
    }

    @Test
    func aPurchaseInAnotherClauseDoesNotTurnARepairDateIntoAPurchase() async throws {
        let source = "2021年に修理、2023年に購入。"
        let candidates = try await ItemInputPeriodGeneration.infer(source: source) { _, _ in
            .init(action: "購入", event: "購入", subject: "対象アイテム", isOngoing: false)
        }
        #expect(candidates.map(\.start) == ["2023"])
    }

    @Test
    func alternativesAndRepeatedPeriodsRemainSeparateAndKeepTheirEvidence() throws {
        let source = "2020年3月に注文。2020年4月に到着。2021年に手放した。2023年6月から再び使っている。"
        let dates = try ItemInputDate.occurrences(in: source)
        let candidates = try ItemInputPeriodGeneration.suggestions(
            dates: dates, roles: [.order, .delivery, .end, .ongoingStart], source: source
        )
        #expect(candidates.count == 3)
        #expect(candidates[0].basis == .order && candidates[0].start == "2020-03")
        #expect(candidates[1].basis == .delivery && candidates[1].start == "2020-04")
        #expect(candidates[0].end == "2021" && candidates[1].end == "2021")
        #expect(candidates[0].continuation == .ended && candidates[1].continuation == .ended)
        #expect(candidates[2].start == "2023-06" && candidates[2].continuation == .ongoing)
        #expect(candidates.allSatisfy { source.contains($0.evidence) })
    }

    @Test
    func endedPeriodsCanRetainAnUnknownStartAndRejectReversedDates() throws {
        let source = "2022年に手放した。"
        let candidates = try ItemInputPeriodGeneration.suggestions(
            dates: ItemInputDate.occurrences(in: source), roles: [.end], source: source
        )
        #expect(candidates.first?.start == nil && candidates.first?.end == "2022")
        let reversed = "2024年から2023年まで使った。"
        #expect(throws: RecordError.invalidPeriod) {
            try ItemInputPeriodGeneration.suggestions(
                dates: ItemInputDate.occurrences(in: reversed), roles: [.start, .end], source: reversed
            )
        }
    }

    @Test
    func literalRangeMarkersPreserveBothBoundariesOfPastUse() throws {
        let source = "2018年から2020年まで使っていた。"
        let candidates = try ItemInputPeriodGeneration.suggestions(
            dates: ItemInputDate.occurrences(in: source), roles: [.end, .end], source: source
        )
        #expect(candidates.count == 1)
        #expect(candidates.first?.start == "2018" && candidates.first?.end == "2020")
        #expect(candidates.first?.continuation == .ended)
    }

    @Test
    func generatedCandidatesAreNotAppliedUntilReviewed() {
        let suggestion = ItemInputSuggestion(name: "Mug", periods: [
            .init(start: "2023-06", end: nil, continuation: .unspecified, basis: .purchase, evidence: "2023年6月に購入")
        ])
        let unreviewed = ItemInputOperations.applying(suggestion, to: .init())
        #expect(unreviewed.newPeriods.isEmpty)
        let reviewed = PeriodInput(start: "2023-07", isOngoing: true)
        let applied = ItemInputOperations.applying(
            suggestion, to: unreviewed, reviewedPeriods: [reviewed]
        )
        #expect(applied.newPeriods.map(\.input) == [reviewed])
        let reapplied = ItemInputOperations.applying(
            suggestion, to: applied, reviewedPeriods: [reviewed]
        )
        #expect(reapplied.newPeriods.map(\.id) == applied.newPeriods.map(\.id))
    }

    @MainActor
    @Test
    func reviewedPeriodsSaveWithTheItemAndSurviveReopen() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "reviewed-period.store")
        let identity = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            var draft = ItemDraft(name: "Mug", note: "A gift")
            draft.newPeriods = [
                .init(input: .init(start: "2018", end: "2020-06", isOngoing: false)),
                .init(input: .init(start: "2023-06", isOngoing: true))
            ]
            #expect(!context.hasChanges)
            #expect(try context.fetchCount(FetchDescriptor<ItemPeriod>()) == 0)
            return try ItemOperations.save(draft, context: context, today: "2025-01-01").uuid
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let saved = try ItemOperations.item(context: context, uuid: identity)
        let periods = try #require(saved.periods)
        #expect(saved.note == "A gift" && saved.marks?.isEmpty == true)
        #expect(periods.count == 2)
        #expect(periods.contains { $0.startLocalDate == "2018" && $0.endLocalDate == "2020-06" && !$0.isOngoing })
        #expect(periods.contains { $0.startLocalDate == "2023-06" && $0.endLocalDate == nil && $0.isOngoing })
    }

    @MainActor
    @Test
    func conflictingAdditionsRejectTheEntireSaveWithoutPendingChanges() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Original")
        var draft = ItemOperations.draft(for: item)
        draft.name = "Changed"
        draft.newTags = [.init(name: "New tag")]
        draft.newPeriods = [.init(input: .init(start: "2023-06"))]
        let existing = try PeriodOperations.add(
            to: item, input: .init(start: "2024"), today: "2025-01-01", context: context
        )
        #expect(throws: RecordError.ongoingPeriodExists) {
            try ItemOperations.save(draft, context: context, today: "2025-01-01")
        }
        #expect(!context.hasChanges && item.name == "Original")
        #expect(try context.fetchCount(FetchDescriptor<StallyLibrary.Tag>()) == 0)
        #expect(item.periods?.map(\.uuid) == [existing.uuid])
        #expect(draft.newPeriods.count == 1 && draft.name == "Changed")
    }

    @MainActor
    @Test
    func invalidNewItemPeriodsDoNotSaveAnItemOrEarlierValidAdditions() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Mug")
        draft.newPeriods = [
            .init(input: .init(start: "2020", end: "2021", isOngoing: false)),
            .init(input: .init(start: "2024", end: "2023", isOngoing: false))
        ]
        #expect(throws: RecordError.invalidPeriod) {
            try ItemOperations.save(draft, context: context, today: "2025-01-01")
        }
        #expect(!context.hasChanges)
        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ItemPeriod>()) == 0)
    }

    @MainActor
    @Test
    func savingFailureDoesNotLeakPeriodAdditionsIntoTheEditor() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "readonly-period.store")
        let identity = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            return try ItemOperations.create(context: context, name: "Original").uuid
        }
        let schema = StallyModelContainerFactory.schema
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(
            "Stally", schema: schema, url: url, allowsSave: false, cloudKitDatabase: .none
        ))
        let context = ModelContext(container)
        let item = try ItemOperations.item(context: context, uuid: identity)
        var draft = ItemOperations.draft(for: item)
        draft.name = "Changed"
        draft.newPeriods = [.init(input: .init(start: "2023-06"))]
        #expect(throws: (any Error).self) {
            try ItemOperations.save(draft, context: context, today: "2025-01-01")
        }
        #expect(!context.hasChanges && item.name == "Original")
        #expect(item.periods?.isEmpty == true)
        #expect(draft.newPeriods.count == 1)
        let reopened = ModelContext(try StallyModelContainerFactory.disk(at: url))
        #expect(try ItemOperations.item(context: reopened, uuid: identity).periods?.isEmpty == true)
    }
}

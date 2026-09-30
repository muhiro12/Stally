import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemCapabilityContractTests {
        @Test(arguments: ItemMarkPolicy.allCases, [false, true])
        func `capabilities match mutation guards for both policies and placements`(
            policy: ItemMarkPolicy,
            archived: Bool
        ) throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Place", category: .other),
                tracking: .init(markPolicy: policy, start: nil),
                today: today
            )
            if archived {
                try ItemOperations.archive(item, on: .now, context: context)
            }
            let captured = ItemOperations.capabilities(for: item)
            #expect(captured.canArchive == !archived)
            #expect(captured.canMoveBackToLibrary == archived)
            #expect(captured.canDisableMarkRecording)
            #expect(!captured.hasNonMarkHistoryConflict)
            #expect(captured.canChangeHistory == (policy == .enabled && !archived))
            if let error = captured.historyChangeError {
                #expect(throws: error) {
                    try ItemOperations.mark(item, on: today, today: today, context: context)
                }
                #expect(throws: error) {
                    try ItemOperations.undoMark(item, on: today, context: context)
                }
            } else {
                #expect(try ItemOperations.mark(item, on: today, today: today, context: context))
                #expect(try !ItemOperations.mark(item, on: today, today: today, context: context))
            }
        }

        @Test
        func `captured permissions never authorize a later invalid mutation`() throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try ItemOperations.create(context: context, input: .init(name: "Bag", category: .bags))
            let before = ItemOperations.capabilities(for: item)
            #expect(before.canChangeHistory)
            try ItemOperations.mark(item, on: today, today: today, context: context)
            #expect(!ItemOperations.capabilities(for: item).canDisableMarkRecording)
            try ItemOperations.archive(item, on: .now, context: context)
            #expect(before.canChangeHistory)
            #expect(!ItemOperations.capabilities(for: item).canChangeHistory)
            #expect(throws: ItemValidationError.archivedItemsCannotChangeHistory) {
                try ItemOperations.undoMark(item, on: today, context: context)
            }
            item.recordsMarks = false
            try context.save()
            let conflict = ItemOperations.capabilities(for: item)
            #expect(conflict.hasNonMarkHistoryConflict)
            #expect(conflict.historyChangeError == .marksNotEnabled)
            #expect(item.marks.count == 1)
        }

        @Test
        func `UUID resolution includes pending records and excludes unrelated records`() throws {
            let context = try makeContext()
            let unrelated = try ItemOperations.create(
                context: context,
                input: .init(name: "Same Name", category: .other)
            )
            let pending = Item(
                name: "Same Name",
                category: .other,
                note: "",
                createdAt: .now,
                uuid: .init(),
                photoData: nil,
                archivedAt: nil
            )
            let pendingID = pending.uuid
            context.insert(pending)
            #expect(try ItemOperations.item(context: context, uuid: pendingID) === pending)
            #expect(try ItemOperations.item(context: context, uuid: unrelated.uuid) === unrelated)
            #expect(try ItemOperations.item(context: context, uuid: .init()) == nil)
            context.rollback()
            #expect(try ItemOperations.item(context: context, uuid: pendingID) == nil)
        }

        @Test
        func `system readings capture values without retaining model identity`() async throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try ItemOperations.create(context: context, input: .init(name: "Bag", category: .bags))
            try ItemOperations.mark(item, on: today, today: today, context: context)
            let history = ItemOperations.historySnapshot(for: item, today: today)
            let capabilities = ItemOperations.capabilities(for: item)
            let now = try #require(today.date(in: .gmt))
            let review = ReviewOperations.identifiersSnapshot(for: [item], timeZone: .gmt, now: now)
            try ItemOperations.undoMark(item, on: today, context: context)
            let capturedCount = await Task.detached {
                history.totalMarks + (capabilities.canChangeHistory ? 1 : 0) + review.dormant.count
            }.value
            #expect(capturedCount == 2)
            #expect(history.markedDays == [today])
            #expect(item.marks.isEmpty)
            #expect(!context.hasChanges)
        }

        private func makeContext() throws -> ModelContext {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            context.autosaveEnabled = false
            return context
        }

        private func readingDay() throws -> LocalDay {
            try #require(LocalDay(year: 2_026, month: 9, day: 30))
        }
    }
}

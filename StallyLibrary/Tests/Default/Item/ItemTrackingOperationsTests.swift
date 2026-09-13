import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct ItemTrackingOperationsTests {
        @Test
        func `legacy updates preserve tracking and unchanged photo bytes`() throws {
            let context = try makeContext()
            let today = try readingDay()
            let start = try #require(ItemStart(rawValue: "2020-09"))
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Plant", category: .other, photoData: try TestPhotoFixtures.preparedData()),
                tracking: .init(recordsMarks: false, start: start),
                today: today
            )
            let photo = item.photoData
            let identifier = item.uuid
            try ItemOperations.update(
                item,
                input: .init(name: "Home Plant", category: .other, photoData: photo),
                context: context
            )
            #expect(item.uuid == identifier)
            #expect(!item.recordsMarks)
            #expect(item.startRawValue == start.rawValue)
            #expect(item.photoData == photo)
            #expect(!context.hasChanges)
            let first = ItemTimeOperations.snapshot(for: item, today: today)
            #expect(ItemTimeOperations.snapshot(for: item, today: today) == first)
            #expect(!context.hasChanges)
        }

        @Test
        func `mark and Undo reject non Mark records while generic lookup remains valid`() throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try createNonMark(context: context, today: today)
            #expect(throws: ItemValidationError.marksNotEnabled) {
                try ItemOperations.mark(item, on: today, today: today, context: context)
            }
            #expect(throws: ItemValidationError.marksNotEnabled) {
                try ItemOperations.undoMark(item, on: today, context: context)
            }
            #expect(item.marks.isEmpty)
            #expect(try ItemOperations.item(context: context, uuid: item.uuid)?.uuid == item.uuid)
            #expect(try ItemOperations.items(context: context, matchingName: "Plant").count == 1)
            #expect(ItemOperations.itemsEligibleForHistoryChanges(from: [item]).isEmpty)
        }

        @Test
        func `tracking edits preserve Mark chronology and reject destructive policy switches`() throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try ItemOperations.create(context: context, input: .init(name: "Bag", category: .bags))
            #expect(item.recordsMarks)
            #expect(item.startRawValue == nil)
            let markedDay = try #require(today.adding(days: -1))
            try ItemOperations.mark(item, on: markedDay, today: today, context: context)
            let identifier = try #require(item.marks.first?.uuid)
            for rawValue in ["2000", "2026-09-13"] {
                try ItemOperations.update(
                    item,
                    input: .init(name: "Bag", category: .bags),
                    tracking: .init(recordsMarks: true, start: try #require(ItemStart(rawValue: rawValue))),
                    today: today,
                    context: context
                )
                #expect(item.marks.first?.uuid == identifier)
                #expect(item.marks.first?.day == markedDay)
            }
            #expect(throws: ItemValidationError.existingMarksRequireRecording) {
                try ItemOperations.update(
                    item,
                    input: .init(name: "Changed", category: .other),
                    tracking: .init(recordsMarks: false, start: nil),
                    today: today,
                    context: context
                )
            }
            #expect(item.name == "Bag")
            #expect(item.startRawValue == "2026-09-13")
            #expect(item.marks.first?.uuid == identifier)
        }

        @Test
        func `invalid fields leave tracking unchanged and stored future starts remain editable`() throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try createNonMark(context: context, today: today)
            let future = try #require(ItemStart(rawValue: "2027"))
            #expect(throws: ItemValidationError.futureStartNotAllowed) {
                try ItemOperations.update(
                    item,
                    input: .init(name: "Changed", category: .bags),
                    tracking: .init(recordsMarks: true, start: future),
                    today: today,
                    context: context
                )
            }
            #expect(!item.recordsMarks)
            #expect(item.name == "Plant")
            #expect(item.startRawValue == nil)
            item.startRawValue = future.rawValue
            try context.save()
            try ItemOperations.update(
                item,
                input: .init(name: "Edited", category: .other),
                tracking: .init(recordsMarks: false, start: future),
                today: today,
                context: context
            )
            #expect(ItemTimeOperations.snapshot(for: item, today: today) == .notStarted(future))
        }

        @Test
        func `archive never pauses or resets elapsed time`() throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: "Home", category: .other),
                tracking: .init(recordsMarks: false, start: try #require(ItemStart(rawValue: "2026-09-01"))),
                today: today
            )
            let before = ItemTimeOperations.snapshot(for: item, today: today)
            try ItemOperations.archive(item, on: .now, context: context)
            #expect(ItemTimeOperations.snapshot(for: item, today: today) == before)
            let tomorrow = try #require(today.adding(days: 1))
            guard case .elapsed(_, let days, _) = ItemTimeOperations.snapshot(for: item, today: tomorrow) else {
                Issue.record("Expected elapsed time while archived")
                return
            }
            #expect(days == 13...13)
            try ItemOperations.moveBackToLibrary(item, context: context)
            #expect(ItemTimeOperations.snapshot(for: item, today: today) == before)
        }

        @Test
        func `inconsistent stored tracking stays visible and can be repaired without deleting history`() throws {
            let context = try makeContext()
            let today = try readingDay()
            let item = try ItemOperations.create(context: context, input: .init(name: "Bag", category: .bags))
            try ItemOperations.mark(item, on: today, today: today, context: context)
            let markID = item.marks.first?.uuid
            item.recordsMarks = false
            item.startRawValue = "invalid"
            try context.save()
            #expect(ItemOperations.hasNonMarkHistoryConflict(item))
            #expect(ItemTimeOperations.snapshot(for: item, today: today) == .invalidStart)
            #expect(throws: ItemValidationError.invalidStart) {
                try ItemOperations.update(item, input: .init(name: "Edited", category: .other), context: context)
            }
            try ItemOperations.update(
                item,
                input: .init(name: "Bag", category: .bags),
                tracking: .init(recordsMarks: true, start: nil),
                today: today,
                context: context
            )
            #expect(item.marks.first?.uuid == markID)
            #expect(!ItemOperations.hasNonMarkHistoryConflict(item))
        }

        private func readingDay() throws -> LocalDay {
            try #require(LocalDay(year: 2_026, month: 9, day: 13))
        }

        private func makeContext() throws -> ModelContext {
            let context = ModelContext(try StallyModelContainerFactory.inMemory())
            context.autosaveEnabled = false
            return context
        }

        private func createNonMark(context: ModelContext, today: LocalDay) throws -> Item {
            try ItemOperations.create(
                context: context,
                input: .init(name: "Plant", category: .other),
                tracking: .init(recordsMarks: false, start: nil),
                today: today
            )
        }
    }
}

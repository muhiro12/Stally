import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct TextInputTests {
    @Test(arguments: [nil, ""] as [String?])
    func optionalValuesRemainAbsentAfterOperationsAndDiskReopen(_ input: String?) async throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "optional-text.store")
        let prepared = try await PhotoOperations.prepare(data: PhotoTestImages.imageData())
        let identity = try autoreleasepool {
            let container = try StallyModelContainerFactory.disk(at: url)
            let context = ModelContext(container)
            let item = try ItemOperations.create(context: context, name: "Camera", note: input)
            #expect(item.note == nil)
            try ItemOperations.update(item, name: "Camera", note: "Original", context: context)
            try ItemOperations.update(item, name: "Camera", note: input, context: context)
            #expect(item.note == nil)

            var draft = ItemOperations.draft(for: item)
            #expect(draft.note.isEmpty && draft.representativeURL.isEmpty)
            draft.note = "Original"
            draft.representativeURL = "https://example.com"
            draft.photos = [.init(prepared: prepared, caption: "Original")]
            let saved = try ItemOperations.save(draft, context: context)
            var clearing = ItemOperations.draft(for: saved)
            clearing.note = input ?? ""
            clearing.representativeURL = input ?? ""
            clearing.photos[0].caption = input ?? ""
            let cleared = try ItemOperations.save(clearing, context: context)
            #expect(cleared.note == nil && cleared.representativeURL == nil)
            #expect(cleared.photos?.first?.caption == nil)

            try exerciseUnknownPeriodEdits(for: cleared, input: input, context: context)
            return item.uuid
        }
        let container = try StallyModelContainerFactory.disk(at: url)
        let context = ModelContext(container)
        let item = try ItemOperations.item(context: context, uuid: identity)
        #expect(item.note == nil && item.representativeURL == nil)
        let photos = try #require(item.photos)
        #expect(photos.count == 1 && photos[0].caption == nil && photos[0].imageData == prepared.imageData)
        let periods = try #require(item.periods)
        #expect(periods.count == 2)
        #expect(periods.allSatisfy { $0.startLocalDate == nil && $0.endLocalDate == nil && !$0.isOngoing })
        #expect(ItemOperations.draft(for: item).photos[0].caption.isEmpty)
    }

    @Test
    func unchangedEmptyDraftDoesNotEraseAnInterveningNote() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Camera")
        var draft = ItemOperations.draft(for: item)
        draft.name = "Renamed"
        try ItemOperations.update(item, name: "Camera", note: "Added elsewhere", context: context)
        let saved = try ItemOperations.save(draft, context: context)
        #expect(saved.name == "Renamed" && saved.note == "Added elsewhere")
    }

    @Test
    func partialEditsDistinguishOmissionClearingAndReplacement() throws {
        #expect(try TextInput.edited(nil, clearing: false, current: "Keep") == "Keep")
        #expect(try TextInput.edited("", clearing: false, current: "Remove") == nil)
        #expect(try TextInput.edited(nil, clearing: true, current: "Remove") == nil)
        #expect(try TextInput.edited("", clearing: true, current: "Remove") == nil)
        #expect(try TextInput.edited("New", clearing: false, current: "Old") == "New")
        #expect(throws: RecordError.conflictingTextEdit) {
            try TextInput.edited("New", clearing: true, current: "Keep")
        }
    }

    @Test(arguments: [" ", "\n", "  Keep this\n"])
    func nonemptyFreeTextIsPreservedExactly(_ text: String) async throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "Camera", note: text)
        let prepared = try await PhotoOperations.prepare(data: PhotoTestImages.imageData())
        draft.photos = [.init(prepared: prepared, caption: text)]
        let item = try ItemOperations.save(draft, context: context)
        #expect(item.note == text && item.photos?.first?.caption == text)
        #expect(try TextInput.edited(text, clearing: false, current: nil) == text)
        #expect(TextInput.optional(text) == text)
    }

    @Test(arguments: ["", " ", "\n"])
    func requiredNamesAndMarkDatesRejectEmptyInputWithoutMutation(_ text: String) throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Keep", note: "Keep note")
        let tag = try TagOperations.create(name: "Keep tag", context: context)
        let mark = try MarkOperations.add(to: item, localDateTime: "2026-11-10", context: context)
        #expect(throws: RecordError.nameRequired) {
            try ItemOperations.create(context: context, name: text)
        }
        #expect(throws: RecordError.nameRequired) {
            try ItemOperations.update(item, name: text, note: nil, context: context)
        }
        #expect(throws: RecordError.nameRequired) {
            try TagOperations.create(name: text, context: context)
        }
        #expect(throws: RecordError.nameRequired) {
            try TagOperations.rename(tag, name: text, context: context)
        }
        #expect(throws: RecordError.invalidDate) {
            try MarkOperations.add(to: item, localDateTime: text, context: context)
        }
        #expect(throws: RecordError.invalidDate) {
            try MarkOperations.correct(mark, localDateTime: text, context: context)
        }
        var draft = ItemOperations.draft(for: item)
        draft.name = text
        draft.note = ""
        #expect(throws: RecordError.nameRequired) {
            try ItemOperations.save(draft, context: context)
        }
        #expect(!context.hasChanges)
        #expect(item.name == "Keep" && item.note == "Keep note" && tag.name == "Keep tag")
        #expect(mark.localDateTime == "2026-11-10" && item.marks?.count == 1)
    }

    private func exerciseUnknownPeriodEdits(for item: Item, input: String?, context: ModelContext) throws {
        let period = try PeriodOperations.add(
            to: item, input: .init(start: input, end: input), today: "2026-11-10", context: context
        )
        try PeriodOperations.end(period, on: input, today: "2026-11-10", context: context)
        let resumed = try PeriodOperations.resume(period, on: input, today: "2026-11-10", context: context)
        try PeriodOperations.correct(
            resumed,
            input: .init(start: input, end: input, isOngoing: false),
            today: "2026-11-10",
            context: context
        )
    }
}

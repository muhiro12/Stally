import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

struct ItemInputTests {
    @Test(arguments: ["", " \n", String(repeating: "あ", count: 4_001)])
    func invalidInputDoesNotInvokeModel(_ source: String) async throws {
        var called = false
        do {
            _ = try await ItemInputOperations.infer(text: source) { _ in
                called = true
                return .init(name: "Unexpected")
            }
            Issue.record("Invalid input must fail")
        } catch let error as ItemInputError {
            #expect(error == (source.count > 4_000 ? .inputTooLong : .emptyInput))
        }
        #expect(!called)
    }

    @Test(arguments: [
        ItemInputSuggestion(name: "Invented"),
        ItemInputSuggestion(name: "Camera", note: "Bought in 2020"),
        ItemInputSuggestion(name: "Camera", representativeURL: "https://invented.example"),
        ItemInputSuggestion(name: "Camera", representativeURL: "javascript:alert(1)"),
        ItemInputSuggestion()
    ])
    func unsupportedFieldsAreRejected(_ suggestion: ItemInputSuggestion) async {
        await #expect(throws: ItemInputError.invalidResult) {
            try await ItemInputOperations.infer(text: "Camera\njavascript:alert(1)") { _ in
                suggestion
            }
        }
    }

    @Test(arguments: ["Camera", "旅のカメラ"])
    func exactSourceFieldsRetainLanguageAndLineBreaks(_ name: String) async throws {
        let note = "A gift\nKeep the case."
        let link = "https://example.com/camera"
        let source = "\(name)\n\(note)\n\(link)"
        let result = try await ItemInputOperations.infer(text: source) { _ in
            .init(name: " \(name) ", note: note, representativeURL: link)
        }
        #expect(result == .init(name: name, note: note, representativeURL: link))
        #expect(ItemInputOperations.text(for: result) == "\(name)\n\n\(note)\n\n\(link)")
    }

    @Test(arguments: ["", " ", "\t", "\r\n"])
    func reformattedNotesRestoreTheCompleteSourcePassage(_ separator: String) async throws {
        let lines = [
            "2025年2月14日にお店で購入。",
            "価格は2,400円。容量は350ml。",
            "色は青。持ち手が広くて使いやすい。",
            "以前のカップと比べて少し重い。",
            "普段は仕事机で使っている。"
        ]
        let note = lines.joined(separator: "\n")
        let source = "名前：Example 陶器マグ M-20\n\nメモ：\n\(note)\n\n代表URL：\nhttps://example.com/mug"
        let result = try await ItemInputOperations.infer(text: source) { _ in
            .init(
                name: "Example 陶器マグ M-20",
                note: lines.joined(separator: separator),
                representativeURL: "https://example.com/mug"
            )
        }
        #expect(result.note == note)
        #expect(result.name == "Example 陶器マグ M-20")
        #expect(result.representativeURL == "https://example.com/mug")
    }

    @Test(arguments: [
        "価格は3,400円。容量は350ml。",
        "価格は2,400円。使いやすい。",
        "容量は350ml。価格は2,400円。",
        "価格は2,400円、容量は350ml。"
    ])
    func noteRecoveryRejectsChangedOmittedOrReorderedContent(_ note: String) async {
        await #expect(throws: ItemInputError.invalidResult) {
            try await ItemInputOperations.infer(text: "Mug\n価格は2,400円。\n容量は350ml。\n使いやすい。") { _ in
                .init(name: "Mug", note: note)
            }
        }
    }

    @Test
    func ambiguousWhitespaceMatchesAreRejected() async {
        await #expect(throws: ItemInputError.invalidResult) {
            try await ItemInputOperations.infer(text: "Mug\nBlue\nceramic\nBlue  ceramic") { _ in
                .init(name: "Mug", note: "Blue ceramic")
            }
        }
    }

    @Test
    func whitespaceRecoveryDoesNotChangeNamesOrLinks() async {
        await #expect(throws: ItemInputError.invalidResult) {
            try await ItemInputOperations.infer(text: "Example Mug\nhttps://example.com/mug") { _ in
                .init(name: "ExampleMug", representativeURL: "https://example.com/mug")
            }
        }
        await #expect(throws: ItemInputError.invalidResult) {
            try await ItemInputOperations.infer(text: "Mug\nhttps://example.com/ mug") { _ in
                .init(name: "Mug", representativeURL: "https://example.com/mug")
            }
        }
    }

    @Test
    func unlabelledProseAndUnicodeNotesPreserveTheSource() async throws {
        let note = "青いマグ☕️。\r\n Cafe\u{301}で購入。\n大切に使いたい。"
        let result = try await ItemInputOperations.infer(text: "旅のカップ。\(note)") { _ in
            .init(name: "旅のカップ", note: "青いマグ☕️。Caféで購入。大切に使いたい。")
        }
        #expect(Array(result.note.utf8) == Array(note.utf8))
    }

    @Test
    func cancellationRejectsEvenAnOtherwiseSuccessfulLateResult() async {
        let task = Task {
            try await ItemInputOperations.infer(text: "Camera") { _ in
                withUnsafeCurrentTask { task in
                    task?.cancel()
                }
                return .init(name: "Camera")
            }
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test
    func modelFailuresRemainVisible() async {
        await #expect(throws: ItemInputError.generationFailed) {
            try await ItemInputOperations.infer(text: "Camera") { _ in
                throw CocoaError(.fileReadUnknown)
            }
        }
        await #expect(throws: ItemInputError.modelNotReady) {
            try await ItemInputOperations.infer(text: "Camera") { _ in
                throw ItemInputError.modelNotReady
            }
        }
    }

    @MainActor
    @Test
    func applyingPreservesDraftIdentityAndUserEditsWithoutSaving() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Original")
        var draft = ItemOperations.draft(for: item)
        draft.name = "User edit during generation"
        draft.note = " "
        draft.newTags = [.init(name: "Travel")]
        let suggestion = ItemInputSuggestion(
            name: "Suggested", note: "Generated", representativeURL: "https://example.com"
        )
        let filled = ItemInputOperations.fillingEmptyFields(of: draft, with: suggestion)
        #expect(filled.name == draft.name && filled.note == " ")
        #expect(filled.representativeURL == suggestion.representativeURL)
        #expect(filled.original?.id == item.uuid && filled.newTags[0].id == draft.newTags[0].id)
        #expect(!context.hasChanges && item.name == "Original" && item.representativeURL == nil)
        let saved = try ItemOperations.save(filled, context: context)
        #expect(saved.uuid == item.uuid && saved.name == draft.name)
        #expect(saved.marks?.isEmpty == true && saved.periods?.isEmpty == true)
    }

    @MainActor
    @Test
    func suggestedDraftPersistsOnlyAfterExplicitSaveAndSurvivesReopen() throws {
        let directory = PersistentTestDirectory.makeURL()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "input.store")
        let identity = try autoreleasepool {
            let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
            let suggestion = ItemInputSuggestion(name: "Camera", note: "A gift")
            let draft = ItemInputOperations.fillingEmptyFields(of: .init(), with: suggestion)
            #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)
            #expect(!context.hasChanges)
            return try ItemOperations.save(draft, context: context).uuid
        }
        let context = ModelContext(try StallyModelContainerFactory.disk(at: url))
        let saved = try ItemOperations.item(context: context, uuid: identity)
        #expect(saved.name == "Camera" && saved.note == "A gift")
        #expect(saved.marks?.isEmpty == true && saved.periods?.isEmpty == true)
    }
}

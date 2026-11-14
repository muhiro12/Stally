import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct ItemSharingTests {
    @Test(arguments: [nil, "", "Remember this\n\nSecond paragraph", "## 見出し\n> 引用 & <b>text</b>\n\\\u{0301}"])
    func sharesLiteralFactsWithoutAnImportGrammar(note: String?) throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        var draft = ItemDraft(name: "カメラ 📷", note: note)
        draft.representativeURL = "https://example.com/camera?a=1&b=2"
        let item = try ItemOperations.save(draft, context: context)
        let expectedNote = note.flatMap { $0.isEmpty ? nil : $0 }
        let expected = "カメラ 📷" + (expectedNote.map { "\n\n" + $0 } ?? "")
            + "\n\nhttps://example.com/camera?a=1&b=2"
        #expect(ItemOperations.shareText(for: item) == expected)
        #expect(!context.hasChanges)
    }

    @Test
    func nameOnlyDoesNotAddEmptySections() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "  A keepsake  ")
        #expect(ItemOperations.shareText(for: item) == "  A keepsake  ")
    }

    @Test
    func sharingOmitsIdentityPreferencesRelationshipsAndHistoryWithoutMutation() throws {
        let context = ModelContext(try StallyModelContainerFactory.inMemory())
        let item = try ItemOperations.create(context: context, name: "Camera", note: "A gift")
        let tag = try TagOperations.create(name: "Private tag", context: context)
        try TagOperations.assign([tag], to: item, context: context)
        let mark = ItemMark(item: item, localDateTime: "2026-11-10")
        let period = ItemPeriod(item: item, startLocalDate: "2020", endLocalDate: nil, isOngoing: true)
        let photo = ItemPhoto(item: item, imageData: nil, thumbnailData: nil, caption: "Private photo", sortOrder: 0)
        context.insert(mark)
        context.insert(period)
        context.insert(photo)
        try context.save()
        try ItemOperations.setArchived(item, to: true, context: context)
        try ItemOperations.setFavorite(item, to: true, context: context)
        try ItemOperations.setMarkRecordingEnabled(item, to: false, context: context)
        let before = try TransferOperations.export(context: context, includingImages: false).manifest
        let text = ItemOperations.shareText(for: item)
        #expect(text == "Camera\n\nA gift")
        var after = try TransferOperations.export(context: context, includingImages: false).manifest
        after.exportedAt = before.exportedAt
        #expect(try TransferCodec.encode(before) == TransferCodec.encode(after))
        #expect(!context.hasChanges)
        #expect(period.startLocalDate == "2020" && period.endLocalDate == nil)
        // A value already previewed for sharing does not change under an intervening edit.
        try ItemOperations.update(item, name: "Updated", note: nil, context: context)
        #expect(text == "Camera\n\nA gift")
        #expect(ItemOperations.shareText(for: item) == "Updated")
    }
}

import Foundation
import SwiftData

/// The caller owns this disposable write context and performs the sole save after graph validation.
enum TransferImportMutation {
    static func apply(_ archive: TransferArchive, selection: Set<UUID>, today: String, context: ModelContext) throws {
        let manifest = archive.manifest
        var tags = try RecordMutation.index(context.fetch(FetchDescriptor<Tag>()), identity: \.uuid)
        var items = try RecordMutation.index(context.fetch(FetchDescriptor<Item>()), identity: \.uuid)
        for row in manifest.tags where selection.contains(row.uuid) {
            let tag = tags[row.uuid] ?? Tag(name: row.name)
            tag.uuid = row.uuid
            tag.name = row.name
            if tag.modelContext == nil { context.insert(tag) }
            tags[row.uuid] = tag
        }
        for row in manifest.items where selection.contains(row.uuid) {
            guard row.tagUUIDs.allSatisfy({ tags[$0] != nil }) else { throw TransferError.invalidSelection }
            let item = items[row.uuid] ?? Item(name: row.name, note: row.note)
            item.uuid = row.uuid
            item.name = row.name
            item.note = row.note
            item.representativeURL = row.representativeURL
            item.createdAt = row.createdAt
            item.isArchived = row.isArchived
            item.isFavorite = row.isFavorite
            item.isMarkRecordingEnabled = row.isMarkRecordingEnabled
            item.tags = row.tagUUIDs.compactMap { tags[$0] }
            if item.modelContext == nil { context.insert(item) }
            items[row.uuid] = item
        }
        try applyMarks(manifest.itemMarks.filter { selection.contains($0.uuid) }, items: items, context: context)
        try applyPeriods(manifest.itemPeriods.filter { selection.contains($0.uuid) }, items: items, context: context)
        try applyPhotos(
            manifest.itemPhotos.filter { selection.contains($0.uuid) },
            media: archive.media,
            items: items,
            context: context
        )
        let touched = Set(manifest.itemPeriods.filter { selection.contains($0.uuid) }.map(\.itemUUID))
        for uuid in touched {
            guard let item = items[uuid] else { throw TransferError.invalidSelection }
            _ = try PeriodReadingOperations.readings(for: item, today: today)
        }
    }

    private static func applyMarks(_ rows: [TransferMark], items: [UUID: Item], context: ModelContext) throws {
        let existing = try RecordMutation.index(context.fetch(FetchDescriptor<ItemMark>()), identity: \.uuid)
        for row in rows {
            guard let item = items[row.itemUUID] else { throw TransferError.invalidSelection }
            let mark = existing[row.uuid] ?? ItemMark(item: item, localDateTime: row.localDateTime)
            mark.uuid = row.uuid
            mark.localDateTime = row.localDateTime
            mark.createdAt = row.createdAt
            if mark.modelContext == nil { context.insert(mark) }
        }
    }

    private static func applyPeriods(_ rows: [TransferPeriod], items: [UUID: Item], context: ModelContext) throws {
        let existing = try RecordMutation.index(context.fetch(FetchDescriptor<ItemPeriod>()), identity: \.uuid)
        for row in rows {
            guard let item = items[row.itemUUID] else { throw TransferError.invalidSelection }
            let period =
                existing[row.uuid]
                ?? ItemPeriod(
                    item: item,
                    startLocalDate: row.startLocalDate,
                    endLocalDate: row.endLocalDate,
                    isOngoing: row.isOngoing
                )
            period.uuid = row.uuid
            period.startLocalDate = row.startLocalDate
            period.endLocalDate = row.endLocalDate
            period.isOngoing = row.isOngoing
            period.createdAt = row.createdAt
            if period.modelContext == nil { context.insert(period) }
        }
    }

    private static func applyPhotos(
        _ rows: [TransferPhoto],
        media: [String: Data],
        items: [UUID: Item],
        context: ModelContext
    ) throws {
        let existing = try RecordMutation.index(context.fetch(FetchDescriptor<ItemPhoto>()), identity: \.uuid)
        for row in rows {
            guard let item = items[row.itemUUID] else { throw TransferError.invalidSelection }
            let photo =
                existing[row.uuid]
                ?? ItemPhoto(
                    item: item,
                    imageData: nil,
                    thumbnailData: nil,
                    caption: row.caption,
                    sortOrder: row.sortOrder
                )
            photo.uuid = row.uuid
            photo.caption = row.caption
            photo.sortOrder = row.sortOrder
            photo.createdAt = row.createdAt
            if let path = row.image.path {
                guard let data = media[String(path.dropFirst("media/".count))] else { throw TransferError.invalidFile }
                photo.imageData = data
                photo.thumbnailData = nil
            }
            if photo.modelContext == nil { context.insert(photo) }
        }
    }
}

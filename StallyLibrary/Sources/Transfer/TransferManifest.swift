import Foundation

struct TransferManifest: Codable, Equatable, Sendable {
    var format: String
    var formatVersion: Int
    var schemaVersion: String
    var exportedAt: Date
    var items: [TransferItem]
    var itemMarks: [TransferMark]
    var itemPeriods: [TransferPeriod]
    var itemPhotos: [TransferPhoto]
    var tags: [TransferTag]

    var recordCount: Int {
        items.count + itemMarks.count + itemPeriods.count + itemPhotos.count + tags.count
    }

    mutating func canonicalizeDates() throws {
        exportedAt = try TransferTimestamp.canonical(exportedAt)
        for index in items.indices { items[index].createdAt = try TransferTimestamp.canonical(items[index].createdAt) }
        for index in itemMarks.indices {
            itemMarks[index].createdAt = try TransferTimestamp.canonical(itemMarks[index].createdAt)
        }
        for index in itemPeriods.indices {
            itemPeriods[index].createdAt = try TransferTimestamp.canonical(itemPeriods[index].createdAt)
        }
        for index in itemPhotos.indices {
            itemPhotos[index].createdAt = try TransferTimestamp.canonical(itemPhotos[index].createdAt)
        }
    }

    mutating func normalizeText() {
        for index in items.indices {
            items[index].note = TextInput.optional(items[index].note)
            items[index].representativeURL = TextInput.optional(items[index].representativeURL)
        }
        for index in itemPhotos.indices {
            itemPhotos[index].caption = TextInput.optional(itemPhotos[index].caption)
        }
        for index in itemPeriods.indices {
            itemPeriods[index].startLocalDate = TextInput.optional(itemPeriods[index].startLocalDate)
            itemPeriods[index].endLocalDate = TextInput.optional(itemPeriods[index].endLocalDate)
        }
    }
}

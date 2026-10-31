import Foundation
import SwiftData

/// Shared export and reviewed import boundary, independent of presentation and file pickers.
@preconcurrency
@MainActor
public enum TransferOperations {
    /// Includes archived Items and unused Tags; incomplete ownership blocks the entire snapshot.
    public static func export(context: ModelContext, includingImages: Bool) throws -> TransferArchive {
        try RecordMutation.validate(context, models: [])
        return try snapshot(context: context, includingImages: includingImages)
    }

    static func snapshot(context: ModelContext, includingImages: Bool) throws -> TransferArchive {
        let items = try context.fetch(FetchDescriptor<Item>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let tags = try context.fetch(FetchDescriptor<Tag>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let marks = try context.fetch(FetchDescriptor<ItemMark>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let periods = try context.fetch(FetchDescriptor<ItemPeriod>()).sorted { first, second in
            first.uuid.uuidString < second.uuid.uuidString
        }
        let photos = try context.fetch(FetchDescriptor<ItemPhoto>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let (photoRows, media) = try photoRows(photos, includingImages: includingImages)
        let manifest = try TransferManifest(
            format: "stally",
            formatVersion: StallyDataContract.formatVersion,
            schemaVersion: StallyDataContract.schemaVersion,
            exportedAt: .now,
            items: items.map { item in
                .init(
                    uuid: item.uuid,
                    name: item.name,
                    note: item.note,
                    representativeURL: item.representativeURL,
                    createdAt: item.createdAt,
                    isArchived: item.isArchived,
                    isFavorite: item.isFavorite,
                    isMarkRecordingEnabled: item.isMarkRecordingEnabled,
                    tagUUIDs: (item.tags ?? []).map(\.uuid).sorted { $0.uuidString < $1.uuidString }
                )
            },
            itemMarks: marks.map(markRow),
            itemPeriods: periods.map(periodRow),
            itemPhotos: photoRows,
            tags: tags.map { .init(uuid: $0.uuid, name: $0.name) }
        )
        try TransferValidation.validate(manifest)
        // Canonical timestamps make a replay equal without mutating local submillisecond Dates.
        return try .init(manifest: TransferCodec.decode(TransferCodec.encode(manifest)), media: media)
    }

    private static func markRow(_ mark: ItemMark) throws -> TransferMark {
        guard let item = mark.item else { throw TransferError.incompleteGraph }
        return .init(uuid: mark.uuid, itemUUID: item.uuid, localDateTime: mark.localDateTime, createdAt: mark.createdAt)
    }

    private static func periodRow(_ period: ItemPeriod) throws -> TransferPeriod {
        guard let item = period.item else { throw TransferError.incompleteGraph }
        return .init(
            uuid: period.uuid,
            itemUUID: item.uuid,
            startLocalDate: period.startLocalDate,
            endLocalDate: period.endLocalDate,
            isOngoing: period.isOngoing,
            createdAt: period.createdAt
        )
    }

    private static func photoRows(_ photos: [ItemPhoto], includingImages: Bool) throws -> (
        [TransferPhoto], [String: Data]
    ) {
        var media: [String: Data] = [:]
        var byteCount = 0
        let rows: [TransferPhoto] = try photos.map { photo in
            guard let item = photo.item else { throw TransferError.incompleteGraph }
            let image = try image(photo, includingImages: includingImages)
            if let path = image.path, let data = photo.imageData {
                guard data.count <= TransferCodec.maximumMediaBytes - byteCount else {
                    throw TransferError.limitExceeded
                }
                byteCount += data.count
                media[String(path.dropFirst("media/".count))] = data
            }
            return .init(
                uuid: photo.uuid,
                itemUUID: item.uuid,
                caption: photo.caption,
                sortOrder: photo.sortOrder,
                createdAt: photo.createdAt,
                image: image
            )
        }
        return (rows, media)
    }

    private static func image(_ photo: ItemPhoto, includingImages: Bool) throws -> TransferImage {
        guard let data = photo.imageData else {
            return .init(state: .unavailable, path: nil, byteCount: nil, sha256: nil)
        }
        guard includingImages else {
            return .init(state: .omitted, path: nil, byteCount: nil, sha256: nil)
        }
        let fileExtension = try TransferMedia.fileExtension(data)
        return .init(
            state: .included,
            path: "media/\(photo.uuid.uuidString.lowercased()).\(fileExtension)",
            byteCount: data.count,
            sha256: TransferMedia.digest(data)
        )
    }
}

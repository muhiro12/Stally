import Foundation
import SwiftData

/// Shared export and reviewed import boundary, independent of presentation and file pickers.
@preconcurrency
@MainActor
public enum TransferOperations {
    /// Includes archived Items and unused Tags; incomplete ownership blocks the entire snapshot.
    public static func export(context: ModelContext, includingImages: Bool) throws -> TransferArchive {
        try RecordMutation.validate(context, models: [])
        return try snapshot(context: ModelContext(context.container), includingImages: includingImages)
    }

    /// Stages a saved snapshot off the main actor for UI and Intent callers.
    public static func prepareExport(context: ModelContext, includingImages: Bool) async throws -> TransferArchive {
        try RecordMutation.validate(context, models: [])
        let archive = try await TransferPreparation.export(
            container: context.container,
            includingImages: includingImages
        )
        try Task.checkCancellation()
        try RecordMutation.validate(context, models: [])
        return archive
    }

    /// Encodes all records without image bytes or external file references.
    public static func exportRecords(context: ModelContext) throws -> Data {
        try TransferCodec.encode(export(context: context, includingImages: false).manifest)
    }

    nonisolated static func snapshot(context: ModelContext, includingImages: Bool) throws -> TransferArchive {
        try snapshot(context: context, includingImages: includingImages, stagingImages: true)
    }

    nonisolated static func snapshot(context: ModelContext, includingImages: Bool, stagingImages: Bool) throws
    -> TransferArchive {
        let budget = TransferBudget.current
        let count =
            try context.fetchCount(FetchDescriptor<Item>()) + context.fetchCount(FetchDescriptor<Tag>())
            + context.fetchCount(FetchDescriptor<ItemMark>()) + context.fetchCount(FetchDescriptor<ItemPeriod>())
            + context.fetchCount(FetchDescriptor<ItemPhoto>())
        try budget.check(recordCount: count)
        let items = try context.fetch(FetchDescriptor<Item>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let tags = try context.fetch(FetchDescriptor<Tag>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let marks = try context.fetch(FetchDescriptor<ItemMark>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let periods = try context.fetch(FetchDescriptor<ItemPeriod>()).sorted { first, second in
            first.uuid.uuidString < second.uuid.uuidString
        }
        let photos = try context.fetch(FetchDescriptor<ItemPhoto>()).sorted { $0.uuid.uuidString < $1.uuid.uuidString }
        let staging = try TransferStaging()
        let photoRows = try photoRows(
            photos,
            includingImages: includingImages,
            staging: staging,
            container: context.container,
            stagingImages: stagingImages
        )
        var manifest = try TransferManifest(
            format: StallyDataContract.fileTypeIdentifier,
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
        manifest.normalizeText()
        try TransferValidation.validate(manifest)
        // Quantize values directly; avoid an encode/decode copy of the complete library.
        try manifest.canonicalizeDates()
        _ = try manifest.estimatedJSONBytes(budget: budget)
        return .init(manifest: manifest, staging: staging)
    }

    nonisolated private static func markRow(_ mark: ItemMark) throws -> TransferMark {
        guard let item = mark.item else { throw TransferError.incompleteGraph }
        return .init(uuid: mark.uuid, itemUUID: item.uuid, localDateTime: mark.localDateTime, createdAt: mark.createdAt)
    }

    nonisolated private static func periodRow(_ period: ItemPeriod) throws -> TransferPeriod {
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

    nonisolated private static func photoRows(
        _ photos: [ItemPhoto],
        includingImages: Bool,
        staging: TransferStaging,
        container: ModelContainer,
        stagingImages: Bool
    ) throws -> [TransferPhoto] {
        try photos.map { photo in
            try Task.checkCancellation()
            guard let item = photo.item else { throw TransferError.incompleteGraph }
            let uuid = photo.uuid
            let image: TransferImage = try autoreleasepool {
                // A disposable context prevents every fetched blob remaining registered together.
                let reader = ModelContext(container)
                let descriptor = FetchDescriptor<ItemPhoto>(predicate: #Predicate { $0.uuid == uuid })
                guard let current = try reader.fetch(descriptor).first else { throw TransferError.staleReview }
                guard let data = current.imageData else {
                    return .init(state: .unavailable, path: nil, byteCount: nil, sha256: nil)
                }
                guard includingImages else {
                    return .init(state: .omitted, path: nil, byteCount: nil, sha256: nil)
                }
                let fileExtension = try TransferMedia.fileExtension(data)
                let path = StallyDataContract.assetPathPrefix + "\(uuid.uuidString.lowercased()).\(fileExtension)"
                if stagingImages { try staging.write(data, path: path) }
                return .init(state: .included, path: path, byteCount: data.count, sha256: TransferMedia.digest(data))
            }
            return .init(
                uuid: uuid,
                itemUUID: item.uuid,
                caption: photo.caption,
                sortOrder: photo.sortOrder,
                createdAt: photo.createdAt,
                image: image
            )
        }
    }
}

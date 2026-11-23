import Foundation

/// Validates portable facts without repairing an incoming graph or guessing dates.
enum TransferValidation {
    static func validate(_ manifest: TransferManifest) throws {
        try validateIdentities(manifest)
        let items = Set(manifest.items.lazy.map(\.uuid))
        let tags = Set(manifest.tags.lazy.map(\.uuid))
        for item in manifest.items {
            try RecordMutation.validateName(item.name)
            guard Set(item.tagUUIDs).count == item.tagUUIDs.count,
                  Set(item.tagUUIDs).isSubset(of: tags)
            else { throw TransferError.incompleteGraph }
            if let link = item.representativeURL { try validateURL(link) }
        }
        for tag in manifest.tags { try RecordMutation.validateName(tag.name) }
        for mark in manifest.itemMarks {
            guard items.contains(mark.itemUUID) else { throw TransferError.incompleteGraph }
            try CivilDate.validateMark(mark.localDateTime)
        }
        for period in manifest.itemPeriods {
            guard items.contains(period.itemUUID) else { throw TransferError.incompleteGraph }
            _ = try CivilDate.range(period.startLocalDate)
            _ = try CivilDate.range(period.endLocalDate)
        }
        try validatePhotos(manifest.itemPhotos, itemIDs: items)
    }

    private static func validateIdentities(_ manifest: TransferManifest) throws {
        var identities: Set<UUID> = []
        func insert(_ uuid: UUID) throws {
            guard identities.insert(uuid).inserted else { throw TransferError.incompleteGraph }
        }
        for item in manifest.items { try insert(item.uuid) }
        for mark in manifest.itemMarks { try insert(mark.uuid) }
        for period in manifest.itemPeriods { try insert(period.uuid) }
        for photo in manifest.itemPhotos { try insert(photo.uuid) }
        for tag in manifest.tags { try insert(tag.uuid) }
    }

    private static func validatePhotos(_ photos: [TransferPhoto], itemIDs: Set<UUID>) throws {
        for photo in photos {
            guard itemIDs.contains(photo.itemUUID), photo.sortOrder >= 0 else { throw TransferError.incompleteGraph }
            try validateImage(photo.image, uuid: photo.uuid)
        }
    }

    static func validateURL(_ text: String) throws {
        guard let validated = try ItemDraftMutation.representativeURL(text), validated == text else {
            throw RecordError.invalidURL
        }
    }

    private static func validateImage(_ image: TransferImage, uuid: UUID) throws {
        let digestLength = 64
        if image.state == .included {
            let extensions = ["jpg", "heic", "heif", "png"]
            let stem = StallyDataContract.assetPathPrefix + uuid.uuidString.lowercased() + "."
            guard let path = image.path,
                  extensions.contains(where: { path == stem + $0 }),
                  let count = image.byteCount, count > 0, count <= TransferCodec.maximumImageBytes,
                  let digest = image.sha256, digest.count == digestLength,
                  digest.utf8.allSatisfy({ "0123456789abcdef".utf8.contains($0) })
            else {
                throw TransferError.invalidFile
            }
        } else if image.path != nil || image.byteCount != nil || image.sha256 != nil {
            throw TransferError.invalidFile
        }
    }
}

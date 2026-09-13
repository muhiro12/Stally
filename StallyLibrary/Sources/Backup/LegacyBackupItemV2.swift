import Foundation

/// Frozen v2 payload adapter. Defaults belong here, never in the strict v3 decoder.
struct LegacyBackupItemV2: Codable {
    let id: UUID
    let name: String
    let categoryRawValue: String
    let note: String
    let photoData: Data?
    let createdAt: Date
    let archivedAt: Date?
    let marks: [BackupMark]

    var currentItem: BackupItem {
        .init(
            id: id,
            name: name,
            categoryRawValue: categoryRawValue,
            note: note,
            photoData: photoData,
            createdAt: createdAt,
            archivedAt: archivedAt,
            marks: marks
        )
    }

    init(_ item: BackupItem) throws {
        guard item.isLegacyCompatible else {
            throw EncodingError.invalidValue(
                item,
                .init(codingPath: [], debugDescription: "Version 2 cannot preserve tracking fields.")
            )
        }
        id = item.id
        name = item.name
        categoryRawValue = item.categoryRawValue
        note = item.note
        photoData = item.photoData
        createdAt = item.createdAt
        archivedAt = item.archivedAt
        marks = item.marks
    }
}

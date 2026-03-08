import Foundation

public struct StallyBackupSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let exportedAt: Date
    public let items: [StallyBackupItem]

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        exportedAt: Date,
        items: [StallyBackupItem]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.items = items.sorted(by: StallyBackupItem.sortForBackup)
    }
}

public struct StallyBackupItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let categoryRawValue: String
    public let photoData: Data?
    public let note: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let archivedAt: Date?
    public let marks: [StallyBackupMark]

    public init(
        id: UUID,
        name: String,
        categoryRawValue: String,
        photoData: Data?,
        note: String?,
        createdAt: Date,
        updatedAt: Date,
        archivedAt: Date?,
        marks: [StallyBackupMark]
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = categoryRawValue
        self.photoData = photoData
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
        self.marks = marks.sorted(by: StallyBackupMark.sortForBackup)
    }
}

public struct StallyBackupMark: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let day: Date
    public let createdAt: Date

    public init(
        id: UUID,
        day: Date,
        createdAt: Date
    ) {
        self.id = id
        self.day = day
        self.createdAt = createdAt
    }
}

public enum StallyBackupCodec {
    public static func snapshot(
        from items: [Item],
        exportedAt: Date = .now
    ) -> StallyBackupSnapshot {
        StallyBackupSnapshot(
            exportedAt: exportedAt,
            items: items.map { item in
                StallyBackupItem(
                    id: item.id,
                    name: item.name,
                    categoryRawValue: item.category.rawValue,
                    photoData: item.photoData,
                    note: item.note,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                    archivedAt: item.archivedAt,
                    marks: item.marks.map { mark in
                        StallyBackupMark(
                            id: mark.id,
                            day: mark.day,
                            createdAt: mark.createdAt
                        )
                    }
                )
            }
        )
    }

    public static func exportData(
        from items: [Item],
        exportedAt: Date = .now
    ) throws -> Data {
        try encode(
            snapshot(
                from: items,
                exportedAt: exportedAt
            )
        )
    }

    public static func encode(
        _ snapshot: StallyBackupSnapshot
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(
                makeDateFormatter().string(from: date)
            )
        }
        return try encoder.encode(snapshot)
    }

    public static func decode(
        _ data: Data
    ) throws -> StallyBackupSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)

            guard let date = makeDateFormatter().date(from: stringValue) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported backup date: \(stringValue)"
                )
            }

            return date
        }
        return try decoder.decode(
            StallyBackupSnapshot.self,
            from: data
        )
    }
}

private extension StallyBackupItem {
    static func sortForBackup(
        _ lhs: StallyBackupItem,
        _ rhs: StallyBackupItem
    ) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt < rhs.updatedAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }
}

private extension StallyBackupMark {
    static func sortForBackup(
        _ lhs: StallyBackupMark,
        _ rhs: StallyBackupMark
    ) -> Bool {
        if lhs.day != rhs.day {
            return lhs.day < rhs.day
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }
}

private extension StallyBackupCodec {
    static func makeDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }
}

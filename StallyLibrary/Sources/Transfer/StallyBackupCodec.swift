import Foundation

/// JSON encoding and decoding helpers for backup snapshots.
public enum StallyBackupCodec {
    /// Builds a backup snapshot from live items.
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

    /// Encodes all items as formatted backup data.
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

    /// Encodes a snapshot into backup JSON.
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

    /// Decodes backup JSON into a snapshot.
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

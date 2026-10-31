import Foundation

/// Strict version and required-key validation precedes decoding; unknown additive keys are ignored.
enum TransferCodec {
    static let maximumJSONBytes = 33_554_432
    static let maximumMediaBytes = 134_217_728
    static let maximumRecordCount = 50_000
    static let maximumImageBytes = 8_388_608

    static func decode(_ data: Data) throws -> TransferManifest {
        guard data.count <= maximumJSONBytes else { throw TransferError.limitExceeded }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["format"] as? String == "stally"
        else { throw TransferError.invalidFile }
        guard object["formatVersion"] as? Int == 1, object["schemaVersion"] as? String == "1.0.0" else {
            throw TransferError.unsupportedVersion
        }
        try require(["exportedAt", "items", "itemMarks", "itemPeriods", "itemPhotos", "tags"], in: object)
        let keys = [
            "items": [
                "uuid", "name", "note", "representativeURL", "createdAt", "isArchived", "isFavorite",
                "isMarkRecordingEnabled", "tagUUIDs"
            ],
            "itemMarks": ["uuid", "itemUUID", "localDateTime", "createdAt"],
            "itemPeriods": ["uuid", "itemUUID", "startLocalDate", "endLocalDate", "isOngoing", "createdAt"],
            "itemPhotos": ["uuid", "itemUUID", "caption", "sortOrder", "createdAt", "image"],
            "tags": ["uuid", "name"]
        ]
        var recordCount = 0
        for (key, required) in keys {
            guard let rows = object[key] as? [[String: Any]] else { throw TransferError.invalidFile }
            recordCount += rows.count
            guard recordCount <= maximumRecordCount else { throw TransferError.limitExceeded }
            for row in rows { try require(required, in: row) }
        }
        try validateImageKeys(object)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            try TransferTimestamp.date(decoder.singleValueContainer().decode(String.self))
        }
        var manifest = try decoder.decode(TransferManifest.self, from: data)
        try TransferValidation.validate(manifest)
        for index in manifest.items.indices {
            manifest.items[index].tagUUIDs.sort { $0.uuidString < $1.uuidString }
        }
        return manifest
    }

    static func encode(_ manifest: TransferManifest) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(TransferTimestamp.string(date))
        }
        guard var object = try JSONSerialization.jsonObject(with: encoder.encode(manifest)) as? [String: Any] else {
            throw TransferError.invalidFile
        }
        for (key, nullable) in ["items": ["representativeURL"], "itemPeriods": ["startLocalDate", "endLocalDate"]] {
            guard var rows = object[key] as? [[String: Any]] else { throw TransferError.invalidFile }
            for index in rows.indices {
                for field in nullable where rows[index][field] == nil { rows[index][field] = NSNull() }
            }
            object[key] = rows
        }
        let data = try JSONSerialization.data(withJSONObject: lowercaseUUIDs(object), options: [.sortedKeys])
        guard data.count <= maximumJSONBytes else { throw TransferError.limitExceeded }
        return data
    }

    private static func validateImageKeys(_ object: [String: Any]) throws {
        guard let photoRows = object["itemPhotos"] as? [[String: Any]] else { throw TransferError.invalidFile }
        for row in photoRows {
            guard let image = row["image"] as? [String: Any], let state = image["state"] as? String else {
                throw TransferError.invalidFile
            }
            if state != "included", ["path", "byteCount", "sha256"].contains(where: { image.keys.contains($0) }) {
                throw TransferError.invalidFile
            }
        }
    }

    private static func require(_ keys: [String], in object: [String: Any]) throws {
        guard keys.allSatisfy({ object.keys.contains($0) }) else { throw TransferError.invalidFile }
    }

    private static func lowercaseUUIDs(_ object: [String: Any]) -> [String: Any] {
        object.mapValues { value in
            guard let rows = value as? [[String: Any]] else {
                return value
            }
            return rows.map { row in
                var normalized = row
                for key in ["uuid", "itemUUID"] {
                    if let text = row[key] as? String { normalized[key] = text.lowercased() }
                }
                if let tags = row["tagUUIDs"] as? [String] { normalized["tagUUIDs"] = tags.map { $0.lowercased() } }
                return normalized
            }
        }
    }
}

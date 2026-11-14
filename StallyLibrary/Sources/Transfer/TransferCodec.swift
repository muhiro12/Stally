import Foundation

/// Typed decoding avoids a second full JSON object graph while retaining required-key semantics.
enum TransferCodec {
    private struct Header: Decodable {
        let format: String
        let formatVersion: Int
        let schemaVersion: String
    }

    static let maximumImageBytes = 8_388_608

    static func decode(_ data: Data) throws -> TransferManifest {
        try decode(data, budget: .current)
    }

    static func encode(_ manifest: TransferManifest) throws -> Data {
        try encode(manifest, budget: .current)
    }

    static func decode(_ data: Data, budget: TransferBudget) throws -> TransferManifest {
        try budget.check(jsonBytes: data.count)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            try TransferTimestamp.date(decoder.singleValueContainer().decode(String.self))
        }
        do {
            let header = try decoder.decode(Header.self, from: data)
            guard header.format == StallyDataContract.fileTypeIdentifier else { throw TransferError.invalidFile }
            guard header.formatVersion == 1, header.schemaVersion == "1.0.0" else {
                throw TransferError.unsupportedVersion
            }
            var manifest = try decoder.decode(TransferManifest.self, from: data)
            try budget.check(recordCount: manifest.recordCount)
            manifest.normalizeText()
            try TransferValidation.validate(manifest)
            for index in manifest.items.indices {
                manifest.items[index].tagUUIDs.sort { $0.uuidString < $1.uuidString }
            }
            return manifest
        } catch is DecodingError {
            throw TransferError.invalidFile
        }
    }

    static func encode(_ manifest: TransferManifest, budget: TransferBudget) throws -> Data {
        _ = try manifest.estimatedJSONBytes(budget: budget)
        var manifest = manifest
        manifest.normalizeText()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(TransferTimestamp.string(date))
        }
        let data = try encoder.encode(manifest)
        try budget.check(jsonBytes: data.count)
        return data
    }
}

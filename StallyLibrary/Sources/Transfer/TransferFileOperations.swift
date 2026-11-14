import Foundation

/// File access ends before review. Only referenced regular files are read, within explicit budgets.
public enum TransferFileOperations {
    /// Reads auxiliary records-only JSON; references to absent package media are rejected.
    @concurrent
    public static func readRecords(_ data: Data) async throws -> TransferArchive {
        let manifest = try TransferCodec.decode(data)
        guard !manifest.itemPhotos.contains(where: { $0.image.state == .included }) else {
            throw TransferError.invalidFile
        }
        return .init(manifest: manifest, media: [:])
    }

    /// The Intent adapter transfers ownership to IntentFile.removedOnCompletion.
    @concurrent
    public static func writeTemporary(_ archive: TransferArchive) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".stally")
        do {
            try Task.checkCancellation()
            try await write(archive, to: url)
            try Task.checkCancellation()
            return url
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    /// Coordinates provider access and retains only private immutable staged files.
    @concurrent
    public static func read(_ url: URL) async throws -> TransferArchive {
        try TransferStagedReader.read(url)
    }
    /// Writes to a replacement candidate before publishing, preserving an existing destination on failure.
    @concurrent
    public static func write(_ archive: TransferArchive, to url: URL) async throws {
        try TransferValidation.validate(archive.manifest)
        let manager = FileManager.default
        let replacement = try manager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: url,
            create: true
        )
        defer { try? manager.removeItem(at: replacement) }
        let candidate = replacement.appending(path: "Export.stally")
        try manager.createDirectory(at: candidate.appending(path: "assets"), withIntermediateDirectories: true)
        for photo in archive.manifest.itemPhotos {
            try Task.checkCancellation()
            if let path = photo.image.path {
                try autoreleasepool {
                    try archive.imageData(path: path).write(to: candidate.appending(path: path))
                }
            }
        }
        try TransferCodec.encode(archive.manifest).write(to: candidate.appending(path: "manifest.json"))
        try Task.checkCancellation()
        if manager.fileExists(atPath: url.path) {
            _ = try manager.replaceItemAt(url, withItemAt: candidate)
        } else {
            try manager.moveItem(at: candidate, to: url)
        }
    }
    /// Writes auxiliary JSON on the transfer executor rather than retaining its encoded bytes in UI state.
    @concurrent
    public static func writeRecords(_ archive: TransferArchive, to url: URL) async throws {
        try Task.checkCancellation()
        let data = try TransferCodec.encode(archive.manifest)
        try Task.checkCancellation()
        try data.write(to: url, options: .atomic)
    }

    /// The caller transfers this file to IntentFile.removedOnCompletion.
    @concurrent
    public static func writeTemporaryRecords(_ archive: TransferArchive) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
        do {
            try await writeRecords(archive, to: url)
            return url
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }
}

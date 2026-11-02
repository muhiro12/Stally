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
            try archive.fileWrapper().write(to: url, options: .atomic, originalContentsURL: nil)
            try Task.checkCancellation()
            return url
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    /// Coordinates and bounds access to a package or records-only JSON file.
    @concurrent
    public static func read(_ url: URL) async throws -> TransferArchive {
        let accessible = url.startAccessingSecurityScopedResource()
        defer { if accessible { url.stopAccessingSecurityScopedResource() } }
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values.isSymbolicLink != true else { throw TransferError.invalidFile }
        if values.isDirectory == true {
            return try await TransferPackage.read(url)
        }
        var coordinationError: NSError?
        var result: Result<Data, any Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinated in
            result = Result { try readFile(coordinated, limit: TransferCodec.maximumJSONBytes) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw TransferError.invalidFile }
        try Task.checkCancellation()
        return try await readRecords(result.get())
    }

    private static func readFile(_ url: URL, limit: Int) throws -> Data {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
        guard values.isRegularFile == true, values.isSymbolicLink != true else { throw TransferError.invalidFile }
        guard let count = values.fileSize, count <= limit else { throw TransferError.limitExceeded }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: limit + 1) ?? Data()
        guard data.count <= limit else { throw TransferError.limitExceeded }
        return data
    }
}

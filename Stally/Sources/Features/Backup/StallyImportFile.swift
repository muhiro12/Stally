import Foundation

/// Copies an opened file into a bounded immutable request while its access is valid.
struct StallyImportFile: Identifiable {
    let id = UUID()
    let data: Data

    static func read(at url: URL) throws -> Self {
        guard url.isFileURL, url.pathExtension.lowercased() == BackupOperations.fileExtension else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        var result: Result<Data, any Error>?
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, error: &coordinationError) { coordinatedURL in
            result = Result {
                let values = try coordinatedURL.resourceValues(forKeys: [.isRegularFileKey])
                guard values.isRegularFile == true else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let handle = try FileHandle(forReadingFrom: coordinatedURL)
                defer {
                    try? handle.close()
                }
                // An extra byte distinguishes an oversized file, including one that grows during reading.
                return try handle.read(upToCount: BackupOperations.maximumImportDataByteCount + 1) ?? .init()
            }
        }
        if let coordinationError {
            throw coordinationError
        }
        guard let result else {
            throw CocoaError(.fileReadUnknown)
        }
        return try .init(data: result.get())
    }
}
